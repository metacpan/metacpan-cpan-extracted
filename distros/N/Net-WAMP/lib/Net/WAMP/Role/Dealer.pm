package Net::WAMP::Role::Dealer;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::WAMP::Role::Dealer - Dealer role for Net::WAMP

=head1 SYNOPSIS

    package MyRouter;

    use parent qw( Net::WAMP::Role::Dealer );

    #For security, this defaults to rejecting everything!
    sub deny_CALL {
        my ($self, $CALL_msg) = @_;

        my $session_obj = $self->get_session();

        #success
        return;

        #fail, generic (Error = wamp.error.not_authorized)
        return 1;

        #fail, custom Auxiliary (Error = wamp.error.not_authorized)
        return { foo => 1 };

        #fail, generic Auxiliary, custom Error
        return 1, 'myapp.error.go_away';

        #fail, custom Auxiliary and Error
        return { foo => 1 }, 'myapp.error.go_away';
    }

    #This follows the same pattern as deny_CALL().
    #It also defaults to rejecting everything.
    sub deny_REGISTER { ... }

=head1 DESCRIPTION

This is an B<EXPERIMENTAL> WAMP Dealer implementation. If you use it,
please send feedback!

=head1 AUTHORIZATION

To have a useful Dealer you’ll need to create a C<deny_CALL> method,
since the default is to deny all CALL requests.
If that Broker is to allow REGISTER requests, you’ll also need a
C<deny_REGISTER()> method. The format of these is described above.

=head1 METHODS

Dealer only exposes a few public methods:

=head2 $registr_id = I<OBJ>->register( SESSION_OBJ, METADATA_HR, PROCEDURE )

This function registers a session to supply the given procedure,
independently of actual WAMP
messaging. This is useful, e.g., if you want to “auto-register” a
procedure to a given session.

The return is the same number that is sent in a REGISTERED message’s
C<Registration>. No REGISTERED message is sent, however.

=head2 I<OBJ>->unregister( SESSION_OBJ, REGISTRATION_ID )

Undoes a registration, without sending an UNREGISTERED message.

=cut

use Try::Tiny;

use parent qw(
    Net::WAMP::Role::Base::Router
);

use Types::Serialiser ();

use Net::WAMP::Role::Base::Router::Features ();
use Net::WAMP::X ();

use constant {
    deny_CALL => 1,
    deny_REGISTER => 1,

    receiver_role_of_REGISTERED => 'callee',
    receiver_role_of_UNREGISTERED => 'callee',
    receiver_role_of_INVOCATION => 'callee',
    receiver_role_of_INTERRUPT => 'callee',
    receiver_role_of_RESULT => 'caller',
};

BEGIN {
    $Net::WAMP::Role::Base::Router::Features::FEATURES{'dealer'}{'features'}{'call_canceling'} = $Types::Serialiser::true;
    $Net::WAMP::Role::Base::Router::Features::FEATURES{'dealer'}{'features'}{'progressive_call_results'} = $Types::Serialiser::true;
}

#----------------------------------------------------------------------

sub register {
    my ($self, $session, $options, $procedure) = @_;

    $self->_validate_uri($procedure);

    if ( $self->_procedure_is_in_state($session, $procedure) ) {
        my $realm = $self->_get_realm_for_session($session);
        die Net::WAMP::X->create('ProcedureAlreadyExists', $realm, $procedure);
    }

    #XXX: It’s less than ideal to store an actual Perl object in _state
    #because it more or less ties us to the in-memory datastore.
    $self->{'_state'}->set_realm_property(
        $session,
        "procedure_session_$procedure",
        $session,
    );

    #unused? See advanced
    $self->{'_state'}->set_realm_property(
        $session,
        "procedure_options_$procedure",
        $options,
    );

    my $registration = Net::WAMP::Utils::generate_global_id();

    #CALL needs to look it up this way.
    $self->{'_state'}->set_realm_property(
        $session,
        "procedure_registration_$procedure",
        $registration,
    );

    #UNREGISTER needs to look it up this way.
    $self->{'_state'}->set_realm_property(
        $session,
        "registration_procedure_$registration",
        $procedure,
    );

    return $registration;
}

sub _procedure_is_in_state {
    my ($self, $session, $procedure) = @_;

    return !!$self->{'_state'}->get_realm_property($session, "procedure_registration_$procedure");
}

sub unregister {
    my ($self, $session, $registration) = @_;

    my $procedure = $self->{'_state'}->unset_realm_property($session, "registration_procedure_$registration");
    if (!defined $procedure) {
        my $realm = $self->_get_realm_for_session($session);
        die Net::WAMP::X->create('NoSuchRegistration', $realm, $registration);
    }

    for my $k (
        "procedure_session_$procedure",
        "procedure_options_$procedure",
        "procedure_registration_$procedure",
    ) {
        $self->{'_state'}->unset_realm_property( $session, $k );
    }

    return;
}

