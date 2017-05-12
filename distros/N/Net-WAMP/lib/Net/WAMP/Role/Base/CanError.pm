package Net::WAMP::Role::Base::CanError;

use strict;
use warnings;

use Try::Tiny;

sub _create_and_send_ERROR {
    my ($self, $subtype, @args) = @_;

    #This is local()ed in handle_message().
    $self->{'_prevent_custom_handler'} = 1;

    return $self->_create_and_send_msg(
        'ERROR',
        Net::WAMP::Messages::get_type_number($subtype),
        @args,
    );
}

sub _catch_exception {
    my ($self, $req_type, $req_id, $todo_cr) = @_;

    my $ret;

    my $id = sprintf '%x', substr( rand, 2 );

    try {
        $ret = $todo_cr->();
    }
    catch {

        #Anything we catch here is likely not something we want
        #a peer to know about.

        warn "ERROR XID $id: $_";

        $self->_create_and_send_ERROR(
            $req_type,
            $req_id,
            'net_wamp.error',
            [ "internal error (XID $id)" ],
        );
    };

    return $ret;
}

1;
