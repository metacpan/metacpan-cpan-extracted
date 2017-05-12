use strict;
use warnings;

use Test::More tests => 2;
use File::Temp;
use Pod::ROBODoc;

#-------------------------------------------------------------------------------
# Setup variables
#-------------------------------------------------------------------------------
my $infile  = 't/robodoc/example-full';
my $outfile = File::Temp->new();

my $pr = Pod::ROBODoc->new();

#-------------------------------------------------------------------------------
# Test filter() with filename arguments
#-------------------------------------------------------------------------------
eval {
    $pr->filter( 
        input  => $infile,
        output => $outfile->filename()
    );
};

is( $@, q{}, 'filter with filenames succeeds' );
ok( -s $outfile, 'filter with filenames writes outfile' );
