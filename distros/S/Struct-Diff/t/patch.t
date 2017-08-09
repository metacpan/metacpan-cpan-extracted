#!perl -T

use strict;
use warnings;
use Struct::Diff qw(diff patch);
use Test::More tests => 16;

### primitives ###
my ($a, $b) = (0, 0);
patch(\$a, diff($a, $b));
ok($a == $b);

($a, $b) = (0, 0);
patch(\$a, diff($a, $b, "noU" => 1));
ok($a == $b);

($a, $b) = (0, 1);
patch(\$a, diff($a, $b));
ok($a == $b);

### arrays ###
($a, $b) = ([ 0 ], [ 0, 1 ]);
patch($a, diff($a, $b));
is_deeply($a, $b, "ARRAY: item added to the end");

($a, $b) = ([ 0, 1 ], [ 0 ]);
patch($a, diff($a, $b));
is_deeply($a, $b, "ARRAY: item removed from the end");

($a, $b) = ([ 0, 2 ], [ 0, 1, 2 ]);
patch($a, diff($a, $b));
is_deeply($a, $b, "ARRAY: item inserted to the middle");

($a, $b) = ([ 0, 1, 2 ], [ 0, 2 ]);
patch($a, diff($a, $b));
is_deeply($a, $b, "ARRAY: item removed from the middle");

($a, $b) = ([ 0, 1 ], [ 0 ]);
patch($a, diff($a, $b, trimR => 1));
is_deeply($a, $b, "ARRAY: removed item, trimmedR");

my $sub_array = [ 0, [ 11, 12 ], 2 ];
$a = [ 0, [[ 100 ]], [ 20, 'a' ], $sub_array, 4 ];
$b = [ 0, [[ 100 ]], [ 20, 'b' ], $sub_array, 5 ];

patch($a, diff($a, $b));
is_deeply($a, $b, "ARRAY: ext common link");

$a = [ 0, [[ 100 ]], [ 20, 'a' ], $sub_array, 4 ]; # restore $a
patch($a, diff($a, $b, 'noU' => 1));
is_deeply($a, $b, "ARRAY: same, but patch doesn't contain Unchanged");

### hashes ###
($a, $b) = ({ 'a' => 'av' }, { 'a' => 'av', 'b' => 'bv' });
patch($a, diff($a, $b));
is_deeply($a, $b, "HASH: added key");

($a, $b) = ({ 'a' => 'av', 'b' => 'bv' }, { 'a' => 'av' });
patch($a, diff($a, $b));
is_deeply($a, $b, "HASH: removed key");

($a, $b) = ({ 'a' => 'av', 'b' => 'bv' }, { 'a' => 'av' });
patch($a, diff($a, $b, trimR => 1));
is_deeply($a, $b, "HASH: removed key, trimmedR");

$a = { 'a' => 'a1', 'b' => { 'ba' => 'ba1', 'bb' => 'bb1' }, 'c' => 'c1' };
$b = { 'a' => 'a1', 'b' => { 'ba' => 'ba2', 'bb' => 'bb1' }, 'd' => 'd1' };

patch($a, diff($a, $b));
is_deeply($a, $b, "HASH: complex test");

### mixed structures ###
$a = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 4 ]}}, 8 ]};
$b = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 3 ]}}, 8 ]};

patch($a, diff($a, $b));
is_deeply($a, $b, "MIXED: complex");

$a = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 4 ]}}, 8 ]}; # restore a
patch($a, diff($a, $b, noO => 1, noU => 1));
is_deeply($a, $b, "MIXED: same, but patch doesn't contain Unchanged");
