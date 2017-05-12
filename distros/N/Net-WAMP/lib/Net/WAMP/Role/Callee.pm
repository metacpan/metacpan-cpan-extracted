package Net::WAMP::Role::Callee;

=encoding utf-8

=head1 NAME

Net::WAMP::Role::Caller - Caller role for Net::WAMP

=head1 SYNOPSIS

    package MyWAMP;

    use parent qw( Net::WAMP::Role::Callee );

    sub on_REGISTERED {
        my ($self, $REGISTERED_msg) = @_;
        ...
    }

    sub on_ERROR_REGISTER {
        my ($self, $ERROR_msg, $REGISTER_msg) = @_;
        ...
    }

    sub on_UNREGISTERED {
        my ($self, $UNREGISTERED_msg) = @_;
        ...
    }

    sub on_ERROR_UNREGISTER {
        my ($self, $ERROR_msg, $UNREGISTER_msg) = @_;
        ...
    }

    #----------------------------------------------------------------------

    #NB: The appropriate ERROR message will already have been sent.
    sub on_INTERRUPT {
        my ($self, $INTERRUPT_msg, $interrupter) = @_;

        ...

        #This is optional, useful if you want to return specific
        #information about the interrupted process (e.g., output thus far):
        $interrupter->send_ERROR( {}, \@args, \%args_kw );

        ...
    }

    #----------------------------------------------------------------------

    #See below about $worker_obj:
    sub on_INVOCATION {
        my ($self, $msg, $worker_obj) = @_;
    }

    #----------------------------------------------------------------------

    package main;

    my $wamp = MyWAMP->new( on_send => sub { ... } );

    my $reg_msg = $wamp->send_REGISTER( {}, 'some.procedure.name' );

    $wamp->send_UNREGISTER( $reg_msg->get('Registration') );

    $wamp->send_UNREGISTER_for_procedure( 'some.procedure.name' );

    #This method returns the original REGISTER message object.
    $wamp->get_REGISTER( $INVOCATION_msg );
    $wamp->get_REGISTER( $registration_id );

    #This method returns an INVOCATION object.
    $wamp->get_INVOCATION( $msg );  #e.g., an ERROR or INTERRUPT
    $wamp->get_INVOCATION( $request_id );

    #You *can* do this, but the worker object makes this easier:
    $wamp->send_YIELD( $req_id, {}, \@args, \%args_kv );
    $wamp->send_ERROR( $req_id, {}, $err_uri, \@args, \%args_kv );

=head1 DESCRIPTION

Callee is the most complex client class to implement.

The registration stuff follows a straightforward pattern. To answer
INVOCATION messages, a special L<Net::WAMP::RPCWorker> class exists
to simplify the work a bit.

=head1 ANSWERING INVOCATION MESSAGES

As in the SYNOPSIS above, you’ll create a C<on_INVOCATION()> method on
your Callee class. That method will accept the arguments shown;
C<$worker_obj> is an instance of L<Net::WAMP::RPCWorker>. This special
subclass maintains the state of the request and should make life a bit
simpler when implementing a Callee.

It is suggested that, for long-running calls,
Callee implementations C<fork()> in their C<on_INVOCATION()>, with
the child sending the response data back to the parent process, which
will then send the data into the RPCWorker object, where it will
end up serialized and ready to send back to the router. There is an
implementation of this in the Net::WAMP distribution’s demos.

=cut

use strict;
use warnings;

use parent qw(
    Net::WAMP::Role::Base::Client
    Net::WAMP::Role::Base::CanError
);

use Types::Serialiser ();

use Net::WAMP::Role::Base::Client::Features ();
use Net::WAMP::RPCWorker ();

use constant {
    receiver_role_of_REGISTER => 'dealer',
    receiver_role_of_UNREGISTER => 'dealer',
    receiver_role_of_YIELD => 'dealer',

    RPCWorker_class => 'Net::WAMP::RPCWorker',
};

BEGIN {
    $Net::WAMP::Role::Base::Client::Features::FEATURES{'callee'}{'features'}{'call_canceling'} = $Types::Serialiser::true;
    $Net::WAMP::Role::Base::Client::Features::FEATURES{'callee'}{'features'}{'progressive_call_results'} = $Types::Serialiser::true;
}

#----------------------------------------------------------------------

sub send_REGISTER {
    my ($self, $opts_hr, $uri) = @_;

    my $msg = $self->_create_and_send_session_msg(
        'REGISTER',
        $opts_hr,
        $uri,
    );

    return $self->{'_sent_REGISTER'}{$msg->get('Request')} = $msg;
}

sub _receive_ERROR_REGISTER {
    my ($self, $msg) = @_;

    my $orig_msg = $self->{'_sent_REGISTER'}{$msg->get('Request')};
    if (!$orig_msg) {
        warn sprintf 'No tracked REGISTER for request ID “%s”!', $msg->get('Request');
    }

    return $orig_msg;
}

