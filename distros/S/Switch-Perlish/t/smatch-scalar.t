use strict;
use warnings;
use lib "t";

use Switch::Perlish;
use Test::More tests => 16;

use switchtest;
use vars qw/ $yay $nay /;

my $topic = 'this value is also a comment';
my $failc = 'yet another string of chars';
sub t_copy { my $copy = \$topic; $copy }

switchtest {
  qw/t_type SCALAR m_type VALUE/,
  topic => \$topic,
  failc => $failc,
  passc => $topic,
};

switchtest {
  qw/t_type SCALAR m_type UNDEF/,
  topic => \undef,
  failc => \$failc,
  passc => undef,
};

switchtest {
  qw/t_type SCALAR m_type SCALAR/,
  topic => \$topic,
  failc => \$failc,
  passc => &t_copy,
};

{
  my $array = [ 1 .. 3 ];
  switchtest {
    qw/t_type SCALAR m_type ARRAY/,
    topic => \$array->[1],
    failc => [\(qw/ perl5's only hyper-operator /)],
    passc => $array,
  };
}

{
  my $hash  = { foo => 'stuff' };
  switchtest {
    qw/t_type SCALAR m_type HASH/,
    topic => \$hash->{foo},
    failc => { tiny => \'hash' },
    passc => $hash,
  };
}

$topic = sub { 'this one' };
switchtest {
  qw/t_type SCALAR m_type CODE/,
  topic => \$topic,
  failc => sub { },
  passc => &t_copy,
};

$topic = \$yay;
switchtest {
  qw/t_type SCALAR m_type OBJECT/,
  topic => $topic,
  failc => $nay,
  passc => $yay,
};

$topic = \qr/^\w+( \w+)+$/;
switchtest {
  qw/t_type SCALAR m_type Regexp/,
  topic => \$topic,
  failc => qr/\d+/,
  passc => &t_copy,
};
