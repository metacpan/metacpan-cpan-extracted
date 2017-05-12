package Net::WAMP::X::PeerLacksMessageRecipientRole;

use strict;
use warnings;

use parent 'Net::WAMP::X::Base';

sub _new {
    my ($class, $msg_type, $role_name) = @_;

    return $class->SUPER::_new(
        "You cannot send a message of type “$msg_type” to a recipient that doesn’t execute the role “$role_name”.",
        message_type => $msg_type,
        role_name => $role_name,
    );
}

1;
