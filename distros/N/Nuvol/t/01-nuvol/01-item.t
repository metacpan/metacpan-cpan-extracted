use strict;

use Test::More;

my $package;

my @methods = qw|drive exists is_file is_folder realpath type|;
my @internal_methods = qw|_load|;

BEGIN {
  $package = 'Nuvol::Item';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Methods';
can_ok $package, $_ for @methods, @internal_methods;

note 'Illegal values';
eval {$package->new({},{})};
like $@, qr/Parameter metadata, id or path required!/, 'Required parameters';

done_testing();
