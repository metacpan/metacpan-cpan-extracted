use strict;

use Test::More;

my $package;

my @functions = qw|copy_from copy_to download_url remove slurp spurt|;

BEGIN {
  $package = 'Nuvol::Role::File';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Functions';
can_ok $package, $_ for @functions;

done_testing();
