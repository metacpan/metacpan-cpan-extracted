#!perl

use strict;
use warnings;

# VERSION

use Test::More;
use Test::Deep;

use lib 't';
use Package::Localize;

{ # test basic modules
    my $p1 = Package::Localize->new('Foo');
    my $p2 = Package::Localize->new('Foo');
    is $p1->name, 'Foo::' . $p1->{id}, 'p1->name is correct';
    is $p2->name, 'Foo::' . $p2->{id}, 'p2->name is correct';

    is $p1->inc, 42, 'p1 original scalar';
    is $p1->inc, 43, 'p1 modified scalar';
    is $p2->inc, 42, 'p2 scalar stays same';

    cmp_deeply $p1->var_ar, [ 42, [43] ], 'p1 original array';
    $p1->var_ar->[1] = [ 55 ];
    cmp_deeply $p1->var_ar, [ 42, [55] ], 'p1 modified array';
    cmp_deeply $p2->var_ar, [ 42, [43] ], 'p2 array stays same';

    cmp_deeply $p1->var_h, { foo => {bar => 42}}, 'p1 original hash';
    $p1->var_h->{foo}{bar} = 55;
    cmp_deeply $p1->var_h, { foo => {bar => 55}}, 'p1 modified hash';
    cmp_deeply $p2->var_h, { foo => {bar => 42}}, 'p2 hash stays the same';
}

# { # Test OO modules
    # my $p1 = Package::Localize->new('FooMeth');
    # my $p2 = Package::Localize->new('FooMeth');
    # is $p1->name, 'FooMeth::' . $p1->{id}, 'p1->name is correct';
    # is $p2->name, 'FooMeth::' . $p2->{id}, 'p2->name is correct';

    # my $p1_obj = $p1::SUPER->new;
    # my $p2_obj = $p2::SUPER->new;

    # cmp_deeply $p1->inc, [ isa($p1->name), 42], 'p1 original scalar';
    #is $p1->inc, 43, 'p1 modified scalar';
    # is $p2->inc, 42, 'p2 scalar stays same';

    # cmp_deeply $p1->var_ar, [ 42, [43] ], 'p1 original array';
    # $p1->var_ar->[1] = [ 55 ];
    # cmp_deeply $p1->var_ar, [ 42, [55] ], 'p1 modified array';
    # cmp_deeply $p2->var_ar, [ 42, [43] ], 'p2 array stays same';

    # cmp_deeply $p1->var_h, { foo => {bar => 42}}, 'p1 original hash';
    # $p1->var_h->{foo}{bar} = 55;
    # cmp_deeply $p1->var_h, { foo => {bar => 55}}, 'p1 modified hash';
    # cmp_deeply $p2->var_h, { foo => {bar => 42}}, 'p2 hash stays the same';
# }


done_testing;

__END__

