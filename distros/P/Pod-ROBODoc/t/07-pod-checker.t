use strict;
use warnings;

use Test::More tests => 1;
use Test::Pod;
use File::Temp;
use Pod::ROBODoc;

#-------------------------------------------------------------------------------
# Setup variables
#-------------------------------------------------------------------------------
my $infile  = 't/robodoc/example-full';
my $outfile = File::Temp->new();

my $pr = Pod::ROBODoc->new();

#-------------------------------------------------------------------------------
# Test filter() for valid pod output
#-------------------------------------------------------------------------------
$pr->filter( 
    input  => $infile,
    output => $outfile->filename()
);

pod_file_ok( $outfile->filename(), 'filter produces valid pod' );