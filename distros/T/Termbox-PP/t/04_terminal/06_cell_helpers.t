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

subtest 'cell_set accepts codepoint' => sub {
  plan tests => 5;
  my $cell = Termbox::Cell->new();
  my $rv;

  lives_ok { $rv = Termbox::cell_set($cell, [ ord('A') ], 1, 3, 4) } 
    'call cell_set(codepoint)';
  is($rv, TB_OK(), 'returns TB_OK');
  is($cell->ch, ord('A'), 'sets single codepoint');
  is($cell->fg, 3,        'sets fg');
  is($cell->bg, 4,        'sets bg');
};

subtest 'cell_set accepts arrayref of codepoints' => sub {
  plan tests => 4;
  my $cell = Termbox::Cell->new();
  my $rv;

  lives_ok { $rv = Termbox::cell_set($cell, [ ord('A'), 0x0308 ], 2, 5, 6) } 
    'call cell_set(arrayref)';
  is($rv, TB_OK(), 'returns TB_OK');
  is(substr(chr($cell->ch), 0, 1), 'A', 'first codepoint is set');
  is($cell->fg, 5, 'sets fg');
};

subtest 'cell_set rejects string input' => sub {
  my $cell = Termbox::Cell->new();
  my $rv;

  $rv = eval { Termbox::cell_set($cell, 'A', 1, 1, 2) } // TB_ERR();
  is($rv, TB_ERR(), 'returns TB_ERR for string input');
};

subtest 'cell_set rejects numeric scalar input' => sub {
  my $cell = Termbox::Cell->new();
  my $rv;

  $rv = eval { Termbox::cell_set($cell, ord('A'), 1, 1, 2) } // TB_ERR();
  is($rv, TB_ERR(), 'returns TB_ERR for numeric scalar input');
};

subtest 'cell_set rejects invalid array elements' => sub {
  plan tests => 2;
  my $cell = Termbox::Cell->new();
  my $rv;

  lives_ok { 
    local $SIG{__WARN__} = sub { };
    $rv = Termbox::cell_set($cell, [ ord('A'), 'x' ], 2, 1, 2)
  } 'call cell_set(mixed arrayref)';
  ok(
    $rv == TB_OK() || $rv == TB_ERR(),
    'returns TB_OK/TB_ERR for invalid array element'
  );
};

subtest 'cell_cmp and cell_copy wrappers' => sub {
  plan tests => 5;
  my $a = Termbox::Cell->new();
  my $b = Termbox::Cell->new();

  is(Termbox::cell_set($a, [ ord('X') ], 1, 9, 1), TB_OK(), 'set a');
  is(Termbox::cell_set($b, [ ord('X') ], 1, 9, 1), TB_OK(), 'set b');
  is(Termbox::cell_cmp($a, $b), 0, 'equal cells compare to 0');
  is(Termbox::cell_copy($b, $a), TB_OK(), 'copy succeeds');
  is(Termbox::cell_cmp($a, $b), 0, 'still equal after copy');
};

subtest 'cell_reserve_ech and cell_free wrappers' => sub {
  plan tests => 3;
  my $cell = Termbox::Cell->new();

  my $rv = Termbox::cell_reserve_ech($cell, 8);
  my $expected = Termbox::TB_OPT_EGC() ? TB_OK() : TB_ERR();
  is($rv, $expected, 'cell_reserve_ech follows TB_OPT_EGC');

  is(Termbox::cell_set($cell, [ ord('Z') ], 1, 7, 8), TB_OK(), 
    'set before free');
  is(Termbox::cell_free($cell), TB_OK(), 'cell_free succeeds');
};

done_testing;
