#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

BEGIN { use_ok( 'SVG::Metadata' ); }
my $object = SVG::Metadata->new ();
isa_ok ($object, 'SVG::Metadata');




