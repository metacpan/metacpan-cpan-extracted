#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Ogre', qw(:SceneType)) }

#eval { SHADOWTYPE_STENCIL_ADDITIVE };
#ok(! $@, 'constants not exported by default');

ok(ST_EXTERIOR_CLOSE != 0, 'constant imported by export tags');


# need to test all of them...
