# $Id: Makefile.PL,v 1.5 2004-09-06 21:44:55 ezra Exp $
# -*- mode: cperl -*-

use 5.00503;
use ExtUtils::MakeMaker;
use Config;

my $SQLLDRBIN = $^O =~ /win32/i ? 'sqlldr.exe' : 'sqlldr';

# make sure that sqlldr is somewhere in our path.
findSqlldr();

printTestSetup();

WriteMakefile(
	      NAME              => 'Oracle::SQLLoader',
	      VERSION_FROM      => 'lib/Oracle/SQLLoader.pm', # finds $VERSION
	      PREREQ_PM         => {}, # Add DBI, DBD::Oracle when autogenerate control
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM  => 'lib/Oracle/SQLLoader.pm', # retrieve abstract from module
		AUTHOR         => 'Ezra Pagel <ezra@techgnosis.org>') : ()
	      ),
	     );




sub findSqlldr{
  
  print "Searching for SQL*Loader executable ($SQLLDRBIN)\n";
  if (exists $ENV{'ORACLE_HOME'}) {
    if (-x "$ENV{'ORACLE_HOME'}/bin/$SQLLDRBIN") {
      print "Found SQL*Loader executable in $ENV{'ORACLE_HOME'}/bin\n";
      return 1;
    }
    else {
      print "Found ORACLE_HOME environment variable ($ENV{'ORACLE_HOME'}), ".
            "but failed to find SQL*Loader executable ($SQLLDRBIN)\n";
      if (not ExtUtils::MakeMaker::prompt("Search the rest of your PATH? " => 'Y') =~ /^\s*y/i) {
        exit;
      }
    }
  }
  print "Searching your PATH for the sqlldr executable....\n";

  foreach (split($Config{'path_sep'}, $ENV{'PATH'})) {
    if (-x "$_/$SQLLDRBIN") {
      print "Found SQL*Loader executable in $_\n";
      return 1;
    }
  }
  if (not ExtUtils::MakeMaker::prompt("Failed to find the sqlldr executable; ".
				      "do you want to proceed?" => 'Y') =~ /^\s*y/i) {
    exit;
  }
}


sub printTestSetup {
  print <<'INFO'

The test suite will attempt to create a small test table named
SQLLOADER_TEST_TABLE and bulkload it using various settings. To
run the tests, export the ORACLE_USERID environment variable to
$username/$password (e.g. 'scott/tiger'), as well as the database
instance name in the ORACLE_SID environment variable.

INFO
}
