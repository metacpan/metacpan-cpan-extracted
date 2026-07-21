use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw(
    :return
    TB_CAP__COUNT
  );
}

sub valid_preinit_status {
  my ($rv) = @_;
  return 1
    if $rv == TB_ERR_NOT_INIT()
    || $rv == TB_ERR_OUT_OF_BOUNDS()
    || $rv == TB_ERR()
    || $rv == TB_OK();
  return 0;
}

subtest 'pre-init status checks' => sub {
  plan tests => 7;

  Termbox::send_literal(my $rv, "foo");
  ok(valid_preinit_status($rv), 'send_literal pre-init returns expected');

  Termbox::send_num($rv, \my $buf, 42);
  ok(valid_preinit_status($rv), 'send_num pre-init returns expected');

  $rv = eval { Termbox::send_init_escape_codes() } // TB_ERR;
  ok(
    valid_preinit_status($rv), 
    'send_init_escape_codes pre-init returns expected'
  );

  $rv = eval { Termbox::send_attr(0, 0) } // TB_ERR;
  ok(valid_preinit_status($rv), 'send_attr pre-init returns expected');

  $rv = eval { Termbox::send_cursor_if(0, 0) } // TB_ERR;
  ok(valid_preinit_status($rv), 'send_cursor_if pre-init returns expected');

  $rv = eval { Termbox::send_clear() } // TB_ERR;
  ok(valid_preinit_status($rv), 'send_clear pre-init returns expected');

  $rv = eval { Termbox::send_sgr(1, 2, 0, 0) } // TB_ERR;
  ok(valid_preinit_status($rv), 'send_sgr pre-init returns expected');
};

subtest 'send_* APIs after init' => sub {
  local $Termbox::global->{initialized} = 1;
  $Termbox::global->{width} = 80;
  $Termbox::global->{height} = 24;
  $Termbox::global->{outbuf} = '';
  $Termbox::global->{caps} = [ ("A") x TB_CAP__COUNT() ];
  $Termbox::global->{wfd} = -1;
  $Termbox::global->{last_fg} = 1;
  $Termbox::global->{last_bg} = 2;
  $Termbox::global->{output_mode} = 0;

  plan tests => 8;

  Termbox::send_literal(my $rv, "foo");
  is($rv, TB_OK(), 'send_literal after init returns TB_OK');
  like($Termbox::global->{outbuf}, qr/foo/, 'send_literal appends to outbuf');

  $Termbox::global->{outbuf} = '';
  Termbox::send_num($rv, \my $buf, 123);
  is($rv, TB_OK(), 'send_num after init returns TB_OK');
  like($Termbox::global->{outbuf}, qr/123/, 'send_num appends number to outbuf');

  $Termbox::global->{outbuf} = '';
  $rv = Termbox::send_init_escape_codes();
  is($rv, TB_OK(), 'send_init_escape_codes after init returns TB_OK');

  $Termbox::global->{outbuf} = '';
  $rv = Termbox::send_attr(1, 2);
  is($rv, TB_OK(), 'send_attr after init returns TB_OK');

  $rv = eval { Termbox::send_sgr(1, 2, 0, 0) } // TB_OK;
  is($rv, TB_OK(), 'send_sgr after init returns TB_OK');

  $rv = eval { Termbox::send_cursor_if(1, 2) } // TB_OK;
  is($rv, TB_OK(), 'send_cursor_if after init returns TB_OK');
};

done_testing();
