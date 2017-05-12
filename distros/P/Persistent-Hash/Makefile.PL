#!/usr/bin/perl
use ExtUtils::MakeMaker;
use Data::Dumper;
use Getopt::Long;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $config = {
	extended => 0,
};

my $options = {};
$options->{help} = \&usage;

Getopt::Long::GetOptions(
	$options, 
	"help", 
	"extended_tests", 
	"dbpw=s", 
	"dbuser=s", 
	"oracle_home=s", 
	"dsn=s"
);

if (-e 't/config.pl')
{
	unlink 't/config.pl';
}

if ($options->{extended_tests})
{
	$config->{extended} = 1;

	eval "use DBI";
	if ($@)
	{
		die "DBI has to be installed in order to test/install Persistent::Hash ($@)\n";
	}

	$config->{dsn}           = $options->{dsn};
	$config->{dbuser}          = $options->{dbuser} || 'root';
	$config->{dbpw}        = $options->{dbpw};
	$config->{oracle_home}   = $options->{oracle_home};

	die "You need to specify a DSN to run extended tests. Rerun with --help" if not defined $config->{dsn};
	die "You need to specify a user to run extended tests. Rerun with --help" if not defined $config->{dbuser};

	if ($config->{dsn} =~ /Oracle/ && !$ENV{'ORACLE_HOME'})
	{
		$ENV{'ORACLE_HOME'} = $config->{oracle_home};
	}
	my $dbh = DBI->connect(
	  $config->{dsn}, $config->{dbuser}, $config->{dbpw}, {
		  RaiseError => 0,
		  Warn       => 0,
		  PrintError => 1,
	  }) || &creve("Could not establish a connection to DSN $dsn: $DBI::errstr");

	print "\n\nConnected.\n";


	&creve("User requested to stop.") if ((my $storage = ask("
Please choose a storage module to run tests (default: MySQL):
MySQL
Oracle
PostgreSQL 
")) =~ /n|no/i);

	$config->{storage_module} = $storage || 'MySQL';

	&creve("User requested to stop.") if (ask("

###########################################################################
#			       WARNING!
###########################################################################
Extended tests require the creation of the test tables. 
The definitions for these tables is defined in docs/test_tables.sql.

Please cancel tests and create those tables before continuing.

If those tables exists, all data in them will be cleared at each test run.

Are you ready ? (y|n)

  		") =~ /n|no/i);

	print "Clearing data in tables...\n";
	$dbh->do('DELETE FROM phash_tests_info') || die $DBI::errstr;
	$dbh->do('DELETE FROM phash_tests_data') || die $DBI::errstr;
	$dbh->do('DELETE FROM phash_tests_index') || die $DBI::errstr;
	$dbh->disconnect();
	print "Done. Disconnected.\n";

	print "Generating t/config.pl\n";
	open(CONFIG, ">t/config.pl") || &creve("Could not write to t/config.pl");
	my $config_dump = Dumper $config;
	$config_dump =~ s/\$VAR1 \=//g;
	print CONFIG $config_dump;
	close CONFIG;
}

WriteMakefile(
  'NAME'         => 'Persistent::Hash',
  'VERSION_FROM' => 'Hash.pm',                               # finds $VERSION
  'AUTHOR'       => 'Benoit Beausejour <bbeausej\@pobox.com>',
  'clean'        => { 'FILES' => 'pod2htm* t/config.pl', },
  'dist'    => { 'PREOP' => 'pod2text Hash.pod > README; pod2html Hash.pod > docs/index.html; pod2html Hash/API.pod > docs/API.html; pod2html Hash/Manual.pod > docs/Manual.html; pod2html Hash/Storage.pod > docs/Storage.html;', },
);
exit;

sub creve
{
	my $msg = shift;
	unlink('t/config.pl');

	print STDERR $msg . "\n";
	WriteMakefile(
	  'NAME'         => 'Persistent::Hash',
	  'VERSION_FROM' => 'Hash.pm',
	  'clean' => { FILES => 'pod2htm* t/config.pl', },
	  'PREREQ_PM'   => 
	  {
		'DBI'	=> '0',
    	  },
  	  'dist'    => { 'PREOP' => 'pod2text Hash.pod > README; pod2html Hash.pod > docs/index.html; pod2html Hash/API.pod > docs/API.html; pod2html Hash/Manual.pod > docs/Manual.html; pod2html Hash/Storage.pod > docs/Storage.html;', },
	);
	exit;
}

sub ask
{
	my $question = shift;
	my $cache    = shift;

	print "$question \n[$cache] ";
	my $answer = <STDIN>;
	chomp $answer;
	if (!$answer) {$answer = $cache;}
	return $answer;
}

sub usage
{
	print <<"EOF";
Usage: perl Makefile.PL
--help			Prints this text
--extended_tests	Will run extended tests
--dsn			DSN to use for the tests (dbi:driver:db;host=hostname)
--dbuser		Database User who has INSERT, DELETE privileges on the DSN
--dbpw			Database User password
--oracle_home		If using an Oracle DSN

EOF
	exit;
}
