use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return );
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

subtest 'cellbuf_init wrapper' => sub {
  plan tests => 4;
  my $buf = cellbuf->new();

  my $rv;
  lives_ok { $rv = Termbox::cellbuf_init($buf, 3, 2) } 'call cellbuf_init';
  is($rv, TB_OK(), 'returns TB_OK');
  is($buf->{width}, 3, 'width set');
  is($buf->{height}, 2, 'height set');
};

subtest 'cellbuf_get and cellbuf_in_bounds wrappers' => sub {
  plan tests => 6;
  my $buf = cellbuf->new();
  is(Termbox::cellbuf_init($buf, 2, 2), TB_OK(), 'init 2x2');

  is(Termbox::cellbuf_in_bounds($buf, 1, 1), 1, 'in bounds returns 1');
  is(Termbox::cellbuf_in_bounds($buf, 3, 0), 0, 'out of bounds returns 0');

  my $out;
  is(Termbox::cellbuf_get($buf, 1, 1, \$out), TB_OK(), 'cellbuf_get ok');
  isa_ok($out, 'Termbox::Cell');
  is(Termbox::cellbuf_get($buf, 9, 9, \$out), TB_ERR_OUT_OF_BOUNDS(), 'cellbuf_get out of bounds');
};

subtest 'cellbuf_clear wrapper' => sub {
  plan tests => 3;
  my $buf = cellbuf->new();
  is(Termbox::cellbuf_init($buf, 2, 1), TB_OK(), 'init');

  is(Termbox::cell_set($buf->{cells}[0], [ord 'X'], 1, 11, 12), TB_OK(), 'seed first cell');
  is(Termbox::cellbuf_clear($buf), TB_OK(), 'clear returns TB_OK');
};

subtest 'cellbuf_resize wrapper' => sub {
  plan tests => 4;
  my $buf = cellbuf->new();
  is(Termbox::cellbuf_init($buf, 2, 2), TB_OK(), 'init');

  is(Termbox::cell_set($buf->{cells}[0], [ord 'A'], 1, 3, 4), TB_OK(), 'seed content');
  is(Termbox::cellbuf_resize($buf, 3, 2), TB_OK(), 'resize returns TB_OK');
  is($buf->{width} * $buf->{height}, scalar(@{$buf->{cells}}), 'cell count matches dimensions');
};

subtest 'cellbuf_free wrapper' => sub {
  plan tests => 4;
  my $buf = cellbuf->new();
  is(Termbox::cellbuf_init($buf, 2, 2), TB_OK(), 'init');

  is(Termbox::cellbuf_free($buf), TB_OK(), 'free returns TB_OK');
  is($buf->{width}, 0, 'width reset');
  is($buf->{height}, 0, 'height reset');
};

done_testing;
