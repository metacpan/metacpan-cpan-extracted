#!perl

use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN { use_ok('Music::Scala') || print "Bail out!\n" }

diag("Testing Music::Scala $Music::Scala::VERSION, Perl $], $^X");
