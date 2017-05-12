#!/usr/bin/perl

# $Id: 01_require.t,v 1.4 2002/10/11 20:37:14 andreychek Exp $

use strict;
use Test::More  tests => 1;

eval { use OpenPlugin(); };

require_ok( 'OpenPlugin' );

