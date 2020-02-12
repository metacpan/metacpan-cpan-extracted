use strict;

use Test::More;

my $package;

my @functions = qw|make_path remove_tree|;

BEGIN {
  $package = 'Nuvol::Role::Folder';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

note 'Functions';
can_ok $package, $_ for @functions;

done_testing();
