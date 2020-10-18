use strict;

use Test::More;

my $package;

my @functions = qw|autoconnect connect|;

BEGIN {
  $package = 'Nuvol';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Functions';
can_ok $package, $_ for @functions;

done_testing();
