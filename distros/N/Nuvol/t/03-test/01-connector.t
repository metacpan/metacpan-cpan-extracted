use strict;

use Test::More;

my $package;

my @functions
  = qw|build_test_connector test_authenticate test_basics test_config test_constants test_defaults test_disconnect|;

BEGIN {
  $package = 'Nuvol::Test::Connector';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Functions';
can_ok $package, $_ for @functions;

done_testing();
