# Pod::WikiDoc - check module loading and create testing directory

use Test::More tests =>  3 ;

BEGIN { use_ok( 'Pod::WikiDoc' ); }

#--------------------------------------------------------------------------#
# Setup variables
#--------------------------------------------------------------------------#

my $parser = Pod::WikiDoc->new ();
isa_ok ($parser, 'Pod::WikiDoc');

my $err;

#--------------------------------------------------------------------------#
# Test convert argument failures
#--------------------------------------------------------------------------#

eval { $parser->convert( {} ) };
$err = $@;

like( $err, qr{\AError: Argument to convert\(\) must be a scalar}, 
    "Catch convert() failure on bad argument"
);

