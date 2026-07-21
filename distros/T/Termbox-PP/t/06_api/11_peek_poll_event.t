use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api :event :return );
}

# Mock out internal functions to isolate the code paths under test.
no warnings 'redefine';
my @calls;
local *Termbox::wait_event = sub {
  my ($event, $timeout) = @_;
  push @calls, [ $event, $timeout ];
  return TB_OK;
};

# -----------------------------
note 'Wait for an event tests';
# -----------------------------

subtest 'tb_peek_event delegates to wait_event' => sub {
  plan tests => 3;

  local $Termbox::global->{initialized} = 1;
  @calls = ();

  my $ev = Termbox::Event->new();

  is(
    tb_peek_event($ev, 123),
    TB_OK,
    'tb_peek_event returns TB_OK'
  );

  is(scalar(@calls), 1, 'wait_event called once');
  is(
    $calls[0][1],
    123,
    'timeout forwarded unchanged'
  );
};

subtest 'tb_poll_event delegates to wait_event with -1' => sub {
  plan tests => 3;

  local $Termbox::global->{initialized} = 1;
  @calls = ();

  my $ev = Termbox::Event->new();

  is(
    tb_poll_event($ev),
    TB_OK,
    'tb_poll_event returns TB_OK'
  );

  is(scalar(@calls), 1, 'wait_event called once');
  is(
    $calls[0][1],
    -1,
    'poll uses blocking timeout (-1)'
  );
};

subtest 'not initialized' => sub {
  plan tests => 2;

  local $Termbox::global->{initialized} = 0;
  my $ev = Termbox::Event->new();

  is(
    tb_peek_event($ev, 0),
    TB_ERR_NOT_INIT,
    'tb_peek_event fails when not initialized'
  );

  is(
    tb_poll_event($ev),
    TB_ERR_NOT_INIT,
    'tb_poll_event fails when not initialized'
  );
};

done_testing;
