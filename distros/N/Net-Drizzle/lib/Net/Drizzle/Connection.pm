package Net::Drizzle::Connection;
use strict;
use warnings;
use IO::Handle;

sub fh {
    my $self = shift;
    my $fh = IO::Handle->new;
       $fh->fdopen($self->fd, 'r+');
       $fh;
}

1;

