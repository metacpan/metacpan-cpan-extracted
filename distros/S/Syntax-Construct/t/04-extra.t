#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 3;
use Syntax::Construct ();

{   # Hack: match-once in string eval causes 5.10.0 to throw
    # Modification of a read-only value attempted. Could be
    # workarounded by adding reset.
    my $match_once = $] eq '5.010000'
        ? q{ my $r = 'abc' =~ ?b?; reset; $r }
        : q{'abc' =~ ?b?};
    my $result = eval $match_once;

    if (eval { 'Syntax::Construct'->import('??'); 1 }) {
        is($result, 1, '??');
    } else {
        isnt($result, 1, 'not ??');
    }
}


{   my $s = 0;
    eval q{ for my $i qw( 1 2 3 ) { $s += $i } };
    if (eval { 'Syntax::Construct'->import('for-qw'); 1 }) {
        is($s, 6, 'for-qw');
    } else {
        is($s, 0, 'no for-qw');
    }
}


{   my $r = eval q{ [ sub { split / /, 'a b'; @_ }->(1, 2) ] };
    if(eval { 'Syntax::Construct'->import('@_=split'); 1}) {
        is_deeply($r, ['a', 'b'], '@_=split');

    } else {
        is_deeply($r, [1, 2], 'no @_=split');
    }
}