#----------------------------------------------------------------------
# Subclass interface:
#
# Must implement:
#   - handle_REGISTER($msg) - responsible for send_REGISTERED()
#   - handle_UNREGISTER($msg) - must send_UNREGISTERED()
#----------------------------------------------------------------------

sub _receive_REGISTER {
    my ($self, $msg) = @_;

    return $self->_catch_exception(
        'REGISTER',
        $msg->get('Request'),
        sub {
            my ($opts, $proc) = map { $msg->get($_) } qw( Options Procedure );

            my ($meta_hr, $error) = $self->deny_REGISTER($msg);
            if ($meta_hr) {
                $self->_create_and_send_ERROR(
                    'REGISTER',
                    $msg->get('Request'),
                    ref($meta_hr) ? $meta_hr : {},
                    $error || 'wamp.error.not_authorized',
                );
                return;
            }

            my $reg_id;
            try {
                $reg_id = $self->register($self->{'_session'}, $opts, $proc);
                $self->_send_REGISTERED( $msg->get('Request'), $reg_id );
            }
            catch {
                if ( try { $_->isa('Net::WAMP::X::ProcedureAlreadyExists') } ) {
                    $self->_create_and_send_ERROR(
                        'REGISTER',
                        $msg->get('Request'),
                        {
                            net_wamp_message => $_->get_message(),
                        },
                        'wamp.error.procedure_already_exists',
                    );
                }
                elsif ( try { $_->isa('Net::WAMP::X::BadURI') } ) {
                    $self->_create_and_send_ERROR(
                        'REGISTER',
                        $msg->get('Request'),
                        {
                            net_wamp_message => $_->get_message(),
                        },
                        'wamp.error.invalid_uri',
                    );
                }
                else {
                    local $@ = $_;
                    die;
                }
            };

            return $reg_id;
        },
    );
}

sub _send_REGISTERED {
    my ($self, $req_id, $reg_id) = @_;

    return $self->_create_and_send_msg(
        'REGISTERED',
        $req_id,
        $reg_id,
    );
}

sub _receive_UNREGISTER {
    my ($self, $msg) = @_;

    $self->_catch_exception(
        'UNREGISTER',
        $msg->get('Request'),
        sub {

            try {
                $self->unregister( $self->{'_session'}, $msg->get('Registration') );
                $self->send_UNREGISTERED( $msg->get('Request') );
            }
            catch {
                if ( try { $_->isa('Net::WAMP::X::NoSuchRegistration') } ) {
                    $self->_create_and_send_ERROR(
                        'UNREGISTER',
                        $msg->get('Request'),
                        {
                            net_wamp_message => $_->get_message(),
                        },
                        'wamp.error.no_such_registration',
                    );
                }
                else {
                    local $@ = $_;
                    die;
                }
            };
        },
    );

    return;
}

sub send_UNREGISTERED {
    my ($self, $req_id) = @_;

    return $self->_create_and_send_msg(
        'UNREGISTERED',
        $req_id,
    );
}

sub _receive_CALL {
    my ($self, $msg) = @_;

    #TODO: validate

    my $procedure = $msg->get('Procedure') or do {
        die "Need “Procedure”!";
    };

    return if !$self->_validate_uri_or_send_ERROR(
        $procedure,
        'CALL',
        $msg->get('Request'),
    );

    my ($meta_hr, $error) = $self->deny_CALL($msg);
    if ($meta_hr) {
        $self->_create_and_send_ERROR(
            'CALL',
            $msg->get('Request'),
            ref($meta_hr) ? $meta_hr : {},
            $error || 'wamp.error.not_authorized',
        );
        return;
    }

    my $target_session = $self->{'_state'}->get_realm_property(
        $self->{'_session'},
        "procedure_session_$procedure",
    );

    if (!$target_session) {
        $self->_create_and_send_ERROR(
            'CALL',
            $msg->get('Request'),
            {},
            'wamp.error.no_such_procedure',
        );
        return;
    }

    my $registration = $self->{'_state'}->get_realm_property(
        $self->{'_session'},
        "procedure_registration_$procedure",
    );

    my $msg2 = do {
        local $self->{'_session'} = $target_session;

        $self->_send_INVOCATION(
            $registration,
            $msg->get('Auxiliary'),
            $msg->get('Arguments'),
            $msg->get('ArgumentsKw'),
        );
    };

    $self->{'_state'}->set_session_property(
        $target_session,
        'invocation_call_req_id_' . $msg2->get('Request'),
        $msg->get('Request'),
    );

    #XXX: It’s less than ideal to store an actual Perl object in _state
    #because it more or less ties us to the in-memory datastore.
    $self->{'_state'}->set_session_property(
        $target_session,
        'invocation_call_session_' . $msg2->get('Request'),
        $self->{'_session'},
    );

    #Used for CANCEL--------------------------------------------------
    $self->{'_state'}->set_session_property(
        $self->{'_session'},
        'call_invocation_req_id_' . $msg->get('Request'),
        $msg2->get('Request'),
    );

    #XXX: It’s less than ideal to store an actual Perl object in _state
    #because it more or less ties us to the in-memory datastore.
    $self->{'_state'}->set_session_property(
        $self->{'_session'},
        'call_invocation_session_' . $msg->get('Request'),
        $target_session,
    );
    #-----------------------------------------------------------------

    return;
}

