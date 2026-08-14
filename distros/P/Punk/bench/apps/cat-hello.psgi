#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw(dirname);
use lib dirname(__FILE__) . "/cat-lib";

# The same 'hello' through Catalyst, hosted on the same server through
# its own psgi_app. Debug off - what you would deploy.
BEGIN { $ENV{CATALYST_DEBUG} = 0 }
require BenchCat;

BenchCat->psgi_app;
