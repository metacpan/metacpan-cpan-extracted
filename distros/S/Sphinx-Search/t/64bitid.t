#! /usr/bin/perl

# Copyright 2007 Jon Schutz, all rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License.

use strict;
use warnings;

use Sphinx::Search;
use Test::More tests => 21;

my $sphinx = Sphinx::Search->new;
ok($sphinx, "Constructor");

my @tests = ( 0, 1, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, '4294967296', '9223372036854775807', '9223372036854775808', '18446744073709551615');

for my $x (@tests) {
#    print $x . " " . $sphinx->_sphUnpackU64($sphinx->_sphPackU64($x)) . "\n";
    ok($sphinx->_sphUnpackU64($sphinx->_sphPackU64($x)) == $x, "64 bit unsigned transfer $x");
}

my @signed_tests = ( 0, 1, -1, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, -0x7FFFFFFF, -0x80000000, -0xFFFFFFFF, '-4294967296', '-9223372036854775807');

for my $x (@signed_tests) {
    my $packed = $sphinx->_sphPackI64($x);
    ok($sphinx->_sphUnpackI64($sphinx->_sphPackI64($x)) == $x, "64 bit signed transfer $x");
}
