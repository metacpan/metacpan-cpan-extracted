#!perl

use Test::More tests => 41;

require_ok('Set::SortedArray');

$a = Set::SortedArray->new(qw/ a b /);
$b = Set::SortedArray->new(qw/ a b c d /);
$c = Set::SortedArray->new(qw/     c d /);

ok( $a->is_equal($a),  'equal' );
ok( $a == $a,          'equal overload' );
ok( !$a->is_equal($b), 'not equal' );
ok( !( $a == $b ),     'not equal overload' );

ok( $a->is_disjoint($c),  'disjoint' );
ok( $a != $c,             'disjoint overload' );
ok( !$a->is_disjoint($b), 'not disjoint' );
ok( !( $a != $b ),        'not disjoint overload' );

ok( $a->is_proper_subset($b),  'proper subset' );
ok( $a < $b,                   'proper subset overload' );
ok( !$a->is_proper_subset($a), 'not proper subset' );
ok( !( $a < $a ),              'not proper subset overload' );
ok( !$a->is_proper_subset($c), 'not proper subset disjoint' );
ok( !( $a < $c ),              'not proper subset disjoint overload' );

ok( $b->is_proper_superset($a),  'proper superset' );
ok( $b > $a,                     'proper superset overload' );
ok( !$a->is_proper_superset($a), 'not proper superset' );
ok( !( $a > $a ),                'not proper superset overload' );
ok( !$a->is_proper_superset($c), 'not proper superset disjoint' );
ok( !( $a > $c ),                'not proper superset disjoint overload' );

ok( $a->is_subset($b),  'subset' );
ok( $a <= $b,           'subset overload' );
ok( $a->is_subset($a),  'subset self' );
ok( $a <= $a,           'subset self overload' );
ok( !$a->is_subset($c), 'not subset disjoint' );
ok( !( $a <= $c ),      'not subset disjoint overload' );

ok( $b->is_superset($a),  'superset' );
ok( $b >= $a,             'superset overload' );
ok( $a->is_superset($a),  'superset self' );
ok( $a >= $a,             'superset self overload' );
ok( !$a->is_superset($c), 'not superset disjoint' );
ok( !( $a >= $c ),        'not superset disjoint overload' );

is( $a->compare($b), -1, 'compare -1' );
is( $b->compare($a), 1,  'compare 1' );
is( $a->compare($a), 0,  'compare 0' );
$cmp = $a->compare($c);
is( $cmp, undef, 'compare undef' );

is( $a <=> $b, -1, 'compare -1 overload' );
is( $b <=> $a, 1,  'compare 1 overload' );
is( $a <=> $a, 0,  'compare 0 overload' );
$cmp = $a <=> $c;
is( $cmp, undef, 'compare undef overload' );