sub _clear_call_invocation {
    my ($self, $session, $orig_req_id) = @_;

    my $target_session = $self->{'_state'}->unset_session_property(
        $session,
        "call_invocation_session_$orig_req_id",
    );

    my $target_req_id = $self->{'_state'}->unset_session_property(
        $session,
        "call_invocation_req_id_$orig_req_id",
    );

    return ($target_req_id, $target_session);
}

#As of now, only a Dealer can receive an ERROR, so there’s no risk of
#conflict with Broker.
sub _receive_ERROR_INVOCATION {
    my ($self, $msg) = @_;

    my $invoc_req_id = $msg->get('Request');

    my ($orig_req_id, $orig_session) = $self->_get_invocation_call_req_and_session(
        'unset_session_property',
        $self->{'_session'},
        $invoc_req_id,
    );

    if ($orig_req_id) {
        $self->_clear_call_invocation($orig_session, $orig_req_id);

        local $self->{'_session'} = $orig_session;

        $self->_create_and_send_ERROR(
            'CALL',
            $orig_req_id,
            ( map { $msg->get($_) } qw( Auxiliary Error Arguments ArgumentsKw ) ),
        );
    }
    elsif ($msg->{'Error'} ne 'wamp.error.canceled') {
        die "ERROR/INVOCATION (not wamp.error.canceled) that references a CALL we don’t have in state!";   #XXX drop connection? protocol error
    }

    return;
}

sub _send_INVOCATION {
    my ($self, $reg_id, $details, $args_ar, $args_hr) = @_;

    return $self->_create_and_send_session_msg(
        'INVOCATION',
        $reg_id,
        $details,
        ( $args_ar ? ( $args_ar, $args_hr || () ) : () ),
    );
}

sub _get_invocation_call_req_and_session {
    my ($self, $access_method, $session, $invoc_req_id) = @_;

    my $orig_req_id = $self->{'_state'}->$access_method(
        $session,
        "invocation_call_req_id_$invoc_req_id",
    );

    if (!defined $orig_req_id) {
        die "Unrecognized YIELD request ID ($invoc_req_id)!"
    }

    my $orig_session = $self->{'_state'}->$access_method(
        $session,
        "invocation_call_session_$invoc_req_id",
    );

    return ($orig_req_id, $orig_session);
}

sub _receive_YIELD {
    my ($self, $msg) = @_;

    my $invoc_req_id = $msg->get('Request');

    my $access_method = $msg->is_progress() ? 'get_session_property' : 'unset_session_property';

    my ($orig_req_id, $orig_session) = $self->_get_invocation_call_req_and_session(
        $access_method,
        $self->{'_session'},
        $invoc_req_id,
    );

    $self->_clear_call_invocation($self->{'_session'}, $orig_req_id);

    local $self->{'_session'} = $orig_session;

    $self->_send_RESULT(
        $orig_req_id,
        $msg->get('Auxiliary'),
        $msg->get('Arguments'),
        $msg->get('ArgumentsKw'),
    );

    return;
}

sub _send_RESULT {
    my ($self, $req_id, $details, $args_ar, $args_hr) = @_;

    return $self->_create_and_send_msg(
        'RESULT',
        $req_id,
        $details,
        ( $args_ar ? ( $args_ar, $args_hr || () ) : () ),
    );
}

sub _receive_CANCEL {
    my ($self, $msg) = @_;

    my ($target_req_id, $target_session) = $self->_clear_call_invocation(
        $self->{'_session'},
        $msg->get('Request'),
    );

    $self->_create_and_send_ERROR(
        'CALL',
        $msg->get('Request'),
        {},
        'wamp.error.canceled',
    );

    #The above will have set this to 1.
    $self->{'_prevent_custom_handler'} = 0;

    #XXX TODO
    if (!$target_req_id) {
        die sprintf "No such (%s)!", $msg->get('Request');
    }

#Needed? Could wait for the ERROR response …
#XXX Memory leak attack?
#
#    $self->_get_invocation_call_req_and_session(
#        'unset_session_property',
#        $session,
#        $target_req_id,
#    );

    local $self->{'_session'} = $target_session;

    $self->_create_and_send_msg(
        'INTERRUPT',
        $target_req_id,
        $msg->get('Auxiliary'),
    );

    return;
}

1;
