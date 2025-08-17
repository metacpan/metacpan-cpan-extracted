#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 8;

use_ok('String::Super');

my $super = String::Super->new;

isa_ok($super, 'String::Super');

is($super->add_utf8("Hello W\N{LATIN SMALL LETTER O WITH DIAERESIS}rld"), 0);
is($super->add_utf8("W\N{LATIN SMALL LETTER O WITH DIAERESIS}rld happiness<ö>"), 1);

ok(length($super->result), 'got result');
ok($super->offset(index => 0) >= 0);
ok($super->offset(index => 1) >= 0);
ok($super->offset(index => 0) != $super->offset(index => 1));

exit 0;

