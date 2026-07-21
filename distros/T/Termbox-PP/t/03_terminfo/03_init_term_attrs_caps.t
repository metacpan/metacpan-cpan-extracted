use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  if ($^O eq 'MSWin32') {
    plan skip_all => 'Not available on Windows';
  }
}

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return );
}

subtest 'init_term_attrs' => sub {
  plan tests => 1;
  # Ensure it's defined for the check
  $Termbox::global->{ttyfd} //= -1;
  is(Termbox::init_term_attrs(), TB_OK(), 'init_term_attrs returns TB_OK');
};

subtest 'init_term_caps' => sub {
  if (!defined $ENV{TERM}) {
    plan skip_all => 'TERM not set';
  }
  plan tests => 1;
  my $rv = Termbox::init_term_caps();
  ok(
    $rv == TB_OK() || $rv == TB_ERR_NO_TERM(), 
    'init_term_caps returns TB_OK or TB_ERR_NO_TERM'
  );
};

done_testing;
