
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Spec::Functions;
use lib $RealBin;
use Proch::Seqfu;
use TestFu;

my $ver = $Proch::Seqfu::VERSION;

ok(defined $ver, "\$Proch::Seqfu::VERSION is defined: $ver");
done_testing();
