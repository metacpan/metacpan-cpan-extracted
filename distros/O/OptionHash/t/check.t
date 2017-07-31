#!/usr/bin/perl

use strict;
use warnings;
use OptionHash;
use Test::Simple tests => 3;

my $def = ohash_define( keys => [ qw< fish cats monkeys > ]);
{
    my %x = ( fish => 1, cats => 2, monkeys => 3 );
    eval{ ohash_check($def, \%x) };
    ok( ! $@, 'ohash_check on a valid hash, no exception') or warn $@;
}
{
    my %x = ( fish => 1, cats => 2, monkeys => 3, carrot => 1 );
    eval{ ohash_check($def, \%x) };
    ok( $@, 'ohash_check on a hash with extra key - exception');
}

{
    my %x = ( fish => 1, cats => 2, monkeys => 3, carrot => 1 );
    eval{ ohash_check($def, {}) };
    ok( !$@, 'def vs nothing = fine');
}
