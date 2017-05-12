package SkypeAPI::Command;

use strict;
use warnings;

use Class::Accessor::Fast;
our @ISA = qw(Class::Accessor::Fast);


# Preloaded methods go here.
use Time::HiRes qw( sleep );

__PACKAGE__->mk_accessors(
  qw/blocking id timeout string reply/
);


1;
__END__
