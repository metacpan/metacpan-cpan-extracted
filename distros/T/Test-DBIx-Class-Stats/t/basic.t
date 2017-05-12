use strict; use warnings;

use Test::More;
use Test::DBIx::Class::Stats;
use lib 't/lib';

use Test::DBIx::Class {
    schema_class => 'TestDB::Schema',
};

with_stats 'test with inferred Schema', sub {
    my $stats = shift;

    my $rs = Schema->resultset('Foo')->search();
    is $stats->call_count, 0, 'No calls on preparing RS';

    my @foo = $rs->all;
    is $stats->call_count, 1, '1 call after preparing RS';
};

my $db = Schema;

with_stats 'test with explicit schema passing', $db, sub {
    my $stats = shift;

    my $rs = $db->resultset('Foo');
    $rs->create({ foo => 1 });
    $rs->create({ foo => 2 });
    $rs->create({ foo => 3 });

    my $result = $rs->get_column('foo')->sum;
    is $result, 6, 'Check method call';
    
    is $stats->call_count, 4, '4 calls after this test';
};

done_testing;
