use strict;
use warnings;

use Test::More tests => 1;
use File::Temp;
use File::Slurp qw( slurp );
use Pod::ROBODoc;

#-------------------------------------------------------------------------------
# Setup variables
#-------------------------------------------------------------------------------
my $pr = Pod::ROBODoc->new();

my $infile  = File::Temp->new();
my $outfile = File::Temp->new();

print $infile slurp( 't/robodoc/example-full' );
seek $infile, 0, 0;
        
local *STDIN  = *$infile;
local *STDOUT = *$outfile;

#-------------------------------------------------------------------------------
# Test filter() with default options (STDIN, STDOUT)
#-------------------------------------------------------------------------------
eval {
    $pr->filter( 
        input  => undef,
        output => undef
    );
};
is( $@, q{}, 'filter with no options succeeds' );
