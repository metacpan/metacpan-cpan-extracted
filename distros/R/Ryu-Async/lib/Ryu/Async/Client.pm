package Ryu::Async::Client;
$Ryu::Async::Client::VERSION = '0.008';
use strict;
use warnings;

sub new { bless { @_[1..$#_] }, $_[0] }

sub incoming { shift->{incoming} }
sub outgoing { shift->{outgoing} }

1;

