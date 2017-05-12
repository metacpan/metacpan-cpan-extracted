use strict;
use warnings;

use Test::More tests => 4;
use File::Temp;
use Pod::ROBODoc;

#-------------------------------------------------------------------------------
# Setup variables
#-------------------------------------------------------------------------------
my $pr = Pod::ROBODoc->new();
my $err;

my $infile  = File::Temp->new();
my $outfile = File::Temp->new();

#-------------------------------------------------------------------------------
# Test invalid params
#-------------------------------------------------------------------------------
eval { $pr->filter( input => {} ) };
$err = $@;

like( $err, qr{\AThe 'input' parameter \(".+"\) to Pod::ROBODoc::filter was a 'hashref', which is not one of the allowed types},
    'filter fails on bad input argument'
);

eval { $pr->filter( input => $infile->filename(), output => {} ) };
$err = $@;

like( $err, qr{\AThe 'output' parameter \(".+"\) to Pod::ROBODoc::filter was a 'hashref', which is not one of the allowed types},
    'filter fails on bad output argument'
);

#-------------------------------------------------------------------------------
# Test invalid input param to filter()
#-------------------------------------------------------------------------------
eval { $pr->filter( input => 'nosuch.file', output => $outfile->filename() ) };
$err = $@;

like( $err, qr{\ACan't open input file},
    'filter fails on non-writeable input file'
);

#-------------------------------------------------------------------------------
# Test invalid output param to filter() 
#-------------------------------------------------------------------------------
chmod 0000, $outfile->filename();

eval { $pr->filter( input => $infile->filename(), output => $outfile->filename() ) };
$err = $@;

like( $err, qr{\ACan't open output file},
    'filter fails on non-writeable output file'
);
