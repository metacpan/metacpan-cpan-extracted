#!/usr/bin/perl

# $Id: 01_require.t,v 1.3 2002/07/07 17:49:55 andreychek Exp $

use strict;
use Test::More  tests => 1;

use lib ".";
use lib "./t";

# Since OpenThoughtTests also loads OpenThought, use eval to catch any errors.
# In this particular file, we want the test to show the failure, as opposed to
# the script not compiling.
eval { require "OpenThoughtTests.pm"; };

require_ok( 'OpenThought' );

