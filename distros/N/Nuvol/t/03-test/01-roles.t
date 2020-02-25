use strict;

use Test::More;

my $package;

my @functions = (
  qw|test_file_applied test_file_prerequisites|,
  qw|test_folder_applied test_folder_prerequisites|,
  qw|test_metadata_applied test_metadata_methods test_metadata_prerequisites|,
);

BEGIN {
  $package = 'Nuvol::Test::Roles';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Functions';
can_ok $package, $_ for @functions;

done_testing();
