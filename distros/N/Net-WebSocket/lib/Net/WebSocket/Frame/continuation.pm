package Net::WebSocket::Frame::continuation;

=encoding utf-8

=HEAD1

Net::WebSocket::Frame::continuation

=head1 SYNOPSIS

    my $frm = Net::WebSocket::Frame::continuation->new(

        fin => 1,   #default

        #Optional, can be either empty (default) or four random bytes
        mask => q<>,

        payload_sr => \$payload,
    );

    $frm->get_type();           #"continuation"

    $frm->is_control_frame();   #0

    my $mask = $frm->get_mask_bytes();

    my $payload = $frm->get_payload();

    my $serialized = $frm->to_bytes();

    $frm->set_fin();    #turns on

=cut

use strict;
use warnings;

use parent qw(
    Net::WebSocket::Base::DataFrame
);

use constant get_opcode => 0;

1;
