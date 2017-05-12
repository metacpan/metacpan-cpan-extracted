package Net::WAMP::Role::Base::Client;

use strict;
use warnings;

use Module::Load ();

use parent qw( Net::WAMP::Role::Base::Peer );

use Net::WAMP::Session ();

use Net::WAMP::Role::Base::Client::Features ();
use Net::WAMP::X ();

use constant PEER_CAN_ACCEPT => (
    __PACKAGE__->SUPER::PEER_CAN_ACCEPT(),
    'HELLO',
);

use constant {
    DEFAULT_GOODBYE_REASON => 'wamp.error.close_realm',
};

sub send_HELLO {
    my ($self, $realm, $details_hr_in) = @_;

    my $details_hr = $self->GET_DETAILS_HR();

    if ($details_hr_in) {
        Module::Load::load('Hash::Merge');
        $details_hr = Hash::Merge::merge( $details_hr, $details_hr_in );
    }



    return $self->_create_and_send_msg( 'HELLO', $realm, $details_hr );
}

#Subclasses can safely override. They’ll probably want to call into
#this one as well and Hash::Merge their contents.
sub GET_DETAILS_HR {
    my ($self) = @_;

    my $details_hr = {
        roles => \%Net::WAMP::Role::Base::Client::Features::FEATURES,
    };

    if (my $agent = $self->get_agent_string()) {
        $details_hr->{'agent'} = $agent;
    }

    return $details_hr;
}

#----------------------------------------------------------------------

sub _receive_WELCOME {
    my ($self, $msg) = @_;

    if ( $self->{'_got_WELCOME'} ) {
        $self->_ABORT_from_protocol_error('duplicate WELCOME');
    }
    else {
        $self->{'_got_WELCOME'} = 1;

        my $roles_hr = $msg->get('Details')->{'roles'};
        if (!$roles_hr) {
            $self->_ABORT_from_protocol_error('missing “Details.roles”');
        }
        else {
            if ( $self->{'_session_id'} = $msg->get('Session') ) {
                $self->{'_session'}->set_peer_roles($roles_hr);
                $self->{'_handshake_done'} = 1;
            }
            else {
                $self->_ABORT_from_protocol_error('missing “Session”');
            }
        }
    }

    return;
}

#----------------------------------------------------------------------
# The below were originally in Peer.pm …
#----------------------------------------------------------------------

#serialization
sub new {
    my ($class, %opts) = @_;

    my $self = {
        _session => Net::WAMP::Session->new(%opts),
    };

    return bless $self, $class;
}

#----------------------------------------------------------------------

sub _check_peer_roles_before_send {
    my ($self, $msg) = @_;

    #cache
    if ($self->REQUIRE_STRICT_PEER_ROLES()) {
        $self->{'_peer_groks_msg'}{$msg->get_type()} ||= do {
            $self->_verify_receiver_can_accept_msg_type($msg->get_type());
            1;
        };
    }

    return;
}

1;
