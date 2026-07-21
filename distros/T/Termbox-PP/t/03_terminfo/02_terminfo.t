use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return );
}

use constant {
  INT16_SIZE    => Termbox::INT16_SIZE(),
  OUT_OF_BOUNDS => 512,
};

subtest 'Terminfo get_terminfo_* with mocked data' => sub {
  # suppress warnings when testing with mocked data
  local $SIG{__WARN__} = sub { };

  # Build a buffer: [offsets][string table]
  # offsets: 0, 4, 8 (relative to string table start)
  # string table: "foo\0bar\0baz\0"
  my $strtab = "foo\0bar\0baz\0";
  $Termbox::global->{terminfo} = pack('s<3', 0, 4, 8) . $strtab;

  plan tests => 9;

  is(
    Termbox::get_terminfo_string(0, 3, INT16_SIZE * 3, length($strtab), 0),
    'foo',
    'get_terminfo_string returns "foo" for index 0'
  );
  is(
    Termbox::get_terminfo_string(0, 3, INT16_SIZE * 3, length($strtab), 1),
    'bar',
    'get_terminfo_string returns "bar" for index 1'
  );
  is(
    Termbox::get_terminfo_string(0, 3, INT16_SIZE * 3, length($strtab), 2),
    'baz',
    'get_terminfo_string returns "baz" for index 2'
  );
  is(
    Termbox::get_terminfo_string(0, 3, INT16_SIZE * 3, length($strtab), 
      OUT_OF_BOUNDS),
    '', 
    'get_terminfo_string returns empty str for out-of-bounds offset'
  );

  # get_terminfo_int16 expects: ($offset, \$val)
  my $val;
  is(
    Termbox::get_terminfo_int16(0, \$val),
    TB_OK(),
    'get_terminfo_int16 returns TB_OK for offset 0'
  );
  is($val, 0, 'get_terminfo_int16 unpacks 0 at offset 0');
  Termbox::get_terminfo_int16(2, \$val);
  is($val, 4, 'get_terminfo_int16 unpacks 4 at offset 2');
  Termbox::get_terminfo_int16(4, \$val);
  is($val, 8, 'get_terminfo_int16 unpacks 8 at offset 4');
  is(
    Termbox::get_terminfo_int16(OUT_OF_BOUNDS, \$val), 
    TB_ERR(), 
    'get_terminfo_int16 returns TB_ERR for out-of-bounds offset'
  );
};

subtest 'Terminfo file loading and access' => sub {
  if ($^O eq 'MSWin32') {
    plan skip_all => 'Terminfo not available on Windows';
  }
  if (!defined $ENV{TERM}) {
    plan skip_all => 'TERM not set';
  }
  if (!defined $ENV{TERMINFO} && !-d '/usr/share/terminfo') {
    plan skip_all => 'No terminfo directory available';
  }

  plan tests => 1;

  my $terminfo_dir = $ENV{TERMINFO} // '/usr/share/terminfo';
  my $term         = $ENV{TERM};

  my $rv;
  ok(
    eval { $rv = Termbox::load_terminfo_from_path($terminfo_dir, $term); 1 },
    'load_terminfo_from_path lives'
  );
};

subtest 'load_terminfo' => sub {
  if ($^O eq 'MSWin32') {
    plan skip_all => 'Terminfo not available on Windows';
  }
  if (!defined $ENV{TERM}) {
    plan skip_all => 'TERM not set';
  }

  plan tests => 2;
  my $rv;
  ok(
    eval { $rv = Termbox::load_terminfo(); 1 },
    'load_terminfo lives'
  );
  ok(
    $rv == TB_OK() || $rv == TB_ERR(),
    'load_terminfo returns a valid status'
  );
};

subtest 'parse_terminfo_caps' => sub {
  if ($^O eq 'MSWin32') {
    plan skip_all => 'Terminfo not available on Windows';
  }
  if (!defined $ENV{TERM}) {
    plan skip_all => 'TERM not set';
  }
  # Ensure terminfo is loaded first
  my $rv = Termbox::load_terminfo();
  plan skip_all => 'terminfo not loaded' if $rv != TB_OK();

  is(
    Termbox::parse_terminfo_caps(),
    TB_OK(),
    'parse_terminfo_caps returns TB_OK after successful load'
  );
};

done_testing;
