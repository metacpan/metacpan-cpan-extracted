use strict;
use warnings;
use lib "t";

use Switch::Perlish;
use Test::More tests => 14;

use switchtest;
use vars qw/ $yay $nay /;

my $topic= 'foo';
switchtest {
  qw/t_type VALUE m_type VALUE/,
  topic => $topic,
  failc => 'bar',
  passc => 'foo',
};

switchtest {
  qw/t_type VALUE m_type SCALAR/,
  topic => $topic,
  failc => 'bar',
  passc => \$topic,
};

switchtest {
  qw/t_type VALUE m_type ARRAY/,
  topic => $topic,
  failc => [qw/ not in here /],
  passc => [qw/ bar baz foo /],
};

switchtest {
  qw/t_type VALUE m_type HASH/,
  topic => $topic,
  failc => {qw/ not in here ! /},
  passc => {qw/ foo bar baz quux /},
};

switchtest {
  qw/t_type VALUE m_type CODE/,
  topic => $topic,
  failc => sub { },
  passc => sub { $_[0] eq 'foo' },
};

switchtest {
  qw/t_type VALUE m_type OBJECT/,
  topic => 'JUSTDONT',
  failc => $nay,
  passc => $yay,
};

switchtest {
  qw/t_type VALUE m_type Regexp/,
  topic => 'wooooob woob woob woob woob woob',
  failc => qr/\d+/,
  passc => qr/^\w+( \w+)+$/,
};
