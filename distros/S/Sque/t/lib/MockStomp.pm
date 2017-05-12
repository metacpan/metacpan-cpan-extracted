package MockStomp;
use Moose;
use base 'Net::Stomp';

sub ack {};
sub send {};
sub subscribe {};
sub receive_frame {};

1;
