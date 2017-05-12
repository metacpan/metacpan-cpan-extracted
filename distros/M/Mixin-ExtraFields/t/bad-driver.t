
use strict;
use warnings;

use Test::More;

{
  package Bad::Driver;
  use base qw(Mixin::ExtraFields::Driver);

  # Look at us!  We're so BAD!  We're not going to defined ANY of the required
  # methods!
}

my $driver = bless {} => 'Bad::Driver';

my @methods = qw(from_args get_all_detailed_extra set_extra delete_extra);

plan tests => scalar @methods;

for (@methods) {
  eval { $driver->$_ };
  like(
    $@,
    qr/not implemented/,
    "$_ call without implementation throws correct error",
  );
}
