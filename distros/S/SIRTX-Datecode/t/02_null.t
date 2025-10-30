#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 3;

use_ok('SIRTX::Datecode');
my $dc = SIRTX::Datecode->null;
isa_ok($dc, 'SIRTX::Datecode');
ok($dc->is_null);

exit 0;
