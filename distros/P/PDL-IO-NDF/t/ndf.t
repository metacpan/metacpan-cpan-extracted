# -*-perl-*-
# Test of the NDF I/O system
# Requires that the NDF module is available.

use strict;

use Test::More;

use PDL::LiteF;
$PDL::verbose = 1;

# Check that we can load the module
BEGIN {
  # Make sure we have NDF
  my $loaded = eval "use NDF; 1";
  if ($loaded) {
    plan tests => 11;
  } else {
    plan skip_all => "NDF module not available.";
  }
  use_ok( "PDL::IO::NDF" );
}

kill 'INT',$$  if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

sub tapprox ($$) {
    my ( $a, $b ) = @_;
    return abs($a-$b) <= 1.0e-5;
}

# Now start by creating a test PDL
my $pdl = pdl( 1,5,10,8);

# Now add a header
$pdl->sethdr(  { NDFTEST => 'yes' } );

# output file name
my $ndffile = "test.sdf";
unlink $ndffile if -e $ndffile;

# Write it out to disk
$pdl->wndf( $ndffile );
ok( -e $ndffile );

# Set up an END block to remove the file
END {
  unlink $ndffile if defined $ndffile and -e $ndffile;
}

# Now read it back in
my $in = rndf( $ndffile );

# Compare the number of entries
is( $in->dims,  $pdl->dims, "Compare dimensionality");

# Check each entry
my $range = $pdl->getdim(0) - 1;
foreach ( 0 .. $range ) {
  is( $in->at($_), $pdl->at($_), "element by element comparison")
}

# Now compare headers
is( $in->gethdr->{NDFTEST}, $pdl->gethdr->{NDFTEST}, "Compare NDFTEST header" );

# try a 2D image
$pdl = pdl( [1,5,10],[8,4,-4]);
$pdl->wndf( $ndffile );
$in = rndf( $ndffile );

# Compare the number of entries
is( $in->dims, $pdl->dims, "Compare dims" );
ok( tapprox( sum($in - $pdl), 0.0 ), "Check diff" );

# try a subset of the 2D image
# NOTE: NDF starts counting at 1, not 0
$in = rndf( "test(1:2,2)" );
ok( tapprox( sum($in - $pdl->slice('0:1,1') ), 0.0 ), "diff slice" );

# end of test
