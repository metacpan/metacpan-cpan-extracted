#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Util qw(:all);

plan tests => 16;

my $string = 'x';

my $tmp_file = '/tmp/mhs-test';
ok(write_file($string, $tmp_file), 'file written');
is(-s $tmp_file, length($string), 'file written correctly');

my $x = read_file($tmp_file);
is($x, $string, 'file read back correctly');
is(get_seconds('01:23'), 83, 'get seconds correct');
is(get_time(83), '01:23', 'get time correct');
is(get_time(0), '--:--', 'get zero time correct');
is(get_time(0,1), 0, 'get zero time with zero correct');
my $ev = {a => 1};
my $broken = {a => 2, b => 1};
fill_broken($ev, $broken);
is_deeply($ev, $broken, 'fill_broken correct');
is_deeply([my_uniq {$_ % 2} 2,4,5 ], [2,5], 'my uniq correct');
$string = 'abc dx   egs ';
is(normalize_string($string), 'ABC DX EGS', 'normalize correct');
is(get_season_slash_string(2016), '2016/17', 'slash string correct');
my $item = 1;shorten_float_item(\$item);
is($item, 1, 'no shorten of integer');
$item = 1.23344; shorten_float_item(\$item);
is($item, 1.233, 'X.ABCDE shortened');
$item = 12.345; shorten_float_item(\$item);
is($item, 12.35, 'XY.ABCD shortened');
$item = 123.456; shorten_float_item(\$item);
is($item, 123.5, 'XYZ.ABC shortened');
is(initialize('abc def ghk'), 'A. GHK', 'initialize correct');

__END__
