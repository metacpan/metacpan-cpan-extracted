package Net::WAMP::Role::Base::Router;

use strict;
use warnings;

use Try::Tiny;

use parent qw(
    Net::WAMP::Role::Base::Peer
    Net::WAMP::Role::Base::CanError
);

use Module::Load ();

use Net::WAMP::Messages ();
use Net::WAMP::Utils ();

use constant STATE_OBJ_CLASS => 'Net::WAMP::Role::Base::Router::State::Memory';

use constant PEER_CAN_ACCEPT => (
    __PACKAGE__->SUPER::PEER_CAN_ACCEPT(),
    'WELCOME',
);

sub new {
    my ($class, $state_obj) = @_;

    my $state_obj_class = $class->STATE_OBJ_CLASS();

    $state_obj ||= do {
        Module::Load::load($state_obj_class);
        $state_obj_class->new();
    };

    return bless {
        _state => $state_obj,
    }, $class;
}

sub handle_message {
    my ($self, $session) = @_;  #also $serialized_msg

    #This works because each individual message handling instance
    #treats a single peer.
    local $self->{'_session'} = $session;

    return $self->SUPER::handle_message(@_[ 2 .. $#_ ]);
}

sub forget_session {
    my ($self, $session) = @_;

    $self->{'_state'}->forget_session($session);
    delete $self->{'_session_peer_groks_msg'}{$session};

    return;
}

sub send_ABORT {
    my ($self, $session, $details, $reason) = @_;

    local $self->{'_session'} = $session;

    my $msg = $self->SUPER::send_GOODBYE( $details, $reason );

    $self->forget_session($session);

    return $msg;
}

sub send_GOODBYE {
    my ($self, $session, $details, $reason) = @_;

    local $self->{'_session'} = $session;

    return $self->SUPER::send_GOODBYE( $details, $reason );
}

#Subclasses can safely override. They’ll probably want to call into
#this one as well and Hash::Merge their contents.
sub GET_DETAILS_HR {
    my ($self) = @_;

    my $details_hr = {
        roles => \%Net::WAMP::Role::Base::Router::Features::FEATURES,
    };

    if (my $agent = $self->get_agent_string()) {
        $details_hr->{'agent'} = $agent;
    }

    return $details_hr;
}

sub get_session {
    return $_[0]->{'_session'};
}

#----------------------------------------------------------------------

sub _get_realm_for_session {
    my ($self, $session) = @_;

    return $self->{'_state'}->get_realm_for_session($session);
}

sub _receive_HELLO {
    my ($self, $msg) = @_;

    return if !$self->_catch_pre_handshake_exception(
        sub {
            my $protocol_error;

            if ($self->{'_state'}->session_exists($self->{'_session'})) {
                $protocol_error = 'second HELLO';
            }
            elsif ( !length $msg->get('Realm') ) {
                $protocol_error = 'missing “Realm”';
            }
            else {
                my $roles_hr = $msg->get('Details')->{'roles'};

                if (!$roles_hr || !%$roles_hr) {
                    $protocol_error = 'missing “Details.roles”';
                }
                else {
                    my ($meta_hr, $error) = $self->deny_HELLO($msg);
                    if ($meta_hr) {
                        $self->send_ABORT(
                            $self->{'_session'},
                            ref($meta_hr) ? $meta_hr : {},
                            $error || 'wamp.error.not_authorized',
                        );
                        return;
                    }

                    $self->{'_state'}->add_session(
                        $self->{'_session'},
                        $msg->get('Realm'),
                    );

                    $self->{'_session'}->set_peer_roles($roles_hr);

                    return 1;
                }
            }

            $self->send_ABORT(
                $self->{'_session'},
                { message => $protocol_error },
                'net_wamp.protocol_error',
            );

            return;
        },
    );

    my $session_id = Net::WAMP::Utils::generate_global_id();

    $self->{'_state'}->set_session_property(
        $self->{'_session'},
        'session_id',
        $session_id,
    );

    $self->_send_WELCOME($session_id);

    return;
}

sub _send_WELCOME {
    my ($self, $session_id) = @_;

    my $details_hr = $self->GET_DETAILS_HR();

    my $msg = $self->_create_and_send_msg(
        'WELCOME',
        $session_id,
        $details_hr,
    );

    return $msg;
}

sub _receive_GOODBYE {
    my ($self, $msg) = @_;

    $self->{'_state'}->forget_session($self->{'_session'});

    if (!$self->{'_session'}->is_shut_down()) {
        $self->SUPER::send_GOODBYE(
            $msg->get('Details'),
            $msg->get('Reason'),
        );
    }

    return $self;
}

#----------------------------------------------------------------------
# The actual logic to change router state is exposed publicly for the
# sake of applications that may want a “default” router configuration.



#----------------------------------------------------------------------

sub _check_peer_roles_before_send {
    my ($self, $msg) = @_;

    my $session = $self->{'_session'};

    #cache
    if ($self->REQUIRE_STRICT_PEER_ROLES()) {
        $self->{'_session_peer_groks_msg'}{$session}{$msg->get_type()} ||= do {
            $self->_verify_receiver_can_accept_msg_type($msg->get_type());
            1;
        };
    }
}

#----------------------------------------------------------------------

sub _catch_pre_handshake_exception {
    my ($self, $todo_cr) = @_;

    my $ret;

    try {
        $ret = $todo_cr->();
    }
    catch {
        $self->_create_and_send_msg(
            'ABORT',
            {
                message => "$_",
            },
            'net_wamp.error',
        );

        if ($self->{'_state'}->session_exists($self->{'_session'})) {
            $self->{'_state'}->forget_session($self->{'_session'});
        }
    };

    return $ret;
}

sub _validate_uri_or_send_ERROR {
    my ($self, $specimen, $subtype, $req_id) = @_;

    my $ok;
    try {
        $self->_validate_uri($specimen);
        $ok = 1;
    }
    catch {
        $self->_create_and_send_ERROR(
            $subtype,
            $req_id,
            {
                net_wamp_message => $_->get_message(),
            },
            'wamp.error.invalid_uri',
        );
    };

    return $ok;
}

#----------------------------------------------------------------------
#XXX Copy/paste …

#sub _peer_is {
#    my ($self, $session, $role) = @_;
#
#    $self->_verify_handshake();
#
#    return $self->{'_state'}->get_session_property($session, 'peer_roles')->{$role} ? 1 : 0;
#}
#
#sub _peer_role_supports_boolean {
#    my ($self, $session, $role, $feature) = @_;
#
#    die "Need role!" if !length $role;
#    die "Need feature!" if !length $feature;
#
#    $self->_verify_handshake();
#
#    my $peer_roles = $self->{'_state'}->get_session_property($session, 'peer_roles');
#
#    if ( my $rolfeat = $peer_roles->{$role} ) {
#        if ( my $features_hr = $rolfeat->{'features'} ) {
#            my $val = $features_hr->{$feature};
#            return 0 if !defined $val;
#
#            if (!$val->isa('Types::Serialiser::Boolean')) {
#                die "“$role”/“$feature” ($val) is not a boolean value!";
#            }
#
#            return $val ? 1 : 0;
#        }
#    }
#
#    return 0;
#}

1;
