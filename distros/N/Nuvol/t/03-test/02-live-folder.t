use strict;

use Test::More;

my $package;

my @functions = qw|build_test_folder test_basics test_cd|;

BEGIN {
  $package = 'Nuvol::Test::FolderLive';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Functions';
can_ok $package, $_ for @functions;

done_testing();
