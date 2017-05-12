package Project::Easy::Helper;

use Class::Easy;

sub run_script {
	my $script = shift;
	my $path   = shift;
	
	my $out = `$script 2>&1`;
	
	my $res = $? >> 8;
	if ($res == 0) {
		debug $path, " … OK\n";
	} elsif ($res == 255) {
		warn $out, $path, " … DIED\n";
		exit;
	} else {
		warn $out, $path, " … FAILED $res TESTS\n";
		exit;
	}
}

# TODO: when status run, new available scripts must be created
sub status {
	my ($project_class, $libs);
	
	eval {
		($project_class, $libs) = &_script_wrapper;
	};
	
	if ($@) {
		&status_fail ($project_class, $libs);
		die $@;
	}
	
	return &status_ok ($project_class, $libs);
	
}

sub status_fail {
	my ($project_class, $libs, $params) = @_;
	
	# my $root = $project_class->root;
	
	# here we must recreate var directories
	# TODO: make it by Project::Easy::Helper service 'install' routine
	
	# my $global_config = $project_class->conf_path->deserialize;
}

sub status_ok {
	my ($pack, $libs, $params) = @_;
	
	my $root = $pack->root;
	
	my $data_files = file->__data__files;
	
	create_scripts ($root, $data_files);
	
	my $lib_dir = $root->append ('lib')->as_dir;
	
	my $includes = join ' ', map {"-I$_"} (@$libs, @INC);
	
	my $files = [];
	my $all_uses = {};
	my $all_packs = {};
	
	$lib_dir->scan_tree (sub {
		my $file = shift;
		
		return 1 if $file->type eq 'dir';
		
		if ($file =~ /\.pm$/) {
			push @$files, $file;
			my $content = $file->contents;

			while ($content =~ m/^(use|package) ([^\$\;\s]+)/igms){
				if ($1 eq 'use') {
					$all_uses->{$2} = $file;
				} else {
					$all_packs->{$2} = $file;
				}
			}
		}
	});
	
	foreach (keys %$all_uses) {
		delete $all_uses->{$_}
			if /^[a-z][a-z0-9]+$/;
	}
	
	my $failed   = {};
	my $external = {};
	
	# here we try to find dependencies
	foreach (keys %$all_uses) {
		$external->{$_} = $all_uses->{$_}
			unless exists $all_packs->{$_};
		
		$failed->{$_} = $all_uses->{$_}
			if ! try_to_use ($_) and ! exists $all_packs->{$_};
	}
	
	debug "external modules: ", join (' ', sort keys %$external), "\n";
	
	warn "requirements not satisfied. you must install these modules:\ncpan -i ",
		join (' ', sort keys %$failed), "\n"
			if scalar keys %$failed;
	
	foreach my $file (@$files) {
		my $abs_path     = $file->abs_path;
		my $rel_path     = $file->rel_path ((ref $root)->current->abs_path);
		my $project_path = $file->rel_path ($root->abs_path);

		# warn "$^X -c $rel_path";
		
		run_script ("$^X $includes -c $abs_path", $rel_path);
		
	}

	# TODO: move db check code to unit
	
	my $db_outdated = 0;
	
	foreach my $datasource (keys %{$pack->config->{db}}) {
		my $ver;
		eval {$ver = update_schema (datasource => $datasource, dry_run => 1);};
		
		next
			unless defined $ver; # if update file not defined
		
		die "datasource '$datasource' error: $@"
			if $@;
		
		if (!$@ and ($ver->{db} ne $ver->{schema})) {
			warn "datasource '$datasource' out-of-date: db ($ver->{db}) vs. schema file ($ver->{schema})\n";
			$db_outdated = 1;
		}
	}

	warn "please update db using: 'bin/updatedb --datasource=<datasource name>'\n"
		if $db_outdated;

	my $test_dir = $root->append ('t')->as_dir;
	
	if (-d $test_dir) {
		$test_dir->scan_tree (sub {
			my $file = shift;
			
			return 1
				if $file->type eq 'dir';
			
			if ($file =~ /\.(?:t|pl)$/) {
				my $path = $file->abs_path;
				
				run_script ("$^X $includes $path", $path);
			}
		});
	}
	
	print "OK\n";
	
	return $pack;
}

1;