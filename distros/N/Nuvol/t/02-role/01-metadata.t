use strict;

use Test::More;

my $package;

my @functions = qw|description id name metadata _load _parse_parameters _set_metadata|;

BEGIN {
  $package = 'Nuvol::Role::Metadata';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Functions';
can_ok $package, $_ for @functions;

done_testing();
