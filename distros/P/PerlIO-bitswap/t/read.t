use warnings;
use strict;

use Test::More tests => 5*10 + 7;

my $test_input = "\x01\x02\x04\x08\x10\x20\x40\x80" .
	"\x92\x07\x58\x97\x0c\x21\xd5\x82\xc8\xb8\xec\xe8\xb2\x85\x1e\x4c";
my $f;

open($f, "<:bitswap(0)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x01\x02\x04\x08\x10\x20\x40\x80";
is scalar(<$f>), "\x92\x07\x58\x97\x0c\x21\xd5\x82";
is scalar(<$f>), "\xc8\xb8\xec\xe8\xb2\x85\x1e\x4c";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(1)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x02\x01\x08\x04\x20\x10\x80\x40";
is scalar(<$f>), "\x61\x0b\xa4\x6b\x0c\x12\xea\x41";
is scalar(<$f>), "\xc4\x74\xdc\xd4\x71\x4a\x2d\x8c";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(2)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x04\x08\x01\x02\x40\x80\x10\x20";
is scalar(<$f>), "\x68\x0d\x52\x6d\x03\x84\x75\x28";
is scalar(<$f>), "\x32\xe2\xb3\xb2\xe8\x25\x4b\x13";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(4)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x10\x20\x40\x80\x01\x02\x04\x08";
is scalar(<$f>), "\x29\x70\x85\x79\xc0\x12\x5d\x28";
is scalar(<$f>), "\x8c\x8b\xce\x8e\x2b\x58\xe1\xc4";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(7)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x80\x40\x20\x10\x08\x04\x02\x01";
is scalar(<$f>), "\x49\xe0\x1a\xe9\x30\x84\xab\x41";
is scalar(<$f>), "\x13\x1d\x37\x17\x4d\xa1\x78\x32";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(8)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x02\x01\x08\x04\x20\x10\x80\x40";
is scalar(<$f>), "\x07\x92\x97\x58\x21\x0c\x82\xd5";
is scalar(<$f>), "\xb8\xc8\xe8\xec\x85\xb2\x4c\x1e";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(16)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x04\x08\x01\x02\x40\x80\x10\x20";
is scalar(<$f>), "\x58\x97\x92\x07\xd5\x82\x0c\x21";
is scalar(<$f>), "\xec\xe8\xc8\xb8\x1e\x4c\xb2\x85";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(32)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x10\x20\x40\x80\x01\x02\x04\x08";
is scalar(<$f>), "\x0c\x21\xd5\x82\x92\x07\x58\x97";
is scalar(<$f>), "\xb2\x85\x1e\x4c\xc8\xb8\xec\xe8";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(24)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x08\x04\x02\x01\x80\x40\x20\x10";
is scalar(<$f>), "\x97\x58\x07\x92\x82\xd5\x21\x0c";
is scalar(<$f>), "\xe8\xec\xb8\xc8\x4c\x1e\x85\xb2";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(12)", \$test_input);
$/ = \8;
is scalar(<$f>), "\x20\x10\x80\x40\x02\x01\x08\x04";
is scalar(<$f>), "\x70\x29\x79\x85\x12\xc0\x28\x5d";
is scalar(<$f>), "\x8b\x8c\x8e\xce\x58\x2b\xc4\xe1";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

open($f, "<:bitswap(36)", \$test_input);
$/ = \3;
is scalar(<$f>), "\x01\x02\x04";
$/ = \10;
is scalar(<$f>), "\x08\x10\x20\x40\x80\xc0\x12\x5d\x28\x29";
$/ = \1;
is scalar(<$f>), "\x70";
$/ = \2;
is scalar(<$f>), "\x85\x79";
$/ = \8;
is scalar(<$f>), "\x2b\x58\xe1\xc4\x8c\x8b\xce\x8e";
is scalar(<$f>), undef;
is scalar(<$f>), undef;
$f = undef;

1;
