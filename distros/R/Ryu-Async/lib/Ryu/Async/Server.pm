package Ryu::Async::Server;

use strict;
use warnings;

our $VERSION = '0.013'; # VERSION

sub new { bless { @_[1..$#_] }, $_[0] }

sub port { shift->{port} }
sub incoming { shift->{incoming} }
sub outgoing { shift->{outgoing} }

1;

