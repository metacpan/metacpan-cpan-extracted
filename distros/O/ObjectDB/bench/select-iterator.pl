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
        1000,
        {
            'find' => sub {
                my $iterator = Person->find(limit => 1000);

                while ($iterator->next) {
                }
            },
            'find (hash)' => sub {
                my $iterator = Person->find(limit => 1000, rows_as_hashes => 1);

                while ($iterator->next) {
                }
            },
            'find_by_compose' => sub {
                my $iterator = Person->table->find_by_compose(table => 'person', columns => [qw/id name profession/], limit => 1000);

                while ($iterator->next) {
                }
            },
            'find_by_compose (hash)' => sub {
                my $iterator = Person->table->find_by_compose(table => 'person', columns => [qw/id name profession/], limit => 1000, rows_as_hashes => 1);

                while ($iterator->next) {
                }
            },
            'find_by_sql' => sub {
                my $iterator = Person->table->find_by_sql('SELECT * FROM person LIMIT 1000', []);

                while ($iterator->next) {
                }
            },
            'find_by_sql (hash)' => sub {
                my $iterator = Person->table->find_by_sql('SELECT * FROM person LIMIT 1000', [], rows_as_hashes => 1);

                while ($iterator->next) {
                }
            },
            'DBI' => sub {
                my $sth = TestDBH->dbh->prepare('SELECT * FROM person LIMIT 1000');
                $sth->execute();

                while (my $row = $sth->fetchrow_arrayref) {
                }
              }
        }
    );
}

bench_select();
