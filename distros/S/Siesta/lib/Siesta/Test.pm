package Siesta::Test;
# set up some stuff for testing
use Siesta::Config;
BEGIN {
    my %dbs = (
        pg     => [ 'dbi:Pg:dbname=siesta', 'richardc', undef ],
        mysql  => [ 'dbi:mysql:siesta_test', 'root', undef ],
        sqlite => [ 'dbi:SQLite:t/test.db', '', '' ],
       );
    @Siesta::Config::STORAGE  = @{ $dbs{ $ENV{SIESTA_TEST_DB} || 'sqlite' } };
    $Siesta::Config::MESSAGES = 'messages';
    $Siesta::Config::ARCHIVE  = 't/root/archive';
    $Siesta::Config::LOG_PATH = 't/temp_error';
}
use Siesta::DBI;

sub import {
    my $class = shift;

    if (@_ && $_[0] eq 'init_db') {
        print "# nuking test database\n";
        if ($Siesta::Config::STORAGE[0] =~ /^dbi:SQLite:(.*)/) {
            unlink $1;
        }
        else {
            # assume mysql
            Siesta::DBI->db_Main->do("drop database siesta_test");
            Siesta::DBI->db_Main->do("create database siesta_test");
        }
        Siesta::DBI->init_db;
    }
    require Siesta;
    Siesta->set_sender('Test');

}

1;
