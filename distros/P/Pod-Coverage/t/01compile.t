#!/usr/bin/perl -w
use Test::More tests => 4;

use_ok('Pod::Coverage');
use_ok('Pod::Coverage::ExportOnly');
use_ok('Pod::Coverage::Overloader');
use_ok('Pod::Coverage::CountParents');

