use strict;
use warnings;
use lib 'lib';
use lib 't/lib';

use TestDBH;
use TestEnv;
use Person;
use Benchmark qw(cmpthese);

sub bench_select {
    my $i = 0;

    TestEnv->prepare_table('person');

    for (1 .. 1000) {
        my $sth = TestDBH->dbh->prepare('INSERT INTO person (name) VALUES (?)');
        $sth->execute('name' . $_);
    }

    cmpthese(
        30_000,
        {
            'find' => sub {
                Person->find(limit => 1000);
            },
            'find_by_compose' => sub {
                Person->table->find_by_compose(table => 'person', columns => [qw/id name profession/], limit => 1000);
            },
            'find_by_sql' => sub {
                Person->table->find_by_sql('SELECT * FROM person LIMIT 1000', []);
            },
            'DBI' => sub {
                my $sth = TestDBH->dbh->prepare('SELECT * FROM person LIMIT 1000');
                $sth->execute();
              }
        }
    );
}

bench_select();
