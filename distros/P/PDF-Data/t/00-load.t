#!/usr/bin/env perl

use v5.16;
use warnings;

use Cwd qw[abs_path];

use lib abs_path(__FILE__) =~ s{(?:/[^/]+){2}$}{/lib}r;

use Test2::V0;

plan(1);

use ok 'PDF::Data';
