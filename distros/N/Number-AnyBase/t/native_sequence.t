#!perl

use strict;
use warnings;

use constant {
    SEQ_LENGTH => 100_000,
    DEC_START  => 1
};

use Test::More;
plan tests => 2;

use Number::AnyBase;

my @asc_sequence;
my @desc_sequence;
my @asc_sequence2;

my $base = Number::AnyBase->new('m'..'z');

{
    my $base_num = $base->to_base(DEC_START - 1);
    push @asc_sequence, $base_num = $base->next($base_num)
        for 1 .. SEQ_LENGTH - 1
}

{
    my $base_num = $base->next( $asc_sequence[-1] );
    unshift @desc_sequence, $base_num = $base->prev($base_num)
        for 1 .. SEQ_LENGTH - 1
}

is_deeply \@desc_sequence, \@asc_sequence, 'next and prev';

is $base->prev( $base->alphabet->[0] ), undef, 'prev of zero is undef';
