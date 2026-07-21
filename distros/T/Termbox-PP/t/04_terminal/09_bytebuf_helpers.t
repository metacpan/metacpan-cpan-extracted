use 5.010;
use strict;
use warnings;

use Test::More;

use File::Temp qw( tempfile );

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return );
}

subtest 'bytebuf_puts and bytebuf_nputs wrappers' => sub {
  plan tests => 7;
  my $buf = '';

  my $rv = eval { Termbox::bytebuf_puts(\$buf, undef) } // TB_ERR;
  is($buf, '', 'puts do nothing for empty caps');

  is(Termbox::bytebuf_puts(\$buf, ''), TB_OK(), 'puts empty is ok');
  is($buf, '', 'empty unchanged');

  is(Termbox::bytebuf_puts(\$buf, 'abc'), TB_OK(), 'puts appends');
  is($buf, 'abc', 'puts content');

  is(
    Termbox::bytebuf_nputs(\$buf, 'XYZ123', 3), 
    TB_OK(), 
    'nputs appends n bytes'
  );
  is($buf, 'abcXYZ', 'nputs content');
};

subtest 'bytebuf_shift wrapper' => sub {
  plan tests => 3;
  my $buf = 'abcdef';

  is(Termbox::bytebuf_shift(\$buf, 2), TB_OK(), 'shift(2)');
  is($buf, 'cdef', 'first two removed');
  is(Termbox::bytebuf_shift(\$buf, 99), TB_OK(), 'overshift ok and clamped');
};

subtest 'bytebuf_reserve and bytebuf_free wrappers' => sub {
  plan tests => 4;
  my $buf = 'abc';

  is(Termbox::bytebuf_reserve(\$buf, 128), TB_OK(), 'reserve returns TB_OK');
  is($buf, 'abc', 'reserve is non-destructive');

  is(Termbox::bytebuf_free(\$buf), TB_OK(), 'free returns TB_OK');
  is($buf, '', 'free clears buffer');
};

subtest 'bytebuf_flush wrapper' => sub {
  plan skip_all => 'Not available on Windows' if $^O eq 'MSWin32';
  plan tests => 5;
  my $buf = "hello";
  my ($fh, $path) = tempfile();
  my $fd = fileno($fh);

  is(Termbox::bytebuf_flush(\$buf, $fd), TB_OK(), 'flush returns TB_OK');
  seek($fh, 0, 0) or die "seek failed: $!";
  my $sink = do { local $/; <$fh> };
  is($sink, 'hello', 'flush writes all data');
  is($buf, '', 'flush clears buffer');
  is(
    Termbox::bytebuf_flush(\$buf, $fd), TB_OK(), 
    'flush empty buffer is TB_OK'
  );
  $buf = "world";  
  is(
    Termbox::bytebuf_flush(\$buf, -1), 
    TB_ERR(), 
    'flush rejects invalid fd'
  );
};

subtest 'bytebuf_flush accepts STDERR fd' => sub {
  plan tests => 2;
  my $buf = '';
  my $fd = fileno(STDERR);

  is(
    Termbox::bytebuf_flush(\$buf, $fd), 
    TB_OK(), 
    'flush empty to STDERR fd is ok'
  );
  is($buf, '', 'buffer remains empty');
};

subtest 'bytebuf wrappers reject invalid buffer arg' => sub {
  plan tests => 2;
  my $rv = eval { Termbox::bytebuf_puts('not_ref', 'x') } // TB_ERR;
  is($rv, TB_ERR, 'puts returns TB_ERR for non-ref buffer');
  $rv = eval { Termbox::bytebuf_free('not_ref') } // TB_ERR;
  is($rv, TB_ERR, 'free returns TB_ERR for non-ref buffer');
};

done_testing;
