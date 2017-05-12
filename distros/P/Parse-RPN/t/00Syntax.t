#!/usr/bin/perl -w    

# $Id: $

use strict;
use 5.006;
use warnings;

use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::RPN;
my $version = $Parse::RPN::VERSION;

ok( $version =~ /\d\.\d+$/ , "Loaded and return a version ($version)");

