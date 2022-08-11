#!/usr/bin/perl

use strict;
use warnings;
use OptionHash;
use Test::Simple tests => 7;

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
    eval{ ohash_check($def, {}) };
    ok( !$@, 'def vs nothing = fine');
}

{
    eval{ ohash_check({}, {})};
    ok($@, 'passing a thing which is not an OptionHash the function dies');
    ok($@ =~ /not an optionhash/i, 'non-optionhash message looks correct');
}

{
    eval{ ohash_check($def, [])};
    ok($@, 'can\'t check an array');
    ok($@ =~ /not a hashref/i, 'non-hashref message looks correct') or print "$@\n";
}
