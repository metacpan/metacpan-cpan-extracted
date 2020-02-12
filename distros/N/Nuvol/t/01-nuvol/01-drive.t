use strict;

use Test::More;

my $package;

my @methods = qw|connector item|;

BEGIN {
  $package = 'Nuvol::Drive';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Methods';
can_ok $package, $_ for @methods;

note 'Illegal values';
eval {$package->new({},{})};
like $@, qr/Parameter metadata, id or path required!/, 'Required parameters';

done_testing();
