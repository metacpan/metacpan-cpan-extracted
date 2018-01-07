#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 12;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{
    # reset()

    my $mock = Mock::Sub->new;

    my $foo = $mock->mock('One::foo', return_value => 99);
    my $ret1 = Two::test;

    is ($ret1, 99, "before reset, return_value is ok");

    $foo->reset;

    my $ret2 = Two::test;

    is ($ret2, undef, "after reset, return_value is reset");

    $foo->side_effect( sub {return 10;} );

    my $ret3 = Two::test;

    is ($ret3, 10, "before reset, side_effect does the right thing");

    $foo->reset;

    my $ret4 = Two::test;

    is ($ret4, undef, "after reset, side_effect does nothing");

    $foo = $mock->mock('One::foo');
    Two::test;
    is ($foo->name, 'One::foo', "before reset, obj has sub name");

    $foo->reset;

    is ($foo->name, 'One::foo', "after reset, obj has sub name");
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    Two::test; 
    Two::test; 

    is ($foo->called, 1, "before reset, called == 1");
    is ($foo->called_count, 2, "before reset, called_count == 2");

    $foo->reset;

    is ($foo->called, 0, "after reset, called == 0");
    is ($foo->called_count, 0, "after reset, called_count == 0");
}
