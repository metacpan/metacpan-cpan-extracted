use strict;
use warnings;
use lib "t";

use vars '$pkg';

use Test::More 'no_plan';

BEGIN {
  $pkg = 'Switch::Perlish';
  use_ok $pkg;
}

can_ok(__PACKAGE__, $_)
  for @Switch::Perlish::EXPORT;

ok eval <<'C0D3Z', 'basic switch() call';
switch 1, sub {
  case 1, sub { 1 };
};
C0D3Z

ok eval <<'C0D3Z', 'basic switch() call with default';
switch 1, sub {
  case 0, sub { 1 };
  default sub { 1 };
};
C0D3Z

{
  local $@;
  eval {
    switch 1, sub { case 1 };
  };
  like $@, qr/^No case block provided/, 'missing case block detected ok';
}

{
  my $yay = 1;
  switch 1, sub {
    case 1, sub { stop };
    $yay = fail "kept on falling through after stop";
  };
  pass "exited switch with stop ok"
    if $yay;
}

for(qw/ case default fallthrough stop /) {
  local $@;
  eval { __PACKAGE__->can($_)->() };
  like $@, qr/Not called within/,
       "$_ failed expectedly when called out of context";
}

{
  my $ret = 'http://bash.org/?201';
  my $res = switch 1, sub { case 1, sub { $ret } };
  is $res, $ret, 'check we get result ok';
}

{
  my $ret = 'http://bash.org/?422766';
  my $res = switch 1, sub { default sub { $ret } };
  is $ret, $res, 'check we get result ok from default';
}

{
  my $ret = 'http://bash.org/?1180';
  my $res = switch 1, sub { return $ret; case 1, sub { 1 } };
  is $ret, $res, 'check we get result ok from early return';
}

{
  my $yay;
  # my $ret = 'http://bash.org/?14833';
  $yay = 0;
  switch 1, sub {
    case 1, sub { fallthrough };
    $yay = pass "fell through successfully with fallthrough()";
    case 1, sub { pass "in another case after fallthrough" };
    $yay = fail "kept on falling through";
  };
  pass "did NOT fallthrough case successfully"
    unless $yay;
}

{
  my $yay = 1;
  switch 1, sub {
    case 1, sub { 1 };
    $yay = fail "successful case statement did NOT exit the switch block";
  };
  pass "successful case statement did exited switch block"
    if $yay;
}

{
  local $@;
  my $errmsg = "http://bash.org/?44584\n";
  eval { switch 1, sub { die($errmsg) }; };
  is $@, $errmsg, 'propagated error correctly';
}

{
  my $yay = 0;
  switch 1, sub {
    case 1, sub {
      switch 2, sub {
        case 2, sub { $yay = pass "made it into nested switch" };
        $yay = fail "did NOT exit nested switch properly";
      };
      pass "executed nested switch ok"
        if $yay;
    };
  };
}

{
  local $@;
  my $errmsg = "http://bash.org/?6618\n";
  eval {
    switch 1, sub {
      case 1, sub {
        switch 2, sub {
          case 2, sub { die($errmsg); };
        };
        fail "did NOT die in nested switch";
      };
    };
  };
  is $@, $errmsg, 'propagated error from nested switch';
}

{
  switch 'foo', sub {
    case 'foo', sub {
      is $_, 'foo', 'topic set correctly';
    };
  };
}

{
  switch 'foo', sub {
    case 'foo', sub {
      switch 'bar', sub {
        case 'bar', sub { is $_, 'bar', 'inner topic set correctly' };
      };
      is $_, 'foo', 'topic reverted correctly';
    };
  };
}

