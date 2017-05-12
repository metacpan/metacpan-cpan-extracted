use strict;
use warnings;
use Test::More;

use Role::Tiny ();

my $last_role;
push @Role::Tiny::ON_ROLE_CREATE, sub {
  ($last_role) = @_;
};

eval q{
  package MyRole;
  use Role::Tiny;
};

is $last_role, 'MyRole', 'role create hook was run';

eval q{
  package MyRole2;
  use Role::Tiny;
};

is $last_role, 'MyRole2', 'role create hook was run again';

done_testing;
