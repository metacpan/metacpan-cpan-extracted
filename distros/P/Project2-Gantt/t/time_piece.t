#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Time::Piece;

my $date_str = '2004-07-21 00:00:00';
my $date_fmt = '%Y-%m-%d %H:%M:%S';

my $t = Time::Piece->strptime($date_str, $date_fmt);

isa_ok($t,'Time::Piece');

is($t->strftime($date_fmt), $date_str, "Check strftime");

is($t->mday, 21, "Check day");
done_testing();

