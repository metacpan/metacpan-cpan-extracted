#!/usr/bin/perl

# $Id: 01_require.t,v 1.2 2002/08/26 18:50:33 andreychek Exp $

use strict;
use Test::More  tests => 1;

use lib ".";
use lib "./t";

require_ok( 'OpenThought::XML2Hash' );
