#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';

use DummyT;
# testing the case where Test::DataDriven::import is not called
use Test::More tests => 1;

Test::DataDriven->run;

__DATA__

=== Dummy test
--- directory chomp
t/dummy
--- created lines chomp
