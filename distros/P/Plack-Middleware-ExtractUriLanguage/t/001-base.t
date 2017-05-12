#
# This file is part of Plack-Middleware-ExtractUriLanguage
#
# This software is Copyright (c) 2013 by BURNERSK.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More tests => 1 + 1;
use Test::NoWarnings;

############################################################################

BEGIN {
  use_ok( 'Plack::Middleware::ExtractUriLanguage' );
}

############################################################################
1;
