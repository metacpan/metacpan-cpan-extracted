use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  $ENV{EXTENDED_TESTING} = 1;
}

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw(
    :func
    tb_set_func
    tb_cell_buffer
    TB_OK
    TB_ERR
  );
}

subtest 'tb_set_func sets extract callbacks' => sub {
  local $SIG{__WARN__} = sub { warn @_ if $_[0] !~ /deprecated/i };
  plan tests => 6;

  my $pre  = sub { return 1 };
  my $post = sub { return 2 };

  # TB_FUNC_EXTRACT_PRE
  is(
    tb_set_func(TB_FUNC_EXTRACT_PRE(), $pre),
    TB_OK(),
    'tb_set_func(TB_FUNC_EXTRACT_PRE) returns TB_OK'
  );
  is(
    $Termbox::global->{fn_extract_esc_pre},
    $pre,
    'pre extract function stored'
  );

  # TB_FUNC_EXTRACT_POST
  is(
    tb_set_func(TB_FUNC_EXTRACT_POST(), $post),
    TB_OK(),
    'tb_set_func(TB_FUNC_EXTRACT_POST) returns TB_OK'
  );
  is(
    $Termbox::global->{fn_extract_esc_post},
    $post,
    'post extract function stored'
  );

  # invalid fn_type
  my $rv = eval { tb_set_func(-1, sub { }) } // TB_ERR();
  is(
    $rv,
    TB_ERR(),
    'invalid fn_type returns TB_ERR'
  );
  ok(
    !defined $Termbox::global->{fn_extract_esc_invalid},
    'no unexpected global side effects'
  );
};

subtest 'tb_cell_buffer deprecation + return shape' => sub {
  plan tests => 4;

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $first = tb_cell_buffer();
  my $second = tb_cell_buffer();

  is(
    ref($first), 
    'ARRAY',
    'tb_cell_buffer returns an array-ref'
  );
  is(
    ref($second),
    'ARRAY',
    'tb_cell_buffer keeps returning an array-ref'
  );
  is(scalar(@warnings), 1, 'tb_cell_buffer warns exactly once');
  like(
    $warnings[0],
    qr/deprecated/i,
    'tb_cell_buffer warning mentions deprecation'
  );
};

done_testing;
