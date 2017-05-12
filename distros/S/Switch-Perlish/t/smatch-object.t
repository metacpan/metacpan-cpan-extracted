use strict;
use warnings;
use lib "t";

use Switch::Perlish;
use Test::More tests => 15;

use switchtest;
use vars qw/ $yay $nay /;

my $tpkg = 'Switch::Perlish::_test';
## we usually use $yay/$nay objects, but let's be specific now
my $obj = bless [qw/some strings/], $tpkg;

switchtest {
  qw/t_type OBJECT m_type VALUE/,
  topic => $obj,
  failc => 'nomethod',
  passc => 'amethod',
};

{
  ## this croak()s so don't use switchtest()
  local $@;
  eval { switch $obj, sub { case undef, sub { } } };
  like $@, qr/^Can't compare OBJECT with an undef/,
       "OBJECT<=>UNDEF: croaks as expected";
}

switchtest {
  qw/t_type OBJECT m_type SCALAR/,
  topic => $obj,
  failc => \42,
  passc => \$obj,
};

switchtest {
  qw/t_type OBJECT m_type ARRAY/,
  topic => $obj,
  failc => [qw/ not in here /],
  passc => [qw/ just plucking some strings /],
};

$obj = bless { qw/this is a hash/ }, $tpkg;
switchtest {
  qw/t_type OBJECT m_type HASH/,
  topic => $obj,
  failc => { qw/ not found in here / },
  passc => { qw/ hold it! this is a stickup! / },
};

switchtest {
   qw/t_type OBJECT m_type CODE/,
   topic => $obj,
   failc => sub { 0 },
   passc => sub { $_[0] =~ /$tpkg/ },
};

switchtest {
  qw/t_type OBJECT m_type OBJECT/,
  topic => $obj,
  failc => $nay,
  passc => $yay,
};

switchtest {
  qw/t_type OBJECT m_type Regexp/,
  topic => $obj,
  failc => qr/\d+/,
  passc => qr/test$/,
};

