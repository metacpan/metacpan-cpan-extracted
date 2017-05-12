use Test::Most;
use Try::Tiny;
use Safe::Isa;
use Carp;
use Data::Munge qw/elem/;

use_ok 'Odoo::Database::Manager';


sub assuming_dbman_connection {
    my %params = @_;
    my %conninfo = %{$params{conninfo} // {}};
    my $test = $params{test};
    my $dbman = Odoo::Database::Manager->new(%conninfo);
    SKIP: {
        my $connectfailed;
        try {
            $dbman->list_databases;
        }
        catch {
            if ($_->$_isa('failure::odoo::rpc::http::connection')) {
                $connectfailed = $_;
            }
        };
        carp "Failed to connect to Odoo server, tests will be skipped" if $connectfailed;
        skip $connectfailed->msg, 1 if $connectfailed;
        subtest 'assuming connected to server' => sub {
            $test->($dbman);
        };
    }
}


assuming_dbman_connection(conninfo => {password => 'admin'}, test => sub {
    my ($dbman) = @_;
    my @initial_dbs;
    lives_ok { @initial_dbs = $dbman->list_databases } 'get list of databases';
    explain '\@initial_dbs = ', \@initial_dbs;
    my $newdb = next_test_db($dbman);
    ok( (not (elem $newdb => \@initial_dbs)) => "PRE: database $newdb not there");
    lives_ok { 
        $dbman->createdb(
            dbname => $newdb, lang => 'en_GB',
            admin_password => 'helloworld')
    } "create database $newdb";
    ok( (elem $newdb => [$dbman->list_databases]) => "database $newdb now in database list");

    lives_ok {
        $dbman->dropdb($newdb)
    } "drop database $newdb";
    ok( (not (elem $newdb => [$dbman->list_databases])) => "database $newdb no longer in database list");
});

sub next_test_db {
    my ($dbman) = @_;
    my $num = 1;
    my @current_dbs = $dbman->list_databases;
    my $format = 'odmtest%d';
    my $dbname = sprintf($format, $num);
    while (elem $dbname => \@current_dbs) {
        $dbname = sprintf($format, ++$num);
    }
    return $dbname;
}

done_testing;
