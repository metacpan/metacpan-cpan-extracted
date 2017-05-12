#!perl

use strict;
use Test::More tests => 3;

# Simple test to make sure that we get an error
# properly.

require_ok( "Starlink::AST" );

# Create a skyframe and then ask for the rest frequency
my $sky = Starlink::AST::SkyFrame->new( "" );
my $restfreq = eval { $sky->Get( "RestFreq" ) };

like( $@, qr/restfreq/, "Does error string look ok");

is( $restfreq, undef, "Should not have rest frequency" );
