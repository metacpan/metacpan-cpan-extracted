package Project::Easy::Helper;

use Class::Easy;

use Getopt::Long;

my $update_defaults = {
	schema_variable => 'db_schema_version',
	can_be_created  => 'table|index|tablespace|trigger|routine|procedure|function',
	
	sql => {
		ver_get => "select var_value from var where var_name = ?",
		ver_upd => "update var set var_value = ? where var_name = ?",
		ver_ins => "insert into var (var_value, var_name) values (?, ?)",
	}
};

sub updatedb {
	# script
	my ($pack, $libs) = &_script_wrapper();
	
	my $mode = 'update';
	my $clean = 0;
	my $schema_file;
	my $datasource = 'default';
	
	GetOptions (
		'h|help'        => sub { &help },
		'install'       => sub {$mode = 'install'},
		'clean'         => \$clean,
		'schema_file=s' => \$schema_file,
		'datasource=s'  => \$datasource
	);
	
	update_schema (
		mode  => $mode,
		clean => $clean,
		schema_file => $schema_file,
		datasource => $datasource
	);
	
}

# TODO: move to DBI::Easy
sub update_schema {
	my $settings = {@_};
	
	my $mode  = $settings->{mode}       || 'update';
	my $clean = $settings->{clean}      || 0;
	my $db    = $settings->{datasource} || 'default';
	
	my $dbh         = $settings->{dbh};
	my $schema_file = $settings->{schema_file};

	my $update_sql = $update_defaults->{sql};

	my $ver_get = $update_sql->{'ver_get'};
	my $ver_upd = $update_sql->{'ver_upd'};
	my $ver_ins = $update_sql->{'ver_ins'};

	my $ver_fld = $update_defaults->{'schema_variable'};

	my $can_created = $update_defaults->{'can_be_created'};
	
	if ($schema_file and !$dbh) {
		# try to create DBI connection from environment
		try_to_use ('DBI');
		my $dbh = DBI->connect;
	}
	
	if (!$dbh and !$schema_file) { # using with Project::Easy
		
		my ($pack, $libs) = &Project::Easy::Helper::_script_wrapper ();

		$dbh = $pack->db ($db);

		die "can't initialize dbh via Project::Easy"
			unless $dbh;

		my $pack_conf = $pack->config->{db}->{$db};
		my $pack_sql  = $pack_conf->{update_sql};

		warn "no update file for datasource '$db'", return
			unless defined $pack_conf->{update};

		$schema_file = $pack->root->file_io ($pack_conf->{update});
		
		$ver_get = $pack_sql->{'ver_get'} if $pack_sql->{'ver_get'};
		$ver_upd = $pack_sql->{'ver_upd'} if $pack_sql->{'ver_upd'};
		$ver_ins = $pack_sql->{'ver_ins'} if $pack_sql->{'ver_ins'};

		$ver_fld = $pack_conf->{'schema_variable'}
			if $pack_conf->{'schema_variable'};

		$can_created = $pack_conf->{'can_be_created'}
			if $pack_conf->{'can_be_created'};
	}
	
	my $schema_version;

	if ($mode eq 'update') {
		eval {
			debug "fetching $ver_get, ['$ver_fld']";
			($schema_version) = $dbh->selectrow_array ($ver_get, {}, $ver_fld);
		};

		unless ($schema_version) {
			die "can't fetch db_schema version, statement: $ver_get ['$ver_fld'].
if you want to init database, please use 'bin/updatedb --install'\n";
		}

	} elsif ($mode eq 'install') {
		$schema_version = 'NEW';
	}

	critical "can't open schema file '$schema_file'"
		unless open SCHEMA, $schema_file;
	
	my $found   = 0;
	my $harvest = 0;

	if ($mode eq 'install') {
		$found   = 1;
		$harvest = 1;
	}

	my $latest_version;
	my $stages = {};

	my @cleaning = ();
	
	while (<SCHEMA>) {
		
		if ($_ =~ /^-{2,}\s*(\d\d\d\d-\d\d-\d\d(?:\.\d+)?)/) {
			if ($schema_version eq $1) {
				# warn "we found latest declaration, start to find next declaration\n";
				$found = 1;
				next;
			}
			next unless $found;

			$latest_version = $1;
			$harvest = 1;
		} elsif ($harvest) {
			die "first string of schema file must contains stage date in format: '--- YYYY-MM-DD'"
			 	unless defined $latest_version;
			
			$stages->{$latest_version} .= $_;
		}

		if (/\bcreate\s+($can_created)\s+['`"]*(\w+)['`"]*/i and ! /^\-\-/) {
			push @cleaning, "drop $1 `$2`";
		}
	}

	close SCHEMA;
	
	if (! defined $latest_version or $latest_version eq '') {
		$latest_version = $schema_version;
	}
	
	if ($settings->{dry_run}) {
		my $version = {db => $schema_version, schema => $latest_version};
		return $version;
	}
	
	if ($mode eq 'install' and $clean) {
		print "\nWARNING!\n\nthese strings applied to database before installing new schema:\n",
			join "\n", @cleaning,
			"\n\ndo you really want to clean all data from database? ";
		my $clean_check = getc;
		critical "clean requested, but not approved! exiting…"
			unless $clean_check =~ /^y$/i;
	} else {
		@cleaning = ();
	}
	
	if ($schema_version eq $latest_version) {
		print "no updates, db schema version: $schema_version\n";
		return;
	}

	print "current version: $schema_version\n";
	print "    new version: $latest_version\n";
	print "\nupdating... ";

	# i don't want to check for errors here
	map {
		print "doing '$_'";
		eval {$dbh->do ($_)};
	} reverse @cleaning
		if scalar @cleaning;

	# updating schema
	
	my $delimiter = ';';
	
	$dbh->{RaiseError} = 1;
	
	eval {
		
		foreach my $stage (sort keys %$stages) {
			
			debug "starting stage $stage";
			
			my @new_items = split /(?<=\;)\s+/, $stages->{$stage}; 
			
			$dbh->begin_work;

			my $statement;
			my $wait_for_delimiter = $delimiter;

			foreach (@new_items) {
				
				s/^\s+//s;
				s/\s+$//s;
				
				# fix for stupid mysql delimiters
				if (/(.*)^delimiter\s+([^\s]+)(?:\s+(.*))?/ms) {

					if ($wait_for_delimiter ne $delimiter and $2 eq $delimiter) {

						my $old_delimiter = $wait_for_delimiter;

						# routine or trigger body finished
						$wait_for_delimiter = $2;

						$statement .= "\n" . $1;
						debug ("delimiter changed to default");

						my @routines = split /\Q$old_delimiter\E/, $statement;

						foreach my $routine (@routines) {
							next if $routine =~ /^\s+$/s;
							debug ("doing \n$routine");
							$dbh->do ($routine);
						}

					} elsif ($wait_for_delimiter eq $delimiter and $2 ne $delimiter) {

						# we must change delimiter for routine or trigger body
						debug ("delimiter changed from default to $2");
						$wait_for_delimiter = $2;
						$statement = $3;

					} else {
						critical "something wrong with delimiter. default: '$delimiter', we want '$wait_for_delimiter', but receive '$1'";
					}

					next;

				} elsif ($wait_for_delimiter ne $delimiter) {
					# accumulating statement
					$statement .= "\n" . $_;
				} else {

					debug ("doing $_");
					$dbh->do ($_);

				}
			}

			my $sth;
			if ($schema_version eq 'NEW') {
				debug "preparing $ver_ins";
				$sth = $dbh->prepare ($ver_ins);
				$schema_version = 'DIRTY_HACK';
			} else {
				debug "preparing $ver_upd";
				$sth = $dbh->prepare ($ver_upd);
			}

			debug "executing ['$stage', '$ver_fld']";

			my $status = $sth->execute ($stage, $ver_fld);
			critical "can't setup schema version\n"
				unless $status;
			
			$dbh->commit;
			
		}
	};

	if ($@){
		print "eval errors: $@\n"
			if $@ ne $dbh->errstr;

		print "dbh errors: " . $dbh->errstr . "\n"
			unless $dbh->{RaiseError};

		# print "database error: $@\n";
		# print "database error: " . $dbh->errstr .  "\n";
		eval {$dbh->rollback};
		warn "can't apply new db schema, rollback\n";
		return;
	}

	print "done\n";
	return 1;
	
}

sub db {
	my ($pack, $libs) = &_script_wrapper;
	
	my $root = $pack->root;
	
	my $config = $pack->config;
	
	
}

1;