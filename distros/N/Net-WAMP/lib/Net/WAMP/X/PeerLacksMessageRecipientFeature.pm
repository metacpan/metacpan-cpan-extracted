package Net::WAMP::X::PeerLacksMessageRecipientFeature;

use strict;
use warnings;

use parent 'Net::WAMP::X::Base';

sub _new {
    my ($class, $msg_type, $feature_name) = @_;

    return $class->SUPER::_new(
        "You cannot send a message of type “$msg_type” to a recipient that doesn’t advertise the feature “$feature_name”.",
        message_type => $msg_type,
        feature_name => $feature_name,
    );
}

1;

