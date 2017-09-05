package Ryu::Async::Server;
$Ryu::Async::Server::VERSION = '0.007';
use strict;
use warnings;

sub new { bless { @_[1..$#_] }, $_[0] }

sub port { shift->{port} }
sub incoming { shift->{incoming} }
sub outgoing { shift->{outgoing} }

1;

