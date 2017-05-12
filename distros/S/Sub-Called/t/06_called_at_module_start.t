#!/usr/bin/perl

use strict;
use warnings;

use Sub::Called;
use Test::More;

use FindBin;
use lib $FindBin::Bin . '/lib';

plan skip_all => 'These are tests for the limitations.';
plan tests    => 2;

require CheckSubCalled;
