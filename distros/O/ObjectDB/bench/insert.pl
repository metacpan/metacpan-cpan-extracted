use strict;
use warnings;
use lib 'lib';
use lib 't/lib';

use TestDBH;
use TestEnv;
use Person;
use Benchmark qw(cmpthese);

sub bench_insert {
    my $i = 0;

    TestEnv->prepare_table('person');

    cmpthese(
        30_000,
        {
            'create' => sub {
                Person->new(name => 'name' . $i++)->create;
            },
            'DBI' => sub {
                my $sth = TestDBH->dbh->prepare('INSERT INTO person (name) VALUES (?)');
                $sth->execute('name' . $i++);
              }
        }
    );
}

bench_insert();
