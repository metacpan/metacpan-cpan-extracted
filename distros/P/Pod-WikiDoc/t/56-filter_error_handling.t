# Pod::WikiDoc - check module loading and create testing directory

use Test::More tests =>  7 ;
use IO::String;

# mock open failure in Pod::WikiDoc
BEGIN { *Pod::WikiDoc::open = sub { 0; } }

BEGIN { use_ok( 'Pod::WikiDoc' ); }

#--------------------------------------------------------------------------#
# Setup variables
#--------------------------------------------------------------------------#

my $parser = Pod::WikiDoc->new ();
isa_ok ($parser, 'Pod::WikiDoc');

my $fake_fh = IO::String->new();
my $err;

#--------------------------------------------------------------------------#
# Test filter parameter failures
#--------------------------------------------------------------------------#

eval { $parser->filter(  input => "missing.file", output => $fake_fh  ) };
$err = $@;

like( $err, qr{\AError: Argument to filter\(\) must be a hash reference}, 
    "Catch filter() failure on bad argument"
);

#--------------------------------------------------------------------------#
# Test file opening failures
#--------------------------------------------------------------------------#

eval { $parser->filter( { input => "missing.file", output => $fake_fh } ) };
$err = $@;

like( $err, qr{\AError: Couldn't open input file 'missing.file'}, 
    "Catch filter() failure on bad input parameter"
);

eval { $parser->filter( { input => $fake_fh, output => "cantopen.file" } ) };
$err = $@;

like( $err, qr{\AError: Couldn't open output file 'cantopen.file'}, 
    "Catch filter() failure on bad output parameter"
);

#--------------------------------------------------------------------------#
# Test bad type of input/output arguments
#--------------------------------------------------------------------------#

eval { $parser->filter( { input => [], output => $fake_fh } ) };
$err = $@;

like( $err, qr{Error: 'input' parameter for filter\(\) must be a filename or filehandle},
    "Catch filter() failure on bad variable type for input parameter"
);

eval { $parser->filter( { input => $fake_fh, output => [] } ) };
$err = $@;

like( $err, qr{Error: 'output' parameter for filter\(\) must be a filename or filehandle},
    "Catch filter() failure on bad variable type for output parameter"
);

