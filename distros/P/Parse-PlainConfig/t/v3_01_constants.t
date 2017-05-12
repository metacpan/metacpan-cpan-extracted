#!/usr/bin/perl -T

use Test::More tests => 3;
use Paranoid;
use Parse::PlainConfig::Constants;
use Class::EHierarchy qw(:all);

use strict;
use warnings;

psecureEnv();

is( PPC_SCALAR, CEH_SCALAR, 'PPC_SCALAR' );
is( PPC_ARRAY,  CEH_ARRAY,  'PPC_ARRAY' );
is( PPC_HASH,   CEH_HASH,   'PPC_HASH' );

