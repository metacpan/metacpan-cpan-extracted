
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok("Package::Generator"); }

# XXX: We probably can't be 100% sure this won't exist, but... come on, what
# are the chances?
my $bogus = "RJBS::PKG::GEN::OMG::WTF::8675309::Jennys::Number";

ok(
  ! Package::Generator->package_exists($bogus),
  "the bogus package didn't exist",
);

ok(
  Package::Generator->package_exists('Package::Generator'),
  "but Package::Generator does",
);
