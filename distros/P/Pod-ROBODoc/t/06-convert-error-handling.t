use strict;
use warnings;

use Test::More tests => 1;
use File::Temp;
use Pod::ROBODoc;

#-------------------------------------------------------------------------------
# Setup variables
#-------------------------------------------------------------------------------
my $pr = Pod::ROBODoc->new();
my $err;

#-------------------------------------------------------------------------------
# Test invalid params
#-------------------------------------------------------------------------------
eval { $pr->convert( {} ) };
$err = $@;

like( $err, qr{\AParameter #1 \(".+"\) to Pod::ROBODoc::convert was a 'hashref', which is not one of the allowed types},
    'convert fails on bad input argument'
);
