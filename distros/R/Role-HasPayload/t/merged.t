use strict;
use warnings;

use Test::More;

{
  package Some::Carrier;
  use Moose;

  with 'Role::HasPayload::Merged';

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
  my $obj = Some::Carrier->new({
    payload => { blort => 10 },
  });

  isa_ok($obj, 'Some::Carrier', 'we got our object');

  is_deeply(
    $obj->payload,
    {
      blort => 10,
      size  => 36,
    },
    "...and the payload is correct",
  );
}

{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $obj = Some::Carrier->new({
    payload => { blort => 10, size => 20 },
  });

  isa_ok($obj, 'Some::Carrier', 'we got our object');

  is_deeply(
    $obj->payload,
    {
      blort => 10,
      size  => 36,
    },
    "...and the payload is correct",
  );

  is(@warnings, 1, "we got a warning when trying to override auto payload");
  like(
    $warnings[0],
    qr{declining to override automatic payload entry size at t.merged\.t},
    "...and it's the right warning",
  );
}

done_testing;
