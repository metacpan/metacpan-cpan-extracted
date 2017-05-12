#!/usr/bin/perl -w

# Load testing for Pod::Classdoc and Pod::Classdoc::Project

use strict;

use Test::More tests => 3;

# Check their perl version
ok( $] >= 5.008, "Your perl is new enough" );

# Load the modules
use_ok( 'Pod::Classdoc');

use_ok( 'Pod::Classdoc::Project');

exit();
