use warnings;
use strict;

use Test::More tests => 37;

my $test_input = "\x01\x02\x04\x08\x10\x20\x40\x80" .
	"\x92\x07\x58\x97\x0c\x21\xd5\x82\xc8\xb8\xec\xe8\xb2\x85\x1e\x4c";
my $x;
my $f;
$/ = \3;

#is scalar(<$f>), "\x08\x04\x02\x01\x80\x40\x20\x10";
#is scalar(<$f>), "\x97\x58\x07\x92
#is scalar(<$f>), "\xe8\xec\xb8\xc8\x4c\x1e\x85\xb2";

open($f, "+<:bitswap(24)", \($x = $test_input));
is scalar(<$f>), "\x08\x04\x02";
is scalar(<$f>), "\x01\x80\x40";
is scalar(<$f>), "\x20\x10\x97";
is scalar(<$f>), "\x58\x07\x92";
ok close($f);
$f = undef;

open($f, "+<:bitswap(24)", \($x = $test_input));
is scalar(<$f>), "\x08\x04\x02";
is scalar(<$f>), "\x01\x80\x40";
is scalar(<$f>), "\x20\x10\x97";
ok close($f);
$f = undef;

open($f, "+<:bitswap(24)", \($x = $test_input));
is scalar(<$f>), "\x08\x04\x02";
is scalar(<$f>), "\x01\x80\x40";
is scalar(<$f>), "\x20\x10\x97";
is scalar(<$f>), "\x58\x07\x92";
ok seek($f, 0, 0);
$f = undef;

open($f, "+<:bitswap(24)", \($x = $test_input));
is scalar(<$f>), "\x08\x04\x02";
is scalar(<$f>), "\x01\x80\x40";
is scalar(<$f>), "\x20\x10\x97";
ok !seek($f, 0, 0);
$f = undef;

open($f, "+<:bitswap(24)", \($x = $test_input));
is scalar(<$f>), "\x08\x04\x02";
is scalar(<$f>), "\x01\x80\x40";
is scalar(<$f>), "\x20\x10\x97";
is scalar(<$f>), "\x58\x07\x92";
ok print($f "\xaa\xbb\xcc\xdd");
$f = undef;
isnt $x, $test_input;

open($f, "+<:bitswap(24)", \($x = $test_input));
is scalar(<$f>), "\x08\x04\x02";
is scalar(<$f>), "\x01\x80\x40";
is scalar(<$f>), "\x20\x10\x97";
# error is bizarrely not reported here
print $f "\xaa\xbb\xcc\xdd";
$f = undef;
is $x, $test_input;

open($f, "+<:bitswap(24)", \($x = $test_input));
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
ok close($f);
$f = undef;
is substr($x, 0, 12), "\xaa\xcc\xbb\xaa\xbb\xaa\xcc\xbb\xcc\xbb\xaa\xcc";

open($f, "+<:bitswap(24)", \($x = $test_input));
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
ok !close($f);
$f = undef;

open($f, "+<:bitswap(24)", \($x = $test_input));
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
ok seek($f, 0, 0);
$f = undef;
is substr($x, 0, 12), "\xaa\xcc\xbb\xaa\xbb\xaa\xcc\xbb\xcc\xbb\xaa\xcc";

open($f, "+<:bitswap(24)", \($x = $test_input));
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
ok !seek($f, 0, 0);
$f = undef;

open($f, "+<:bitswap(24)", \($x = $test_input));
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
is scalar(<$f>), "\x82\xd5\x21";
$f = undef;
is substr($x, 0, 12), "\xaa\xcc\xbb\xaa\xbb\xaa\xcc\xbb\xcc\xbb\xaa\xcc";

open($f, "+<:bitswap(24)", \($x = $test_input));
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
print $f "\xaa\xbb\xcc";
is scalar(<$f>), undef;
$f = undef;

1;
