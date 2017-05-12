#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 3;

use_ok('Net::SMTP::Verify');
my $v = Net::SMTP::Verify->new;

isa_ok( $v, 'Net::SMTP::Verify');

cmp_ok( $v->resolve('markusbenning.de'), 'eq', 'affenschaukel.bofh-noc.de', 'lookup markusbenning.de' );
