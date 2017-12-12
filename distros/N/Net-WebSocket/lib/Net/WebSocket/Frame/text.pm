package Net::WebSocket::Frame::text;

=encoding utf-8

=head1 NAME

Net::WebSocket::Frame::text

=head1 SYNOPSIS

    my $frm = Net::WebSocket::Frame::text->new(

        #This flag defaults to on
        fin => 1,

        #Optional, can be either empty (default) or four random bytes
        mask => q<>,

        payload => $payload_text,
    );

    $frm->get_type();           #"text"

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

use constant get_opcode => 1;

1;
