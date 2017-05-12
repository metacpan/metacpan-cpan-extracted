
use strict;
use warnings;

use Test::Needs qw( Moo );
use Test::More tests => 4;

require Moo;
my $package_no = 1;

sub failcode {
  my ( $reason, $code ) = @_;
  local $@;
  my $failed = 1;
  $code = "package Sample${package_no};\n" . $code;
  $package_no++;
  $code .= ";\n undef \$failed;";
  eval $code;
  ok( $failed, $reason ) or diag "expected fail from code: $code";
  return $@;
}

failcode "Too many args" => q[
  use Moo;
  use MooX::Lsub;
  lsub hello => sub { }, q[world];
];

failcode "Not a code ref" => q[
  use Moo;
  use MooX::Lsub;
  lsub hello => q[world];
];

failcode "Not enough args" => q[
  use Moo;
  use MooX::Lsub;
  lsub hello =>;
];

failcode "No args" => q[
  use Moo;
  use MooX::Lsub;
  lsub;
];
