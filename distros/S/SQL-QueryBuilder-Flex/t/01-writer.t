
use lib qw( lib );
use strict;
use warnings;

use Test::More tests => 7;

my $package = 'SQL::QueryBuilder::Flex::Writer';
use_ok($package);

can_ok($package, qw/
    clear
    write
    add_params
    get_params
    to_sql
/);

{
    my $writer = $package->new();
    is
        $writer->to_sql(),
        '',
        'checking empty to_sql'
    ;
}

{
    my $writer = $package->new();
    $writer->write('Test1');
    $writer->write('Test2', 1);
    $writer->write('Test3', 2);
    is
        $writer->to_sql(1),
        "Test1\n  Test2\n    Test3",
        'checking to_sql with indent'
    ;
}

{
    my $writer = $package->new();
    $writer->write('Test1');
    $writer->write('Test2', 1);
    $writer->write('Test3', 2);
    is
        $writer->to_sql(),
        "Test1 Test2 Test3",
        'checking to_sql without indent'
    ;
}

{
    my $writer = $package->new();
    $writer->write('Test1', 1);
    $writer->clear();
    is
        $writer->to_sql(),
        '',
        'checking clear'
    ;
}

{
    my $writer = $package->new();
    $writer->add_params('param1', 'param2');
    is
        join(', ', $writer->get_params()),
        'param1, param2',
        'checking params'
    ;
}

1;
