#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

eval 'use Test::Fixme'; ## no critic
plan(skip_all => 'Test::Fixme required') if $@;

run_tests(match => qr/FIXME/, where => [qw(lib)]);
