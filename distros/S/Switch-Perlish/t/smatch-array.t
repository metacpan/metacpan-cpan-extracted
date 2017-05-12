use strict;
use warnings;
use lib "t";

use Switch::Perlish;
use Test::More tests => 15;

use switchtest;
use vars qw/ $yay $nay /;

switchtest {
  qw/t_type ARRAY m_type VALUE/,
  topic => [qw/ foo bar baz /],
  failc => 'incorrect',
  passc => 'foo',
};

{
  ## this can only ever return false so we can't use switchtest()
  my $yay;
  switch [qw/ I'm defined /], sub {
    case undef, sub {
      $yay = fail "ARRAY<=>UNDEF: shouldn't succesfully match"
    };
    $yay = pass "ARRAY<=>UNDEF: successfully failed";
  };
}

{
  my $topic = [ 18 .. 24 ];
  ## all references to undef are the same
  switchtest {
    qw/t_type ARRAY m_type SCALAR/,
    topic => $topic,
    failc => \42,
    passc => \$topic->[3],
  };
}

switchtest {
  qw/t_type ARRAY m_type ARRAY/,
  topic => [qw/ foo bar baz /],
  failc => [qw/ not in here /],
  passc => [qw/ we're off to the bar /],
};

switchtest {
  qw/t_type ARRAY m_type HASH/,
  topic => [qw/ foo bar baz /],
  failc => { qw/ not in here ! / },
  passc => { qw/ in the bar ! / },
};

switchtest {
  qw/t_type ARRAY m_type CODE/,
  topic => [qw/ foo bar baz /],
  failc => sub { 0 },
  passc => sub { "@_" =~ /foo/ },
};

switchtest {
  qw/t_type ARRAY m_type OBJECT/,
  topic => [ qw/ please JUSTDONT ever / ],
  failc => $nay,
  passc => $yay,
};

switchtest {
  qw/t_type ARRAY m_type Regexp/,
  topic => [qw/ the following will match /],
  failc => qr/\d+/,
  passc => qr/^foll/,
};

