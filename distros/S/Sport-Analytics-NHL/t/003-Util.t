#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Util;

plan tests => @Sport::Analytics::NHL::Util::EXPORT - 1;

my $string = 'x';

my $tmp_file = '/tmp/mhs-test';
ok(write_file($string, $tmp_file), 'file written');
is(-s $tmp_file, length($string), 'file written correctly');

my $x = read_file($tmp_file);
is($x, $string, 'file read back correctly');
is(get_seconds('01:23'), 83, 'get seconds correct');
my $ev = {a => 1};
my $broken = {a => 2, b => 1};
fill_broken($ev, $broken);
is_deeply($ev, $broken, 'fill_broken correct');
is_deeply([my_uniq {$_ % 2} 2,4,5 ], [2,5], 'my uniq correct');
$string = 'abc dx   egs ';
is(normalize_string($string), 'ABC DX EGS', 'normalize correct');
