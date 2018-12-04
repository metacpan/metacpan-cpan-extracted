package Protocol::DBus::Parser;

use strict;
use warnings;

use Protocol::DBus::Marshal ();
use Protocol::DBus::Message ();

use constant SINGLE_UNIX_FD_CMSGHDR => (0, 0, pack 'I!');

use constant _LE_INIT_UNPACK => 'x4 V x4 V';
use constant _BE_INIT_UNPACK => 'x4 N x4 N';

sub new {
    my ($class, $socket) = @_;

    return bless { _s => $socket, _buf => q<> }, $class;
}

sub get_message {
    my ($self) = @_;

    my $msg;

    if (!$self->{'_bodysz'}) {
        if (defined recv( $self->{'_s'}, my $peek, 16, Socket::MSG_PEEK() )) {
            if ( 16 == length $peek ) {
                @{$self}{'_bodysz', '_hdrsz'} = unpack(
                    (0 == index($peek, 'B')) ? _BE_INIT_UNPACK() : _LE_INIT_UNPACK(),
                    $peek,
                );

                Protocol::DBus::Pack::align( $self->{'_hdrsz'}, 8 );

                $self->{'_msgsz'} = 16 + $self->{'_hdrsz'} + $self->{'_bodysz'};
            }
        }
        elsif (!$!{'EAGAIN'} && !$!{'EWOULDBLOCK'}) {
            die "recv(): $!";
        }
    }

    if (defined $self->{'_bodysz'} && !defined $self->{'_unix_fds'}) {
        if (defined recv( $self->{'_s'}, my $full_hdr, 16 + $self->{'_hdrsz'}, Socket::MSG_PEEK() )) {
            if ( length($full_hdr) == 16 + $self->{'_hdrsz'} ) {
                my ($hdr) = Protocol::DBus::Message::Header::parse_simple(\$full_hdr);

                $self->{'_unix_fds'} = $hdr->[6]{ Protocol::DBus::Message::Header::FIELD()->{'UNIX_FDS'} } || 0;

                $self->{'_pending_unix_fds'} = $self->{'_unix_fds'};

                my $body_sig = $hdr->[6]{ Protocol::DBus::Message::Header::FIELD()->{'SIGNATURE'} };

                if ($hdr->[4]) {
                    die "No SIGNATURE header field!" if !defined $body_sig;
                }
            }
        }
        elsif (!$!{'EAGAIN'} && !$!{'EWOULDBLOCK'}) {
            die "recv(): $!";
        }
    }

    if (defined $self->{'_unix_fds'}) {

        my $needed_bytes = $self->{'_msgsz'} - length $self->{'_buf'};

        my $got;

        if ($self->{'_unix_fds'}) {
            my $msg = Socket::MsgHdr->new(
                buflen => $needed_bytes,
            );

            # The unix FDs might arrive in a single control
            # message, as individual control messages, or as
            # some combination thereof. There is no way to know.
            # So plan for the worst, and assume each unix FD is
            # in its own control.
            $msg->cmsghdr( (SINGLE_UNIX_FD_CMSGHDR()) x $self->{'_pending_unix_fds'} );

            $got = Socket::MsgHdr::recvmsg( $self->{'_s'}, $msg );
            if (defined $got) {

                if ($self->{'_pending_unix_fds'}) {
                    require Protocol::DBus::Parser::UnixFDs;
                    push @{ $self->{'_filehandles'} }, Protocol::DBus::Parser::UnixFDs::extract_from_msghdr($msg);
                    $self->{'_pending_unix_fds'} = $self->{'_unix_fds'} - @{ $self->{'_filehandles'} };
                }

                $self->{'_buf'} .= $msg->buf();
            }
        }
        else {
            $got = sysread(
                $self->{'_s'},
                $self->{'_buf'},
                $needed_bytes,
                length $self->{'_buf'},
            );
        }

        if (defined $got) {
            if ($got >= $needed_bytes) {
                local $Protocol::DBus::Marshal::PRESERVE_VARIANT_SIGNATURES = 1 if $self->{'_preserve_variant_signatures'};

                # This clears out the buffer .. it should??
                my $msg = Protocol::DBus::Message->parse( \$self->{'_buf'}, delete $self->{'_filehandles'} );

                die "Not enough bytes??" if !$msg;

                delete @{$self}{'_bodysz', '_unix_fds'};

                return $msg;
            }
            elsif (!$got) {
                die "Peer stopped writing!";
            }
        }
        elsif (!$!{'EAGAIN'} && !$!{'EWOULDBLOCK'}) {
            die "recv(): $!";
        }
    }

    return undef;
}

sub preserve_variant_signatures {
    my $self = shift;

    if (@_) {
        $self->{'_preserve_variant_signatures'} = !!$_[0];
    }

    return !!$self->{'_preserve_variant_signatures'};
}

1;
