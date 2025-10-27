#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 1;

use_ok('SIRTX::VM::Chunk');

exit 0;
