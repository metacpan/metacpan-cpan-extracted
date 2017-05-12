use strict;
use ExtUtils::MakeMaker;

# Prompt for the options.
eval { require Config::Tiny };
if ( $@ ) {
    print "\nConfig::Tiny is required in order to configure test database.\n";
    print "If you wish to run this module's tests, please install\n";
    print "Config::Tiny and re-run 'perl Makefile.PL'\n\n";

    # Ensure that no config file exists - as this is our flag for the tests.
    unlink( "test.conf" ); # don't care if it's not there
} else {
    print "\nPlease enter details of a postgres database to use for testing.";
    print qq(

          *********************************************************
          *********************************************************
          ****  WARNING: These tests are destructive.  Do not  ****
          ****  run them on a database containing live data.   ****
          *********************************************************
          *********************************************************

    );
    print "To skip the tests, accept 'undef' for the database name.\n";
    my ($dbname, $dbuser, $dbpass, $dbhost, $dbport);
    $dbname = prompt "\nDatabase name for testing: ", "undef";
    $dbname = "" unless ($dbname and $dbname ne "undef");

    if ( $dbname ) {
        $dbuser = prompt "Database user: ", "undef";
        $dbuser = "" unless ($dbuser and $dbuser ne "undef");
        $dbpass = prompt "Database password: ", "undef";
        $dbpass = "" unless ($dbpass and $dbpass ne "undef");
        $dbhost = prompt "Database host (if needed): ", "undef";
        $dbhost = "" unless ($dbhost and $dbhost ne "undef");
        $dbport = prompt "Port number (if needed): ", "undef";
        $dbport = "" unless ($dbport and $dbport ne "undef");

        my $config = Config::Tiny->new;
        $config->{_} = { dbname => $dbname,
                         dbuser => $dbuser,
                         dbpass => $dbpass,
                         dbhost => $dbhost,
                         dbport => $dbport,
                       };
        $config->write( "test.conf" );
    } else {
        # Ensure that no config file exists - as this is our flag for the tests
        unlink( "test.conf" ); # don't care if it's not there
    }
}

WriteMakefile(
    'NAME'           => 'Search::InvertedIndex::DB::Pg',
    'VERSION_FROM'   => 'lib/Search/InvertedIndex/DB/Pg.pm',
    'PREREQ_PM'      => {
                          'Carp' => 0,
                          'DBD::Pg' => 0,
                          'DBI' => 0,
                          'Search::InvertedIndex' => 0,
                        },
);
