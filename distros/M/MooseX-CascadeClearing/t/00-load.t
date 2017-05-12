#!/usr/bin/env perl
#
# This file is part of MooseX-CascadeClearing
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

# keep MooseX:: from complaining about non-exported sugar
package foo;

use Test::More tests => 1;

BEGIN { use_ok 'MooseX::CascadeClearing' }

diag( "Testing MooseX::CascadeClearing $MooseX::CascadeClearing::VERSION, Perl $], $^X" );
