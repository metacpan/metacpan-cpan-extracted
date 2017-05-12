
package OOPS::OOPS1004::Setup; # dummy

package OOPS::OOPS1004;

# Regular expression to match error returned when the database
# has not been initialized:
#
#	mysql		with '1':Table 'PREFIXobject' doesn't exist
# 	sqlite		no such (?:table|table): at dbdimp.c
#	postgresql	with '1':ERROR:  relation "PREFIXobject" does not exist
#
our $nodatarx = qr/with '1':Table '\S+object' doesn't exist| with '1':ERROR:  relation "\S+object" does not exist|no such table: /;

sub initial_setup_real
{
	my ($pkg, %args) = @_;

	my ($dbh, $dbms) = OOPS::OOPS1004->dbiconnect(%args);
	$dbh->disconnect;
	require "OOPS/OOPS1004/$dbms.pm";

	# create tables, initial objects, etc.
	no strict 'refs';
	my $x;
	for my $t (&{"OOPS::OOPS1004::${dbms}::table_list"}()) {
		$x .= "-DROP TABLE $t;\n";
	}
	my ($oldout, $olderr, $obuf, $ebuf);
	if ($ENV{HARNESS_ACTIVE}) {
		open $oldout, ">&", *STDOUT or die "Can't dup STDOUT: $!";
		open $olderr, ">&", *STDERR or die "Can't dup STDERR: $!";
		select(STDOUT);
		$obuf = $|;
		select(STDERR);
		$ebuf = $|;
		close(STDOUT);
		close(STDERR);
	}
	db_domany($pkg, 
		\%args, 
		$x 
		 . &{"OOPS::OOPS1004::${dbms}::tabledefs"}() 
		 . db_initial_values() 
		 . &{"OOPS::OOPS1004::${dbms}::db_initial_values"}(),
		$ENV{HARNESS_ACTIVE});
	if ($ENV{HARNESS_ACTIVE}) {
		open STDOUT, ">&", $oldout or die "Can't dup \$oldout: $!";
		open STDERR, ">&", $olderr or die "Can't dup \$olderr: $!";
		select(STDERR);
		$| = $ebuf;
		select(STDOUT);
		$| = $obuf;
	}
	return $dbms;
}

sub db_initial_values
{
	return <<END;
	INSERT INTO TP_object values (1, 1, 'HASH', 'H', 'V', '0', '0', $SCHEMA_VERSION, 1, 1);
	INSERT INTO TP_attribute values (2, 'user objects', '1', 'R');

	INSERT INTO TP_object values (2, 2, 'HASH', 'H', 'V', '0', '0', 0, 1, 1);
	INSERT INTO TP_attribute values (2, 'internal objects', '2', 'R');
	INSERT INTO TP_attribute values (2, 'VERSION', '$VERSION', '0');
	INSERT INTO TP_attribute values (2, 'SCHEMA_VERSION', '$SCHEMA_VERSION', '0');

	INSERT INTO TP_object values (3, 3, 'HASH', 'H', 'V', '0', '0', 0, 1, 1);
	INSERT INTO TP_attribute values (2, 'counters', '3', 'R');
END
}

sub db_domany
{
	my ($pkgoops, $connectargs, $x, $silent) = @_;
	my ($dbh, $dbms, $prefix);
	if (ref $pkgoops) {
		$dbh = $pkgoops->{dbh};
		$prefix = $pkgoops->{table_prefix};
	} else {
		($dbh, $dbms, $prefix) = OOPS::OOPS1004->dbiconnect(%$connectargs);
	}
	my @ret;
	$x .= ";\n" unless $x =~ /;/;  # if there's just one query...

	while ($x =~ /\G\s*(\S.*?);\n/sgc) {
		my $stmt = $1;
		$stmt =~ s/TP_/$prefix/g;
		print STDERR "do $stmt\n" if $OOPS::OOPS1004::debug_initialize;
		if ($stmt =~ s/^-//) {
			eval { my $r = $dbh->do($stmt) } 
				or do {
					warn "do '$stmt':".$dbh->errstr
						unless $silent;
					$dbh->disconnect;
					$dbh = OOPS::OOPS1004->dbiconnect(%$connectargs);
					push(@ret, $r);
				};
		} else {
			my $r = $dbh->do($stmt) 
				or die "<<$stmt>>".$dbh->errstr; 
			push(@ret, $r);
		}
	}
	die "x='$x'" unless $x =~ /\G\s*\Z/sg;
	$dbh->commit;
	unless (ref $pkgoops) {
		$dbh->disconnect();
	}
	return(@ret);
}

#
# On a failure to load the named_objects hash, auto-initialize the
# database.
#
sub load_failure
{
	my ($oops, $err) = @_;

	die $err 
		unless $err =~ /$nodatarx/;

	die "DBMS not initialized - use auto_init or initial_setup()\n" 
		unless $oops->{args}{auto_initialize} || $ENV{OOPS_INIT};
	
	$oops->{dbh}->disconnect;
	$oops->byebye;
	$oops->initial_setup_real(%{$oops->{args}});
	my ($dbh, $dbms, $prefix) = OOPS::OOPS1004->dbiconnect(%{$oops->{args}});
	$oops->{dbh} = $dbh;
	$oops->initialize();
	$oops->{named_objects} = $oops->load_virtual_object(1);
	return undef;
}

1;
