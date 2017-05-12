#!/usr/bin/env perl
# difficult utf8 situations

use warnings;
use strict;
use utf8;

use Test::More tests => 7;
use Encode  qw/is_utf8/;

use String::Print 'sprintp';

my $latin1 = chr 230;  # æ
ok(!is_utf8 $latin1);

my $format = "a${latin1}b%sc";
my $out1   = sprintp $format, 'z';
ok(is_utf8($out1), 'formatted with normal param');
is($out1, 'aæbzc');

my $out2   = sprintp $format, $latin1;
ok(is_utf8($out2), 'formatted with latin1');
is($out2, 'aæbæc');

my $out3   = sprintp $format, 'Ø';
ok(is_utf8($out3), 'formatted with utf8');
is($out3, 'aæbØc');
