package Net::WebSocket::Base::DataMessage;

use parent qw(
    Net::WebSocket::Message
    Net::WebSocket::Base::Typed
);

use constant is_control_message => 0;

1;
