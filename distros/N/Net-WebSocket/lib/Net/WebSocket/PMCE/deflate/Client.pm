package Net::WebSocket::PMCE::deflate::Client;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::WebSocket::PMCE::deflate::Client - permessage-deflate for a client

=head1 SYNOPSIS

    my $deflate = Net::WebSocket::PMCE::deflate::Server->new( %opts );

    #Send this to the server.
    my $handshake = $deflate->create_handshake_object();

    #You’ll probably want Net::WebSocket::Handshake
    #to do this for you, but just in case:
    #$deflate->consume_parameters( @params_kv );

    #OPTIONAL: Inspect $deflate to be sure you’re happy with the setup
    #that the client’s parameters allow.

    #...and now use this to send/receive messages.
    my $data_obj = $deflate->create_data_object();

=head1 DESCRIPTION

See L<Net::WebSocket::PMCE::deflate> for general information about
this class.

=head1 METHODS

=head2 I<OBJ>->consume_parameters( KEY1 => VALUE1, .. )

Inherited from the base class. The alterations made in response
to the different parameters are:

=over

=item * <client_no_context_takeover> - Sets the object’s
C<deflate_no_context_takeover> flag.

=item * <server_no_context_takeover> - If the object’s
C<inflate_no_context_takeover> flag is set, and if
we do *not* receive this flag from the peer, then we C<die()>.
This option is ignored otherwise.

=item * <client_max_window_bits> - If given and less than the object’s
C<deflate_max_window_bits> option, then that option is reduced to the
new value.

=item * <server_max_window_bits> - If given and less than the object’s
C<inflate_max_window_bits> option, then that option is reduced to the
new value. If given and B<greater> than the object’s
C<inflate_max_window_bits> option, then we C<die()>.

=back

=cut

use parent qw(
    Net::WebSocket::PMCE::deflate
);

use constant {
    _PEER_NO_CONTEXT_TAKEOVER_PARAM => 'server_no_context_takeover',
    _LOCAL_NO_CONTEXT_TAKEOVER_PARAM => 'client_no_context_takeover',
    _DEFLATE_MAX_WINDOW_BITS_PARAM => 'client_max_window_bits',
    _INFLATE_MAX_WINDOW_BITS_PARAM => 'server_max_window_bits',

    _ENDPOINT_CLASS => 'Client',
};

sub _create_extension_header_parts {
    my ($self) = @_;

    my @parts = $self->SUPER::_create_extension_header_parts();

    #Let’s always advertise support for this feature.
    if (!defined $self->{'deflate_max_window_bits'}) {
        push @parts, _DEFLATE_MAX_WINDOW_BITS_PARAM() => undef;
    }

    return @parts;
}

sub _consume_extension_options {
    my ($self, $opts_hr) = @_;

    if (exists $opts_hr->{'server_max_window_bits'}) {
        $self->__validate_max_window_bits('server', $opts_hr->{'server_max_window_bits'});

        if ( $opts_hr->{'server_max_window_bits'} > $self->inflate_max_window_bits() ) {
            die 'server_max_window_bits greater than client stipulated!';
        }

        $self->{'inflate_max_window_bits'} = $opts_hr->{'server_max_window_bits'};
        delete $opts_hr->{'server_max_window_bits'};
    }

    if (exists $opts_hr->{'client_max_window_bits'}) {
        $self->__validate_max_window_bits('client', $opts_hr->{'client_max_window_bits'});

        my $max = $self->deflate_max_window_bits();

        if ($opts_hr->{'client_max_window_bits'} < $max) {
            $self->{'deflate_max_window_bits'} = $opts_hr->{'client_max_window_bits'};
        }

        #If the server requested a greater client_max_window_bits than
        #we gave, that’s no problem, but we’re just going to ignore it.

        delete $opts_hr->{'client_max_window_bits'};
    }

    if (exists $opts_hr->{'client_no_context_takeover'}) {
        $self->__validate_no_context_takeover( $opts_hr->{'client_no_context_takeover'} );

        $self->{'deflate_no_context_takeover'} = 1;

        delete $opts_hr->{'client_no_context_takeover'};
    }

    if (exists $opts_hr->{'server_no_context_takeover'}) {
        $self->__validate_no_context_takeover( $opts_hr->{'server_no_context_takeover'} );
        delete $opts_hr->{'server_no_context_takeover'};
    }
    elsif ($self->{'inflate_no_context_takeover'}) {

        #The RFC doesn’t seem to have a problem with a server that
        #neglects a client’s server_no_context_takeover request.

        #die 'server didn’t accept server_no_context_takeover';

        delete $self->{'inflate_no_context_takeover'};
    }

    return;
}

1;
