package Net::WAMP::Session;

=encoding utf-8

=head1 NAME

Net::WAMP::Session

=head1 SYNOPSIS

    my $session = Net::WAMP::Session->new(

        #required
        on_send => sub { ... },

        #optional; default is 'json'
        serialization => 'msgpack',
    );

=head1 DISCUSSION

The only thing externally documented about these objects is that
they exist and how to instantiate them. A future refactor might
obscure this functionality entirely—e.g., if the Router functionality
of Net::WAMP becomes widely used.

Please do not use any of the methods on these objects directly,
as this interface is not at all meant to be stable.

=cut

use strict;
use warnings;

use Types::Serialiser ();

use Net::WAMP::Messages ();

sub new {
    my ($class, %opts) = @_;

    my @missing = grep { !$opts{$_} } qw( serialization  on_send );
    die 'Need “serialization”!' if !$opts{'serialization'};
    die 'Need “on_send”!' if !$opts{'serialization'};

    my $self = bless {
        _last_session_scope_id => 0,
        #_send_queue => [],
        _on_send => $opts{'on_send'},
    }, $class;

    $self->_set_serialization_format($opts{'serialization'});

    return $self;
}

sub send_message {
    $_[0]->{'_on_send'}->( $_[0]->message_object_to_bytes($_[1]) );
    return;
}

sub get_next_session_scope_id {
    my ($self) = @_;

    return ++$self->{'_last_session_scope_id'};
}

sub message_bytes_to_object {
    my ($self) = @_;

    my $array_ref = $self->_destringify($_[1]);

    my $type_num = shift(@$array_ref);
    my $type = Net::WAMP::Messages::get_type($type_num);

    return $self->_create_msg( $type, @$array_ref );
}

sub message_object_to_bytes {
    my ($self, $wamp_msg) = @_;

    return $self->_stringify( $wamp_msg->to_unblessed() );
}

sub set_peer_roles {
    my ($self, $peer_roles_hr) = @_;

    if ($self->{'_peer_roles'}) {
        die 'Already set peer roles!';
    }

    $self->{'_peer_roles'} = $peer_roles_hr;

    return;
}

sub peer_is {
    my ($self, $role) = @_;

    $self->_verify_peer_roles_set();

    return $self->{'_peer_roles'}{$role} ? 1 : 0;
}

sub peer_role_supports_boolean {
    my ($self, $role, $feature) = @_;

    die "Need role!" if !length $role;
    die "Need feature!" if !length $feature;

    $self->_verify_peer_roles_set();

    if ( my $brk = $self->{'_peer_roles'}{$role} ) {
        if ( my $features_hr = $brk->{'features'} ) {
            my $val = $features_hr->{$feature};
            return 0 if !defined $val;

            if (!$val->isa('Types::Serialiser::Boolean')) {
                die "“$role”/“$feature” ($val) is not a boolean value!";
            }

            return Types::Serialiser::is_true($val);
        }
    }

    return 0;
}

sub _verify_peer_roles_set {
    my ($self) = @_;

    die 'No peer roles set!' if !$self->{'_peer_roles'};

    return;
}

sub has_sent_GOODBYE {
    return $_[0]->{'_sent_GOODBYE'};
}

sub mark_sent_GOODBYE {
    my ($self) = @_;

    if ($self->{'_sent_GOODBYE'}) {
        die 'Already sent GOODBYE!';
    }

    $self->{'_sent_GOODBYE'} = 1;

    if ($self->{'_received_GOODBYE'}) {
        $self->{'_finished'} = 1;
    }

    return;
}

sub mark_received_GOODBYE {
    my ($self) = @_;

    $self->{'_received_GOODBYE'} = 1;

    if ($self->{'_sent_GOODBYE'}) {
        $self->{'_finished'} = 1;
    }

    return;
}

sub is_finished {
    return $_[0]->{'_finished'} ? 1 : undef;
}

#sub enqueue_message_to_send {
#    my ($self, $msg) = @_;
#
#    push @{ $self->{'_send_queue'} }, $msg;
#
#    return;
#}
#
#sub shift_message_queue {
#    my ($self, $msg) = @_;
#
#    return undef if !@{ $self->{'_send_queue'} };
#
#    return $self->message_object_to_bytes(
#        shift @{ $self->{'_send_queue'} },
#    );
#}

sub shutdown {
    $_[0]{'_is_shut_down'} = 1;
    return;
}

sub is_shut_down {
    return $_[0]{'_is_shut_down'};
}

sub get_serialization {
    my ($self) = @_;

    return $self->{'_serialization'};
}

sub get_websocket_data_type {
    my ($self) = shift;
    return $self->{'_serialization_module'}->websocket_data_type();
}

#----------------------------------------------------------------------

sub _set_serialization_format {
    my ($self, $serialization) = @_;

    my $ser_mod = "Net::WAMP::Serialization::$serialization";
    Module::Load::load($ser_mod) if !$ser_mod->can('stringify');

    $self->{'_serialization'} = $serialization;
    $self->{'_serialization_module'} = $ser_mod;

    return $self;
}

sub _serialization_is_set {
    my ($self) = @_;

    return $self->{'_serialization_module'} ? 1 : 0;
}

sub _stringify {
    my ($self) = shift;
    return $self->{'_serialization_module'}->can('stringify')->(@_);
}

sub _destringify {
    my ($self) = shift;
    return $self->{'_serialization_module'}->can('parse')->(@_);
}

#----------------------------------------------------------------------

#XXX De-duplicate TODO
sub _create_msg {
    my ($self, $name, @parts) = @_;

    my $mod = "Net::WAMP::Message::$name";
    Module::Load::load($mod) if !$mod->can('new');

    return $mod->new(@parts);
}

#----------------------------------------------------------------------

1;
