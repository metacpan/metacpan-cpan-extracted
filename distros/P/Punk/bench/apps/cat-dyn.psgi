#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(dirname);
use lib dirname(__FILE__) . "/cat-lib";
# BENCH-PATH: /books/42

# The Catalyst counterpart of punk-dyn: one Args(1) capture.
BEGIN { $ENV{CATALYST_DEBUG} = 0 }
require BenchCat;

BenchCat->psgi_app;
