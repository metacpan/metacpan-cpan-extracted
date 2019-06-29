#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Tools qw(:all);

plan tests => @Sport::Analytics::NHL::Tools::EXPORT_OK+0;
for my $sub (@Sport::Analytics::NHL::Tools::EXPORT_OK) {
	ok(defined &$sub, "sub $sub defined");
}
