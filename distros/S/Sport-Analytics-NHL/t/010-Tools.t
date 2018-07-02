#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Tools;

plan tests => 1;
for my $var (qw($DB)) {
	ok(scalar(grep { $_ eq $var } @Sport::Analytics::NHL::Tools::EXPORT), "$var exported");
}
