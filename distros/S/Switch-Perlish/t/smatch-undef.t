use strict;
use warnings;
use lib "t";

use Switch::Perlish;
use Test::More 'no_plan';#tests => 14;

use switchtest;
use vars qw/ $yay $nay /;

my $topic = undef;
{
  ## this can only ever return false so we can't use switchtest()
  my $yay;
  switch $topic, sub {
    case 'foo', sub {
     $yay = fail "UNDEF<=>VALUE: shouldn't succesfully match"
    };
    $yay = pass "UNDEF<=>VALUE: successfully failed";
  };
  fail "UNDEF<=>VALUE: failed to properly match"
    if !$yay;
}

{
  ## this can only ever return true so we can't use switchtest()
  my $yay;
  switch $topic, sub {
    case undef, sub {
      $yay = pass "UNDEF<=>UNDEF: succesfully matched"
    };
    $yay = fail "UNDEF<=>UNDEF: unsuccessfully matched";
  };
  fail "UNDEF<=>UNDEF: failed to properly match\n"
    unless $yay;
}

switchtest {
  qw/t_type UNDEF m_type SCALAR/,
  topic => $topic,
  failc => \'bar',
  passc => \undef,
};

switchtest {
  qw/t_type UNDEF m_type ARRAY/,
  topic => $topic,
  failc => [qw/ not in here /],
  passc => [ 'foo', undef ],
};

switchtest {
  qw/t_type UNDEF m_type HASH/,
  topic => $topic,
  failc => {qw/ not in here ! /},
  passc => { foo => 1, bar => undef },
};

switchtest {
  qw/t_type UNDEF m_type CODE/,
  topic => $topic,
  failc => sub { },
  passc => sub { !defined($_[0]) },
};

{
  ## this croak()s so don't use switchtest()
  local $@;
  eval { switch $topic, sub { case $yay, sub { } } };
  like $@, qr/^Can't compare undef with OBJECT/,
       "UNDEF<=>OBJECT: croaks as expected";
}

{
  ## this croak()s so don't use switchtest()
  local $@;
  eval { switch $topic, sub { case qr/fail/, sub { } } };
  like $@, qr/^Can't compare undef with Regexp/,
       "UNDEF<=>Regexp: croaks as expected";
}
