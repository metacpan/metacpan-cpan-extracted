package DummySocket;
use parent 'IO::Socket::UNIX';
use strict;

# Mojo::UserAgent->_connected calls these: they're not important for a unix
# socket, but the methods have to be there.
sub sockhost { \1 };
sub peerhost { \1 };
sub sockport { -1 };
sub peerport { -1 };

1;
