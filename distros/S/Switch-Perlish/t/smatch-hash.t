use strict;
use warnings;
use lib "t";

use Switch::Perlish;
use Test::More tests => 16;

use switchtest;
use vars qw/ $nay $yay /;

switchtest {
  qw/t_type HASH m_type VALUE/,
  topic => {qw/ foo bar baz quux /},
  failc => 'notthis',
  passc => 'baz',
};

switchtest {
  qw/t_type HASH m_type UNDEF/,
  topic => { foo => undef },
  failc => 'notthis',
  passc => undef,
};

{
  my $topic = { foo => 'stuff' };
  switchtest {
    qw/t_type HASH m_type SCALAR/,
    topic => $topic,
    failc => \'this is not the ref you are looking for',
    passc => \$topic->{foo},
  };
}

switchtest {
  qw/t_type HASH m_type ARRAY/,
  topic => {qw/ foo bar baz quux /},
  failc => [qw/ none of these /],
  passc => [qw/ at the baz /],
};

switchtest {
  qw/t_type HASH m_type HASH/,
  topic => {qw/ foo bar baz quux /},
  failc => {qw/ none of these ! /},
  passc => {qw/ godd ol' baz quux /},
};

switchtest {
  qw/t_type HASH m_type CODE/,
  topic => {qw/this isn't a set/},
  failc => sub { 'wah wah' },
  passc => sub { 'this' },
};

switchtest {
  qw/t_type HASH m_type OBJECT/,
  topic => {qw/JUSTDONT use this ever/},
  failc => $nay,
  passc => $yay,
};

switchtest {
  qw/t_type HASH m_type Regexp/,
  topic => {qw/one of these matches/},
  failc => qr/\d+/,
  passc => qr/ese$/,
};
