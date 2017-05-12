#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

eval <<'EVAL';
use Proc::Daemon;
EVAL

cmp_ok( $@, 'eq', '', 'loading Proc::Daemon' );
