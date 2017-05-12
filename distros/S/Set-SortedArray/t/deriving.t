#!perl

use Test::More tests => 9;

require_ok('Set::SortedArray');

$a = Set::SortedArray->new(qw/ a b c     /);
$b = Set::SortedArray->new(qw/   b c d   /);
$c = Set::SortedArray->new(qw/     c d e /);

is_deeply(
    $a->union($b),    #
    Set::SortedArray->new_presorted(qw/ a b c d /),
    'union ab'
);
is_deeply(
    $a->union( $b, $c ),    #
    Set::SortedArray->new_presorted(qw/ a b c d e /),
    'union abc'
);

is_deeply(
    $a->intersection($b),    #
    Set::SortedArray->new_presorted(qw/ b c /),
    'intersection ab'
);
is_deeply(
    $a->intersection( $b, $c ),    #
    Set::SortedArray->new_presorted(qw/ c /),
    'intersection abc'
);

is_deeply(
    $a->difference($b),            #
    Set::SortedArray->new(qw/ a /),
    'a - b'
);
is_deeply(
    $a->difference($c),            #
    Set::SortedArray->new(qw/ a b /),
    'a - c'
);

is_deeply(
    $a->symmetric_difference($b),    #
    Set::SortedArray->new(qw/ a d /),
    'a % b'
);
is_deeply(
    $a->symmetric_difference($c),    #
    Set::SortedArray->new(qw/ a b d e /),
    'a % c'
);
