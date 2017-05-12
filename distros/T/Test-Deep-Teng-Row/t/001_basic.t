use strict;
use warnings;

use Test::Tester;
use Test::More;
use Test::mysqld;

use Test::Deep;
use Test::Deep::Teng::Row;

use Teng;
use Teng::Schema::Loader;
use DBI;

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

{
    package MyDB;
    use parent 'Teng';
    1;
}

my $dbh = DBI->connect($mysqld->dsn( dbname => 'test' ));
$dbh->do(q{
    CREATE TABLE `hoge` (
        `id` INT NOT NULL AUTO_INCREMENT,
        name VARCHAR(45) NOT NULL,
        PRIMARY KEY (`id`)
    );
});

my $teng = Teng::Schema::Loader->load(
    dbh => $dbh,
    namespace => 'MyDB',
);

my $foo      = $teng->insert('hoge', { name => 'foo' });
my $bar      = $teng->insert('hoge', { name => 'bar' });
my $dameleon = $teng->insert('hoge', { name => 'dameleon' });
my @rows     = $teng->search('hoge', {}, { order_by => 'id' });

{
    package FakeRow;
    sub new {
        bless {}, shift;
    }

    1;
}

subtest 'fail cmp_deeply' => sub {
    check_test sub {

        cmp_deeply \@rows, [$foo, $bar, $dameleon];
    }, {
        ok => 0,
    };
};

subtest 'fail cmp_deeply by uncorrect object in expected expr' => sub {
    check_test sub {
        cmp_deeply \@rows, +[ map { teng_row($_) } ($foo, $bar, FakeRow->new)];
    }, {
        ok => 0,
        diag => 'expected row is not teng row object',
    };
};

subtest 'fail cmp_deeply by uncorrect object in got expr' => sub {

    check_test sub {
        cmp_deeply [FakeRow->new], [teng_row($dameleon)];
    }, {
        ok => 0,
        diag => 'got row is not teng row object',
    };
};

subtest 'success with single' => sub {

    check_test sub {

        cmp_deeply $dameleon, teng_row($dameleon);
    }, {
        ok => 1,
    };
};

subtest 'success with in array' => sub {
    check_test sub {

        cmp_deeply \@rows, +[ map { teng_row($_) } ($foo, $bar, $dameleon)];
    }, {
        ok => 1,
    };
};

done_testing;
