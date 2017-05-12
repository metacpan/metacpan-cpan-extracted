use strict;
use warnings;

use Test::More;

{
  package Some::Message;
  use Moose;

  has payload => (is => 'ro', isa => 'HashRef', required => 1);

  with 'Role::HasMessage::Errf';
}

{
  my $obj = Some::Message->new({
    payload => { size => 36 },
    message => "can't fit into pants under %{size;inch}n",
  });

  isa_ok($obj, 'Some::Message', 'the message-having object');

  for my $role (qw(Role::HasMessage Role::HasMessage::Errf)) {
    ok($obj->does($role), "...it does $role");
  }

  is_deeply(
    $obj->payload,
    { size => 36 },
    "...and the payload is correct",
  );

  is(
    $obj->message,
    "can't fit into pants under 36 inches",
    "...and msg formats",
  );
}

done_testing;
