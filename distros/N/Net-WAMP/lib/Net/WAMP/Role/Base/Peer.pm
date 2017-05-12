package Net::WAMP::Role::Base::Peer;

use strict;
use warnings;

use Module::Load ();

use constant REQUIRE_STRICT_PEER_ROLES => 1;

use constant PEER_CAN_ACCEPT => qw( GOODBYE  ABORT  ERROR );

#----------------------------------------------------------------------

sub handle_message {
    my ($self) = @_;

    my $msg = $self->{'_session'}->message_bytes_to_object($_[1]);

    my ($handler_cr, $handler2_cr) = $self->_get_message_handlers($msg);

    local $self->{'_prevent_custom_handler'};

    my @extra_args = $handler_cr->( $self, $msg );

    #Check for external method definition
    if (!$self->{'_prevent_custom_handler'} && $handler2_cr) {
        $handler2_cr->( $self, $msg, @extra_args );
    }

    return $msg;
}

sub send_GOODBYE {
    my ($self, $details_hr, $reason) = @_;

    $reason ||= $self->DEFAULT_GOODBYE_REASON();

    $self->{'_session'}->mark_sent_GOODBYE();

    my $msg = $self->_create_and_send_msg( 'GOODBYE', $details_hr, $reason );

    return $msg;
}

sub send_ABORT {
    my ($self, $details_hr, $reason) = @_;

    return $self->_create_and_send_msg( 'ABORT', $details_hr, $reason );
}

sub get_agent_string { return ref $_[0] }

#----------------------------------------------------------------------

sub _receive_GOODBYE {
    my ($self, $msg) = @_;

    $self->{'_session'}->mark_received_GOODBYE();

    if (!$self->{'_session'}->has_sent_GOODBYE()) {
        $self->send_GOODBYE(
            $msg->get('Details'),
            'wamp.error.goodbye_and_out',
        );
    }

    return $self;
}

sub _receive_ERROR {
    my ($self, $msg) = @_;

    my $subtype = $msg->get_request_type();
    my $subhandler_n = "_receive_ERROR_$subtype";

    return $self->$subhandler_n($msg);
}

sub _ABORT_from_protocol_error {
    my ($self, $msg) = @_;

    $self->send_ABORT(
        {
            ( $msg ? (message => $msg) : () ),
        },
        'net_wamp.protocol_error',
    );
}

sub _send_msg {
    my ($self, $msg) = @_;

    if ($self->{'_session'}->is_finished()) {
        die "Session ($self->{'_session'}) is already finished!";
    }

    $self->_check_peer_roles_before_send($msg);

    $self->{'_session'}->send_message($msg);

    return $self;
}

sub _create_and_send_msg {
    my ($self, $name, @parts) = @_;

    #This is in Peer.pm
    my $msg = $self->_create_msg($name, @parts);

    $self->_send_msg($msg);

    return $msg;
}

sub _create_and_send_session_msg {
    my ($self, $name, @parts) = @_;

    #This is in Peer.pm
    my $msg = $self->_create_msg(
        $name,
        $self->{'_session'}->get_next_session_scope_id(),
        @parts,
    );

    $self->_send_msg($msg);

    return $msg;
}

sub _get_message_handlers {
    my ($self, $msg) = @_;

    #$self->_verify_handshake();

    my $type = $msg->get_type();

    my $handler_cr = $self->can("_receive_$type");
    if (!$handler_cr) {
        die "“$self” received a message of type “$type” but cannot handle messages of this type!";
    }

    my $handler2_cr = $self->can("on_$type");

    return ($handler_cr, $handler2_cr);
}

sub _verify_handshake {
    my ($self) = @_;

    die "Need WAMP handshake first!" if !$self->{'_handshake_done'};

    return;
}

#or else send “wamp.error.invalid_uri”
#WAMP’s specification gives: re.compile(r"^([^\s\.#]+\.)*([^\s\.#]+)$")

sub _validate_uri {
    my ($self, $specimen) = @_;

    if ($specimen =~ m<\.\.>o) {
        die Net::WAMP::X->create('BadURI', 'empty URI component', $specimen);
    }

    if (0 == index($specimen, '.')) {
        die Net::WAMP::X->create('BadURI', 'initial “.”', $specimen);
    }

    if (substr($specimen, -1) eq '.') {
        die Net::WAMP::X->create('BadURI', 'trailing “.”', $specimen);
    }

    if ($specimen =~ tr<#><>) {
        die Net::WAMP::X->create('BadURI', '“#” is forbidden', $specimen);
    }

    #XXX https://github.com/wamp-proto/wamp-proto/issues/275
    if ($specimen =~ m<\s>o) {
        die Net::WAMP::X->create('BadURI', 'Whitespace is forbidden.', $specimen);
    }

    return;
}

#XXX De-duplicate TODO
sub _create_msg {
    my ($self, $name, @parts) = @_;

    my $mod = "Net::WAMP::Message::$name";
    Module::Load::load($mod) if !$mod->can('new');

    return $mod->new(@parts);
}

#This happens during handshake.
sub _receive_ABORT {
    my ($self, $msg) = @_;

    require Data::Dumper;
    warn Data::Dumper::Dumper('received ABORT', $msg);

    #die "$msg: " . $self->_stringify($msg);   #XXX

    return;
}

sub _verify_receiver_can_accept_msg_type {
    my ($self, $msg_type) = @_;

    my $session = $self->{'_session'};

    if (!grep { $_ eq $msg_type } $self->PEER_CAN_ACCEPT()) {
        my $role;

        my $cr = $self->can("receiver_role_of_$msg_type") or do {
            die "I don’t know what role accepts “$msg_type” messages!";
        };

        $role = $cr->();

        if (!$session->peer_is( $role )) {
            die Net::WAMP::X->create(
                'PeerLacksMessageRecipientRole',
                $msg_type,
                $role,
            );
        }

        if (my $cr = $self->can("receiver_feature_of_$msg_type")) {
            if (!$session->peer_role_supports_boolean( $role, $cr->() )) {
                my $feature_name = $cr->();
                die Net::WAMP::X->create(
                    'PeerLacksMessageRecipientFeature',
                    $msg_type,
                    $feature_name,
                );
            }
        }
    }

    return;
}

1;
