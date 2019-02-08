use Modern::Perl;
use Carp;
use String::Util ':all';
use DBI;
use File::Which;
use File::Path 'remove_tree';

use constant DBNAME => 'testmysqlorm';

sub get_dbh {

	my $dbh = DBI->connect(
		'dbi:mysql:host=localhost',
		'root', undef, { RaiseError => 1, PrintError => 0 }
	);

	eval { $dbh->do( "use " . DBNAME ); };

	return $dbh;
}

sub check_connection {

	eval { get_dbh(); };
	if ($@) {
		print STDERR $@ . "\n";
		return 0;
	}

	return 1;
}

sub remove_tmp {

	if ( !$ENV{SKIP_REMOVE_TREE} ) {
		remove_tree('tmp');
		verbose("tmp cleaned");
	}
}

sub mysql_binary_exists {

	if ( which('mysql') ) {
		return 1;
	}

	return 0;
}

sub get_mysql_cmdline {

	if ( !mysql_binary_exists ) {
		die "mysql binary not found";
	}

	my $cmd = 'mysql ';
	$cmd .= '-u root ';
	$cmd .= '-h localhost ';
	$cmd .= '-D testmysqlorm ';

	return $cmd;
}

sub drop_db {

	my $dbh = get_dbh();
	$dbh->do("drop database if exists testmysqlorm");
	verbose("dropped testmysqlorm");
}

sub verbose {

	if ( $ENV{VERBOSE} ) {
		print STDERR "[VERBOSE] @_\n";
	}
}

sub load_db {

	my $dbh = get_dbh();
	$dbh->do("create database testmysqlorm");

	my $cmd = get_mysql_cmdline();

	my $file = 'sql';
	if ( -e $file ) {
	}
	elsif ( -e "../t/$file" ) {
		$file = "../t/$file";
	}
	elsif ( -e "t/$file" ) {
		$file = "t/$file";
	}
	else {
		confess "can't find $file";
	}

	$cmd = sprintf( "%s < %s", get_mysql_cmdline(), $file );
	sysprint($cmd);

	verbose("loaded testmysqlorm");
}

sub sysprint {
	my $cmd = shift;
	verbose($cmd);
	system($cmd);
	die if $?;
}

1;
