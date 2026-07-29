use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'Termbox::PP';
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

sub Termbox::tb_debug_handler {
  $_ = shift;
  chomp;
  pass sprintf($_, @_);
};

subtest 'debug' => sub {
  plan tests => 4;

  lives_ok { Termbox::DEBUG('DEBUG message') } 'lives';
  lives_ok { Termbox::DEBUG('DEBUG formatted %s', 'message') } 'lives';
};

subtest 'trace' => sub {
  plan tests => 11;

  sub test_sub_with_args {
    Termbox::TRACE("%s", @_);
    my ($param) = @_;
    my $rv;
    my $guard = Termbox::TRACE_LEAVE(\$rv);
    if ($param eq 'early') {
      $rv = -1;
      return $rv;   # early exit
    }
    $rv = 100;
    return $rv;     # regular exit
  }

  sub test_sub_nested {
    Termbox::TRACE('');
    my $rv = 200;
    my $guard = Termbox::TRACE_LEAVE(\$rv);
    test_sub_with_args('normal');    # nesting test
    return $rv;
  }

  my $rv = test_sub_with_args('normal');
  is($rv, 100, "return value is correct for normal exit");
  $rv = test_sub_with_args('early');
  is($rv, -1, "return value is correct for early exit");
  $rv = test_sub_nested();
  is($rv, 200, "return value is correct for nested call");
};

done_testing;
