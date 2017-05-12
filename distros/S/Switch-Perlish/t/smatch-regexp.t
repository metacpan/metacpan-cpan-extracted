use strict;
use warnings;
use lib "t";

use Switch::Perlish;
use Test::More tests => 15;

use switchtest;
use vars qw/ $yay $nay /;

my $topic = qr/^[a-zA-Z]+/;
switchtest {
  qw/t_type Regexp m_type VALUE/,
  topic => $topic,
  failc => '1ncorrect',
  passc => 'foo etc.',
};

{
  ## this croak()s so don't use switchtest()
  local $@;
  eval { switch $topic, sub { case undef, sub { } } };
  like $@, qr/^Can't compare Regexp with an undef/,
       "Regexp<=>UNDEF: croaks as expected";
}

switchtest {
  qw/t_type Regexp m_type SCALAR/,
  topic => $topic,
  failc => \42,
  passc => \$topic,
};

switchtest {
  qw/t_type Regexp m_type ARRAY/,
  topic => $topic,
  failc => [qw{ 7his \/\/on't /\/\atch }],
  passc => [qw/ this does /],
};

switchtest {
  qw/t_type Regexp m_type HASH/,
  topic => $topic,
  failc => { qw/ ! nope ? never / },
  passc => { qw/ of course / },
};

switchtest {
  qw/t_type Regexp m_type CODE/,
  topic => $topic,
  failc => sub { '|\|aw' =~ $_[0] },
  passc => sub { 'yeah'  =~ $_[0] },
};

switchtest {
  qw/t_type Regexp m_type OBJECT/,
  topic => qr/_test/,
  failc => $nay,
  passc => $yay,
};

switchtest {
  qw/t_type Regexp m_type Regexp/,
  topic => qr/x-ism/,
  failc => qr/this can't match/,
  passc => qr/this magically will/x,
};
