use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return :keys :event );
}

subtest 'extract_esc_cap matches trie leaf and consumes bytes' => sub {
  plan tests => 7;

  local $Termbox::global->{cap_trie} = captrie->new();
  local $Termbox::global->{inbuf} = "\e[Arest";

  is(
    $Termbox::global->{cap_trie}->add("\e[A", TB_KEY_ARROW_UP(), 0),
    TB_OK(),
    'added arrow-up cap'
  );

  my $event = Termbox::Event->new();
  is(Termbox::extract_esc_cap($event), TB_OK(), 'cap parser returns TB_OK');
  is($event->{type}, TB_EVENT_KEY(), 'event type is key');
  is($event->{key}, TB_KEY_ARROW_UP(), 'event key is arrow up');
  is($event->{mod}, 0, 'event mod is zero');
  is($event->{ch}, 0, 'event ch is zero');
  is($Termbox::global->{inbuf}, 'rest', 'cap bytes consumed from buffer');
};

subtest 'extract_esc_cap returns NEED_MORE on branch-only prefix' => sub {
  plan tests => 4;

  local $Termbox::global->{cap_trie} = captrie->new();
  local $Termbox::global->{inbuf} = "\e[A";

  is(
    $Termbox::global->{cap_trie}->add("\e[ABC", TB_KEY_F1(), 0),
    TB_OK(),
    'added longer cap'
  );

  my $event = Termbox::Event->new();
  is(
    Termbox::extract_esc_cap($event),
    TB_ERR_NEED_MORE(),
    'branch prefix returns NEED_MORE'
  );
  is($Termbox::global->{inbuf}, "\e[A", 'buffer unchanged on NEED_MORE');
  ok(!$event->{type}, 'event remains untouched');
};

subtest 'extract_esc_mouse parses VT200 left click' => sub {
  plan tests => 6;

  # ESC [ M Cb Cx Cy where Cb=' ' (left), Cx='!' (x=0), Cy='!' (y=0)
  local $Termbox::global->{inbuf} = "\e[M !!tail";

  my $event = Termbox::Event->new();
  is(Termbox::extract_esc_mouse($event), TB_OK(), 'mouse parser returns TB_OK');
  is($event->{type}, TB_EVENT_MOUSE(), 'event type is mouse');
  is($event->{key}, TB_KEY_MOUSE_LEFT(), 'mouse left key detected');
  is($event->{x}, 0, 'x coordinate parsed');
  is($event->{y}, 0, 'y coordinate parsed');
  is($Termbox::global->{inbuf}, 'tail', 'mouse bytes consumed');
};

subtest 'extract_esc_mouse parses SGR (1006) motion/release' => sub {
  plan tests => 7;

  # ESC [ < Cb ; Cx ; Cy M
  local $Termbox::global->{inbuf} = "\e[<35;110;11Mtail";

  my $event = Termbox::Event->new();
  is(Termbox::extract_esc_mouse($event), TB_OK(), '1006 parser returns TB_OK');
  is($event->{type}, TB_EVENT_MOUSE(), 'event type is mouse');
  is($event->{key}, TB_KEY_MOUSE_RELEASE(), 'mouse release detected');
  is($event->{mod}, TB_MOD_MOTION(), 'motion bit detected');
  is($event->{x}, 109, 'x coordinate parsed');
  is($event->{y}, 10, 'y coordinate parsed');
  is($Termbox::global->{inbuf}, 'tail', '1006 bytes consumed');
};

subtest 'extract_esc_mouse parses URXVT (1015) wheel event' => sub {
  plan tests => 6;

  # ESC [ Cb ; Cx ; Cy M
  local $Termbox::global->{inbuf} = "\e[97;14;10Mtail";

  my $event = Termbox::Event->new();
  is(Termbox::extract_esc_mouse($event), TB_OK(), '1015 parser returns TB_OK');
  is($event->{type}, TB_EVENT_MOUSE(), 'event type is mouse');
  is($event->{key}, TB_KEY_MOUSE_WHEEL_DOWN(), 'wheel-down detected');
  is($event->{x}, 13, 'x coordinate parsed');
  is($event->{y}, 9, 'y coordinate parsed');
  is($Termbox::global->{inbuf}, 'tail', '1015 bytes consumed');
};

subtest 'extract_esc parses arrow-left cap (\eOD)' => sub {
  plan tests => 5;

  local $Termbox::global->{cap_trie} = captrie->new();
  local $Termbox::global->{inbuf} = "\eODtail";
  local $Termbox::global->{fn_extract_esc_pre} = undef;
  local $Termbox::global->{fn_extract_esc_post} = undef;

  is(
    $Termbox::global->{cap_trie}->add("\eOD", TB_KEY_ARROW_LEFT(), 0),
    TB_OK(),
    'added arrow-left cap'
  );

  my $event = Termbox::Event->new();
  is(Termbox::extract_esc($event), TB_OK(), 'extract_esc returns TB_OK');
  is($event->{type}, TB_EVENT_KEY(), 'event type is key');
  is($event->{key}, TB_KEY_ARROW_LEFT(), 'event key is arrow left');
  is($Termbox::global->{inbuf}, 'tail', 'cap bytes consumed');
};

subtest 'extract_esc_user pre-hook precedence and consumption' => sub {
  plan tests => 5;

  local $Termbox::global->{inbuf} = "\eXremain";
  local $Termbox::global->{fn_extract_esc_pre} = sub {
    my ($event, $consumed) = @_;
    $$consumed = 2;
    $event->{type} = TB_EVENT_KEY();
    $event->{key} = TB_KEY_ESC();
    return TB_OK();
  };
  local $Termbox::global->{fn_extract_esc_post} = undef;

  my $event = Termbox::Event->new();
  is(Termbox::extract_esc($event), TB_OK(), 'extract_esc uses pre hook');
  is($event->{type}, TB_EVENT_KEY(), 'hook set event type');
  is($event->{key}, TB_KEY_ESC(), 'hook set event key');
  is($Termbox::global->{inbuf}, 'remain', 'extract_esc_user consumed bytes');
  is(
    Termbox::extract_esc_user($event, 1),
    TB_ERR(),
    'post hook absent returns TB_ERR'
  );
};

done_testing;
