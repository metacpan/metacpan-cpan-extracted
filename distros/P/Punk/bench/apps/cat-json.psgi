#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(dirname);
use lib dirname(__FILE__) . "/cat-lib";
# BENCH-PATH: /json

# The Catalyst counterpart of punk-json: JSON::MaybeXS in the action.
BEGIN { $ENV{CATALYST_DEBUG} = 0 }
require BenchCat;

BenchCat->psgi_app;
