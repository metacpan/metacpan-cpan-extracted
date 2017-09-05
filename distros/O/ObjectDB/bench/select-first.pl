use strict;
use warnings;
use lib 'lib';
use lib 't/lib';

use TestDBH;
use TestEnv;
use Person;
use Benchmark qw(cmpthese);

sub bench_select_first {
    my $i = 0;

    TestEnv->prepare_table('person');

    my $sth = TestDBH->dbh->prepare('INSERT INTO person (name) VALUES (?)');
    $sth->execute('name');

    cmpthese(
        30_000,
        {
            'find' => sub {
                Person->find(first => 1);
            },
            'find_by_compose' => sub {
                Person->table->find_by_compose(table => 'person', columns => [qw/id name profession/], limit => 1);
            },
            'find_by_sql' => sub {
                Person->table->find_by_sql('SELECT * FROM person LIMIT 1', []);
            },
            'DBI' => sub {
                my $sth = TestDBH->dbh->prepare('SELECT * FROM person LIMIT 1');
                $sth->execute();
              }
        }
    );
}

bench_select_first();
