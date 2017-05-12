# -*-cperl-*-

use strict;
use Test::More;
use Test::Number::Delta;
use File::Spec;

use PDL::Bad;

BEGIN {

  # No point if we are missing NDF and PDL
  my $ok = eval "use NDF; 1;";
  if (!$ok) {
    plan skip_all => "NDF module is not installed";
    exit;
  }

  $ok = eval "use PDL::LiteF; 1;";
  if (!$ok) {
    plan skip_all => "PDL is not installed";
    exit;
  }

  plan tests => 19;
}

BEGIN {
  use_ok( "PDL::IO::NDF" );
}

my $testfile = File::Spec->catfile( "t", "data", "s4a20120702_00052_0002_noi.sdf" );

my $pdl = rndf( $testfile );

ok( defined $pdl, "Read a PDL");
is( $pdl->ndims, 2, "Number of dimensions");
is( $pdl->type, double, "Check data type" );

# Check the header
my $hdr = $pdl->gethdr();
is( $hdr->{INSTRUME}, "SCUBA-2", "Check instrument header" );
is( $hdr->{Title}, "s4a Bolometer Noise", "Check NDF title" );

my %extensions = %{ $hdr->{NDF_EXT} };
is( scalar(keys %extensions), 2, "Count number of extensions" );

if ($PDL::Bad::Status) {
  # count the number of bad values
  my $isgood = $pdl->isgood();
  is( $isgood->sum, 1011, "Check number of expected good data values");

  my @stats = $pdl->stats();

  # Results from KAPPA STATS for comparison
  delta_ok( $stats[0], 348.824395337609, "Compare mean" );
  delta_ok( $stats[6], 325.374457524842, "Compare standard deviation" );
  delta_ok( $stats[3], 50.3813963567958, "Compare min" );
  delta_ok( $stats[4], 4342.69610949016, "Compare max" );

} else {

 SKIP: {
    skip "Bad values not supported in this PDL", 5;
  };
}


# Make sure we can write it
my $output = "testme.sdf";
END {
  unlink $output if -e $output;
}
$pdl->wndf($output);

ok( -e $output, "Written output file");

# Test the minimalist read
$pdl = rndf( $testfile, QuickRead => 1 );

ok( defined $pdl, "Read the new PDL");
is( $pdl->ndims, 2, "Number of dimensions");
is( $pdl->type, double, "Check data type" );

$hdr = $pdl->gethdr();
is( $hdr->{INSTRUME}, "SCUBA-2", "Check instrument header" );
is( $hdr->{Title}, "s4a Bolometer Noise", "Check NDF title" );
ok( !exists $hdr->{NDF_EXT}, "No extensions" );
