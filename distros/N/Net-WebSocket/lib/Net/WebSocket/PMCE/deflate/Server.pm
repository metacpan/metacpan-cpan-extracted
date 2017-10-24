package Net::WebSocket::PMCE::deflate::Server;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::WebSocket::PMCE::deflate::Server - permessage-deflate for a server

=head1 SYNOPSIS

    my $deflate = Net::WebSocket::PMCE::deflate::Server->new( %opts );

    #You’ll probably want Net::WebSocket::Handshake
    #to do this for you, but just in case:
    #$deflate->consume_parameters( @params_kv );

    #OPTIONAL: Inspect $deflate to be sure you’re happy with the setup
    #that the client’s parameters allow.

    #Send this to the client.
    my $handshake = $deflate->create_handshake_object();

    #...and now use this to send/receive messages.
    my $data_obj = $deflate->create_data_object();

=head1 DESCRIPTION

The above should describe the workflow sufficiently.

The optional “inspection” step is to ensure
that you’re satisfied with the compression parameters, which may be
different now from what you gave to the constructor.

For example, if you do this:

    my $deflate = Net::WebSocket::PMCE::deflate::Server->new(
        inflate_max_window_bits => 10,
    );

… and then this has no C<client_max_window_bits>:

    $deflate->consume_parameters( @extn_objs );

… then that means the client doesn’t understand C<client_max_window_bits>,
which means we can’t send that parameter. When this happens, C<$deflate>
changes to return 15 rather than 10 from its C<inflate_max_window_bits()>
method.

In general this should be fine, but if, for some reason, you want to
insist that the client compress with no more than 10 window bits,
then at this point you can fail the connection.

=back

=cut

use parent qw(
    Net::WebSocket::PMCE::deflate
);

use constant {
    _ENDPOINT_CLASS => 'Server',
    _PEER_NO_CONTEXT_TAKEOVER_PARAM => 'client_no_context_takeover',
    _LOCAL_NO_CONTEXT_TAKEOVER_PARAM => 'server_no_context_takeover',
    _DEFLATE_MAX_WINDOW_BITS_PARAM => 'server_max_window_bits',
    _INFLATE_MAX_WINDOW_BITS_PARAM => 'client_max_window_bits',
};

#----------------------------------------------------------------------

#=head1 METHODS
#
#This inherits all methods from L<Net::WebSocket::PMCE::deflate>
#and also supplies the following:
#
#=head2 I<OBJ>->peer_supports_client_max_window_bits()
#
#Call this after C<consume_peer_extensions()> to ascertain whether the
#client indicated support for the C<client_max_window_bits> parameter.
#
#=cut
#
#sub peer_supports_client_max_window_bits {
#    my ($self) = @_;
#    return $self->{'_peer_supports_client_max_window_bits'};
#}

#----------------------------------------------------------------------

#Remove once legacy support goes.
sub new {
    my ($class, @opts_kv) = @_;

    my $self = $class->SUPER::new(@opts_kv);

    $self->_warn_legacy() if $self->{'key'};

    return $self;
}

=head2 I<OBJ>->consume_parameters( KEY1 => VALUE1, .. )

Inherited from the base class. The alterations made in response
to the different parameters are:

=over

=item * <client_no_context_takeover> - Sets the object’s
C<inflate_no_context_takeover> flag.

=item * <server_no_context_takeover> - Sets the object’s
C<deflate_no_context_takeover> flag.

=item * <client_max_window_bits> - If given and less than the object’s
C<inflate_max_window_bits> option, then that option is reduced to the
new value.

=item * <server_max_window_bits> - If given and less than the object’s
C<deflate_max_window_bits> option, then that option is reduced to the
new value.

=back

=cut

sub _create_extension_header_parts {
    my ($self) = @_;

    local $self->{'inflate_max_window_bits'} = undef if !$self->{'_peer_supports_client_max_window_bits'};

    return $self->SUPER::_create_extension_header_parts();
}

sub _consume_extension_options {
    my ($self, $opts_hr) = @_;

    for my $ept_opt ( [ client => 'inflate' ], [ server => 'deflate' ] ) {
        my $mwb_opt = "$ept_opt->[0]_max_window_bits";

        if (exists $opts_hr->{$mwb_opt}) {
            if ($ept_opt->[0] eq 'client') {
                $self->{'_peer_supports_client_max_window_bits'} = 1;

                if (!defined $opts_hr->{$mwb_opt}) {
                    delete $opts_hr->{$mwb_opt};
                    next;
                }
            }

            my $self_opt = "$ept_opt->[1]_max_window_bits";
            $self->__validate_max_window_bits($ept_opt->[0], $opts_hr->{$mwb_opt});

            my $max = $self->{$self_opt} || ( $self->VALID_MAX_WINDOW_BITS() )[-1];

            if ($opts_hr->{$mwb_opt} < $max) {
                $self->{$self_opt} = $opts_hr->{$mwb_opt};
            }

            #If the client requested a greater server_max_window_bits than
            #we want, that’s no problem, but we’re just going to ignore it.

            delete $opts_hr->{$mwb_opt};
        }
    }

    for my $ept_opt ( [ client => 'inflate' ], [ server => 'deflate' ] ) {
        my $nct_hdr = "$ept_opt->[0]_no_context_takeover";

        if (exists $opts_hr->{$nct_hdr}) {
            $self->__validate_no_context_takeover( $ept_opt->[0], $opts_hr->{$nct_hdr} );

            $self->{"$ept_opt->[1]_no_context_takeover"} = 1;

            delete $opts_hr->{$nct_hdr};
        }
    }

    return;
}

1;
