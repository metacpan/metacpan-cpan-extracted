package Protocol::DBus::Parser;

use strict;
use warnings;

use Protocol::DBus::Message ();

use constant _CHUNK_SIZE => 65536;

sub new {
    my ($class, $socket) = @_;

    return bless { _s => $socket, _buf => q<> }, $class;
}

sub get_message {
    my ($self) = @_;

    my $msg;

    if (length $self->{'_buf'}) {
        $msg = Protocol::DBus::Message->parse( \$self->{'_buf'} );
    }

    if (!$msg) {
        {
            my $got = sysread(
                $self->{'_s'},
                $self->{'_buf'},
                _CHUNK_SIZE(),
                length $self->{'_buf'},
            );

            if (defined $got) {
                $msg = Protocol::DBus::Message->parse( \$self->{'_buf'} ) or do {
                    redo if $got == _CHUNK_SIZE();
                };
            }
            elsif (!$!{'EAGAIN'} && !$!{'EWOULDBLOCK'}) {
                die "recv(): $!";
            }
        }
    }

    return $msg;
}

1;
