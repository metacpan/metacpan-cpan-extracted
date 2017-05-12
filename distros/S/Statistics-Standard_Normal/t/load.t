#!/usr/bin/env perl

use Test::More tests => 4;

require_ok('Statistics::Standard_Normal');

Statistics::Standard_Normal->import(qw/ z_to_pct pct_to_z /);

ok( defined &z_to_pct, 'import z_to_pct' );
ok( defined &pct_to_z, 'import pct_to_z' );
ok( !eval { Statistics::Standard_Normal->import('not_exported') },
    "don't import junk" );