sub _receive_REGISTERED {
    my ($self, $msg) = @_;

    my $req_id = $msg->get('Request');

    my $orig_reg = delete $self->{'_sent_REGISTER'}{ $req_id };

    #This likely means the Router screwed up. Or, maybe more likely,
    #this Callee implementation has a bug … :-(
    if (!$orig_reg) {
        die "Received REGISTERED for unknown (Request=$req_id)!"; #XXX
    }

    $self->{'_registrations'}{ $msg->get('Registration') } = $orig_reg;

    return;
}

sub get_REGISTER {
    my ($self, $msg_or_reg_id) = @_;

    my $reg_id = ref($msg_or_reg_id) ? $msg_or_reg_id->get('Registration') : $msg_or_reg_id;

    return $self->{'_registrations'}{ $reg_id };
}

#----------------------------------------------------------------------

sub get_INVOCATION {
    my ($self, $msg_or_req_id) = @_;

    my $req_id = ref($msg_or_req_id) ? $msg_or_req_id->get('Request') : $msg_or_req_id;

    return $self->{'_invocations'}{ $req_id };
}

sub _receive_INVOCATION {
    my ($self, $msg) = @_;

    my $registration = $self->{'_registrations'}{ $msg->get('Registration') };

    if (!$registration) {
        my $reg_id = $msg->get('Registration');
        die "Received INVOCATION for unknown (Registration=$reg_id)!"; #XXX
    }

    $self->{'_invocations'}{ $msg->get('Request') } = $msg;

    my $worker_class = $self->RPCWorker_class();

    return $worker_class->new( $self, $msg );
}

#----------------------------------------------------------------------

sub send_UNREGISTER {
    my ($self, $reg_id) = @_;

    my $msg = $self->_create_and_send_session_msg(
        'UNREGISTER',
        $reg_id,
    );

    return $self->{'_sent_UNREGISTER'}{$msg->get('Request')} = $msg;
}

sub send_UNREGISTER_for_procedure {
    my ($self, $uri) = @_;

    my $reg_id;

    for my $this_reg_id ( keys %{ $self->{'_registrations'} } ) {
        if ($uri eq $self->{'_registrations'}{$this_reg_id}) {
            $reg_id = $this_reg_id;
            last;
        }
    }

    die "No registration for procedure “$uri”!" if !$reg_id;

    return $self->send_UNREGISTER($reg_id);
}

sub _receive_ERROR_UNREGISTER {
    my ($self, $msg) = @_;

    my $orig_msg = delete $self->{'_sent_UNREGISTER'}{$msg->get('Request')};
    if (!$orig_msg) {
        warn sprintf 'No tracked UNREGISTER for request ID “%s”!', $msg->get('Request');
    }

    return $orig_msg;
}

sub _receive_UNREGISTERED {
    my ($self, $msg) = @_;

    my $req_id = $msg->get('Request');

    my $unreg_msg = delete $self->{'_sent_UNREGISTER'}{ $req_id } or do {
        die "Received UNREGISTERED for unknown ($req_id)!"; #XXX
    };

    my $reg = $unreg_msg->get('Registration');

    delete $self->{'_registrations'}{ $reg };

    return $unreg_msg;
}

#----------------------------------------------------------------------

sub send_YIELD {
    my ($self, $req_id, $opts_hr, @args) = @_;

    my $worker = $self->{'_invocations'}{ $req_id };
    if (!$worker) {
        die sprintf("Refuse to send YIELD for unknown INVOCATION (%s)!", $req_id);
    }

    if (!$opts_hr->{'progress'}) {
        delete $self->{'_invocations'}{ $req_id };
    }

    return $self->_create_and_send_msg(
        'YIELD',
        $req_id,
        $opts_hr,
        @args
    );
}

sub send_ERROR {
    my ($self, $req_id, $details_hr, $err_uri, @args) = @_;

    if (!delete $self->{'_invocations'}{ $req_id }) {
        die sprintf("Refuse to send ERROR for unknown INVOCATION (%s)!", $req_id);
    }

    return $self->_create_and_send_ERROR(
        'INVOCATION',
        $req_id,
        $details_hr,
        $err_uri,
        @args,
    );
}

#----------------------------------------------------------------------

#Requires HELLO with roles.callee.features.call_canceling of true
sub _receive_INTERRUPT {
    my ($self, $msg) = @_;

    my $interrupter = Net::WAMP::Role::Callee::Interrupter->new( $self, $msg );

    return $interrupter;
}

#----------------------------------------------------------------------

package Net::WAMP::Role::Callee::Interrupter;

sub new {
    bless { _callee => $_[1], _msg => $_[2] }, $_[0];
}

#sub sent_ERROR {
#    return $_[0]->{'_sent_error'};
#}

sub send_ERROR {
    my ($self, $metadata_hr, @args) = @_;

    die 'Already sent ERROR!' if $self->{'_sent_error'};

    $self->{'_callee'}->send_ERROR(
        $self->{'_msg'}->get('Request'),
        $metadata_hr,
        'wamp.error.canceled',
        @args,
    );

    $self->{'_sent_error'} = 1;

    return;
}

sub DESTROY {
    my ($self) = @_;

    $self->send_ERROR( {} ) if !$self->{'_sent_error'};

    return;
}

1;
