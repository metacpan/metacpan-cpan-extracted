use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return :event :keys );
}

sub lives_ok (&$) {
  my ($code, $name) = @_;
  my $error;
  my $ok = eval { $code->(); 1 };
  $error = $@;
  ok($ok, $name);
  diag("Died with: $error") unless $ok;
  return $ok;
}

subtest 'Termbox::Cell->new' => sub {
  plan tests => 5;
  my $cell;
  lives_ok { $cell = Termbox::Cell->new() } 'new() lives';
  isa_ok    $cell, 'Termbox::Cell',  'returns blessed object';
  is        $cell->ch, 0, 'ch defaults to 0';
  is        $cell->fg, 0, 'fg defaults to 0';
  is        $cell->bg, 0, 'bg defaults to 0';
};

subtest 'Termbox::Cell::set and accessors' => sub {
  plan tests => 8;
  my $cell = Termbox::Cell->new();
  my $rv;
  lives_ok { $rv = $cell->set('A', 3, 5) } 'set() lives';
  is $rv,         TB_OK(), 'set returns TB_OK';
  is $cell->[0], 'A',      'ch stored as UTF-8 string';
  is $cell->[1], 3,        'fg stored';
  is $cell->[2], 5,        'bg stored';
  is $cell->ch,  ord('A'), 'ch() returns codepoint';
  is $cell->fg,  3,        'fg() accessor';
  is $cell->bg,  5,        'bg() accessor';
};

subtest 'Termbox::Cell::set empty ch' => sub {
  plan tests => 2;
  my $cell = Termbox::Cell->new();
  $cell->set('X', 1, 2);
  is $cell->set('', 0, 0), TB_OK(), 'empty ch accepted';
  is $cell->ch, 0,                  'ch set to 0 for empty string';
};

subtest 'Termbox::Cell::equal' => sub {
  plan tests => 4;
  my $a = Termbox::Cell->new();
  my $b = Termbox::Cell->new();
  $a->set('X', 9, 1);
  $b->set('X', 9, 1);
  is $a->equal($b), 1, 'identical cells are equal';
  $b->set('Y', 9, 1);
  is $a->equal($b), 0, 'different ch: not equal';
  $b->set('X', 8, 1);
  is $a->equal($b), 0, 'different fg: not equal';
  $b->set('X', 9, 2);
  is $a->equal($b), 0, 'different bg: not equal';
};

subtest 'Termbox::Cell::copy' => sub {
  plan tests => 5;
  my $src = Termbox::Cell->new();
  my $dst = Termbox::Cell->new();
  $src->set('M', 5, 3);
  my $rv;
  lives_ok { $rv = $dst->copy($src) } 'copy() lives';
  is $rv,      TB_OK(),  'copy returns TB_OK';
  is $dst->ch, ord('M'), 'ch copied';
  is $dst->fg, 5,        'fg copied';
  is $dst->bg, 3,        'bg copied';
};

SKIP: {
  skip 'TB_OPT_EGC not enabled', 4 unless Termbox::TB_OPT_EGC();

  subtest 'Termbox::Cell EGC accessors' => sub {
    plan tests => 4;
    my $cell = Termbox::Cell->new();
    $cell->set("A\x{0308}", 1, 0);  # A + combining diaeresis
    my $ech = $cell->ech;
    is ref($ech), 'ARRAY', 'ech() returns ARRAY ref';
    is $ech->[0], ord('A'), 'first codepoint in ech';
    ok $cell->nech >= 1,    'nech() >= 1 for EGC';
    ok $cell->cech >= 1,    'cech() >= 1 for EGC';
  };
}

subtest 'Termbox::Event->new' => sub {
  plan tests => 10;
  my $ev;
  lives_ok { $ev = Termbox::Event->new() } 'new() lives';
  isa_ok    $ev, 'Termbox::Event', 'returns blessed object';
  is $ev->{type}, 0, 'type defaults to 0';
  is $ev->{mod},  0, 'mod defaults to 0';
  is $ev->{key},  0, 'key defaults to 0';
  is $ev->{ch},   0, 'ch defaults to 0';
  is $ev->{w},    0, 'w defaults to 0';
  is $ev->{h},    0, 'h defaults to 0';
  is $ev->{x},    0, 'x defaults to 0';
  is $ev->{y},    0, 'y defaults to 0';
};

subtest 'Termbox::Event accessors' => sub {
  plan tests => 8;
  my $ev = Termbox::Event->new();
  $ev->{type} = TB_EVENT_KEY;
  $ev->{mod}  = TB_MOD_CTRL;
  $ev->{key}  = TB_KEY_ENTER;
  $ev->{ch}   = ord('a');
  $ev->{w}    = 80;
  $ev->{h}    = 24;
  $ev->{x}    = 10;
  $ev->{y}    = 5;
  is $ev->type, TB_EVENT_KEY,  'type() accessor';
  is $ev->mod,  TB_MOD_CTRL,   'mod() accessor';
  is $ev->key,  TB_KEY_ENTER,  'key() accessor';
  is $ev->ch,   ord('a'),      'ch() accessor';
  is $ev->w,    80,            'w() accessor';
  is $ev->h,    24,            'h() accessor';
  is $ev->x,    10,            'x() accessor';
  is $ev->y,    5,             'y() accessor';
};

subtest 'Termbox::Event type constants' => sub {
  plan tests => 3;
  is TB_EVENT_KEY,    1, 'TB_EVENT_KEY == 1';
  is TB_EVENT_RESIZE, 2, 'TB_EVENT_RESIZE == 2';
  is TB_EVENT_MOUSE,  3, 'TB_EVENT_MOUSE == 3';
};

done_testing;
