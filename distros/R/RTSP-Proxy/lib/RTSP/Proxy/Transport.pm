# transport role, supports proxying the media transport associated with an RTSP session

package RTSP::Proxy::Transport;

use Moose::Role;

requires qw/handle_packet/;

has session => (
    is => 'rw',
    isa => 'RTSP::Proxy::Session',
    required => 1,
);

1;