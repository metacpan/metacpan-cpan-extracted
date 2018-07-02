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
