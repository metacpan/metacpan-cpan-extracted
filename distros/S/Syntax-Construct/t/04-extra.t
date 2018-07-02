#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 2;
use Syntax::Construct ();

SKIP: {
    eval { 'Syntax::Construct'->import('??'); 1 } or skip $@, 1;

    # Hack: match-once in string eval causes 5.10.0 to throw
    # Modification of a read-only value attempted. Could be
    # workarounded by adding reset.
    my $match_once = $] eq '5.010000'
        ? q{ my $r = 'abc' =~ ?b?; reset; $r }
        : q{'abc' =~ ?b?};

    my $result = eval $match_once;
    is($result, 1, '??');
}

SKIP: {
    eval { 'Syntax::Construct'->import('for-qw'); 1 } or skip $@, 1;

    my $s = 0;
    eval q{ for my $i qw( 1 2 3 ) { $s += $i } };
    is($s, 6, 'for-qw');
}
