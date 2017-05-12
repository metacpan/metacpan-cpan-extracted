use strict;
use warnings;
use lib "t";

use Switch::Perlish;
use Test::More tests => 16;

use switchtest;
use vars qw/ $yay $nay /;

switchtest {
  qw/t_type CODE m_type VALUE/,
  topic => sub { $_[0] =~ /wicked/ },
  failc => 'nothing cool',
  passc => 'something wicked this way comes',
};

switchtest {
  qw/t_type CODE m_type UNDEF/,
  topic => sub { !defined($_[0]) },
  failc => 'defined',
  passc => undef,
};

{
  my $topic = sub { };
  switchtest {
    qw/t_type CODE m_type SCALAR/,
    topic => $topic,
    failc => \sub { 'xxx' },
    passc => \$topic,
  };
}

switchtest {
  qw/t_type CODE m_type ARRAY/,
  topic => sub { $_[-1] eq 'wizard' },
  failc => [qw/ not in here /],
  passc => [qw/ we're off to see the wizard /],
};

switchtest {
  qw/t_type CODE m_type HASH/,
  topic => sub { my %h = @_; exists $h{foo} },
  failc => { qw/ not in here ! / },
  passc => { qw/ pity the foo who mess with perl internals / },
};

switchtest {
  qw/t_type CODE m_type CODE/,
  topic => sub { $_[0]->() },
  failc => sub { 0 },
  passc => sub { 1 },
};

switchtest {
  qw/t_type CODE m_type OBJECT/,
  topic => sub { $_[0]->can('amethod') },
  failc => $nay,
  passc => $yay,
};

switchtest {
  qw/t_type CODE m_type Regexp/,
  topic => sub { "$_[0]" =~ /x-ism/ },
  failc => qr/\d+/,
  passc => qr/only the internals of this are matched/x,
};

