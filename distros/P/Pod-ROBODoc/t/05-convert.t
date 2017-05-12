use strict;
use warnings;

use Test::More tests => 4;
use File::Slurp qw( slurp );
use Pod::ROBODoc;

#-------------------------------------------------------------------------------
# Setup variables
#-------------------------------------------------------------------------------
my $input = slurp( 't/robodoc/example-full' );

my $pr = Pod::ROBODoc->new();

#-------------------------------------------------------------------------------
# Test convert()
#-------------------------------------------------------------------------------
my $output = eval { $pr->convert( $input ) };
is( $@, q{}, 'convert with full example succeeds' );
ok( length $output > 1, 'convert with full example generates non-empty output' ); 

#-------------------------------------------------------------------------------
# Test convert() with empty input
#-------------------------------------------------------------------------------
$output = eval { $pr->convert( q{} ) };
is( $@, q{}, 'convert with empty string succeeds' );
is( $output, q{}, 'convert with empty string generates empty output' );