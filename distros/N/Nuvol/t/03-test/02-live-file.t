use strict;

use Test::More;

my $package;

my @functions = qw|build_test_file test_basics test_copy test_crud|;

BEGIN {
  $package = 'Nuvol::Test::FileLive';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Functions';
can_ok $package, $_ for @functions;

done_testing();
