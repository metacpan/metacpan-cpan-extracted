#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

eval <<'EVAL';
use Net::ENUM;
EVAL

cmp_ok( $@, 'eq', '', 'loading Net::ENUM' );
