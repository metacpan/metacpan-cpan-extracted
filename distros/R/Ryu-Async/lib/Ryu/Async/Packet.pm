package Ryu::Async::Packet;
$Ryu::Async::Packet::VERSION = '0.008';
use strict;
use warnings;

sub new { bless { @_[1..$#_] }, $_[0] }

sub payload { $_[0]->{payload} }
sub from { $_[0]->{from} }

1;

