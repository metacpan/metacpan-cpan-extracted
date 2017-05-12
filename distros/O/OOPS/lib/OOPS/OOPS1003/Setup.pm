
package OOPS::OOPS1003::Setup; # dummy

package OOPS::OOPS1003;

our $nodatarx = qr/with '1':no such table: \S+object|with '1':Table '\S+object' doesn't exist| with '1':ERROR:  relation "\S+object" does not exist/;

sub initial_setup_real
{
	my ($pkg, %args) = @_;

	my ($dbh, $dbms) = OOPS::OOPS1003->dbiconnect(%args);
	$dbh->disconnect;
	require "OOPS/OOPS1003/$dbms.pm";

	# create tables, initial objects, etc.
	no strict 'refs';
	my $x;
	for my $t (&{"OOPS::OOPS1003::${dbms}::table_list"}()) {
		$x .= "-DROP TABLE $t;\n";
	}
	db_domany($pkg, \%args, 
		$x 
		. &{"OOPS::OOPS1003::${dbms}::tabledefs"}() 
		. db_initial_values() 
		. &{"OOPS::OOPS1003::${dbms}::db_initial_values"}());
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
	my ($pkgoops, $connectargs, $x) = @_;
	my ($dbh, $dbms, $prefix);
	if (ref $pkgoops) {
		$dbh = $pkgoops->{dbh};
		$prefix = $pkgoops->{table_prefix};
	} else {
		($dbh, $dbms, $prefix) = OOPS::OOPS1003->dbiconnect(%$connectargs);
	}
	while ($x =~ /\G\s*(\S.*?);\n/sg) {
		my $stmt = $1;
		$stmt =~ s/TP_/$prefix/g;
		print STDERR "do $stmt\n" if $OOPS::debug_initialize;
		if ($stmt =~ s/^-//) {
			eval { $dbh->do($stmt) } || do {
				warn "do '$stmt':".$dbh->errstr;
				$dbh->disconnect;
				$dbh = OOPS::OOPS1003->dbiconnect(%$connectargs);
			};
		} else {
			$dbh->do($stmt) || die "<<$stmt>>".$dbh->errstr; 
		}
	}
	$dbh->commit;
	unless (ref $pkgoops) {
		$dbh->disconnect;
	}
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
		unless $oops->{args}{auto_initialize} || $ENV{OOPS::OOPS1003_INIT};
	
	$oops->{dbh}->disconnect;
	$oops->byebye;
	$oops->initial_setup_real(%{$oops->{args}});
	my ($dbh, $dbms, $prefix) = OOPS::OOPS1003->dbiconnect(%{$oops->{args}});
	$oops->{dbh} = $dbh;
	$oops->initialize();
	$oops->{named_objects} = $oops->load_virtual_object(1);
	return undef;
}

1;
