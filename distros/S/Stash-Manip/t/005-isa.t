#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Stash::Manip;

{
    package Foo;
}

{
    package Bar;
}

my $stash = Stash::Manip->new('Foo');
my @ISA = ('Bar');
@{$stash->get_package_symbol('@ISA')} = @ISA;
isa_ok('Foo', 'Bar');

done_testing;
