use strict;
use warnings;

use Test::More;

{
  package Some::Carrier;
  use Moose;

  with 'Role::HasPayload::Auto';

  has size => (
    is   => 'ro',
    isa  => 'Int',
    lazy => 1,
    traits  => [ 'Role::HasPayload::Meta::Attribute::Payload' ],
    default => 36,
  );

  has private_thing => (
    is      => 'ro',
    isa     => 'Int',
    default => 13,
  );
}

{
  my $obj = Some::Carrier->new;

  isa_ok($obj, 'Some::Carrier', 'we got our object');

  is_deeply(
    $obj->payload,
    {
      size => 36,
    },
    "...and the payload is correct",
  );
}

done_testing;
