use strict;
use warnings;
use Test::More tests => 2;

use STD;

# Create a temporary folder to store STD' artifacts
require File::Temp;
my $tmp = File::Temp->newdir();

#check that we have get back a parser when we have an empty string
my $r = STD->parse( '', tmp_prefix => $tmp );
ok( defined $r, 'STD->parse() returned something on a empty string' );
isa_ok( $r, 'STD', 'STD->parse() return type' );
