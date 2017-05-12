#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Package::Stash;

{
    package Foo;
}

{
    package Bar;
    sub bar { }
}

{
    my $stash = Package::Stash->new('Foo');
    my @ISA = ('Bar');
    @{$stash->get_or_add_symbol('@ISA')} = @ISA;
    isa_ok('Foo', 'Bar');
    isa_ok(bless({}, 'Foo'), 'Bar');
}

{
    package Baz;
    sub foo { }
}

{
    my $stash = Package::Stash->new('Quux');
    {
        my $isa = $stash->get_or_add_symbol('@ISA');
        @$isa = ('Baz');
        isa_ok('Quux', 'Baz');
        isa_ok(bless({}, 'Quux'), 'Baz');
        ok(Quux->can('foo'));
    }
    {
        my $isa = $stash->get_or_add_symbol('@ISA');
        @$isa = ('Bar');
        isa_ok('Quux', 'Bar');
        isa_ok(bless({}, 'Quux'), 'Bar');
        ok(Quux->can('bar'));
    }
}

done_testing;
