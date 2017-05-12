#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

eval <<'EVAL';
use STUN::RFC_5389;
EVAL

cmp_ok( $@, 'eq', '', 'loading STUN::RFC_5389' );
