#!/usr/bin/perl

use strict;
BEGIN { $^W = 1 }

use Test::More;

plan tests => 1;

# Goal of these tests: confirm that Sub::Uplevel will work with Exporter's
# import() function

package main;
use lib 't/lib';
require MyImporter;
require Bar;
MyImporter::import_for_me('Bar','func3');
can_ok('main','func3');

