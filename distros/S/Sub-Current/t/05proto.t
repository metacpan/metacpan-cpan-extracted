#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Sub::Current;

# prototype must be ''
ok( defined prototype \&ROUTINE, 'proto defined' );
is( prototype \&ROUTINE, '', 'proto empty' );

# and this should compile
sub skaro { ROUTINE }
is(skaro(), \&skaro, 'skaro');
