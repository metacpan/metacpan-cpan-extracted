package Net::WebSocket::Frame::binary;

=encoding utf-8

=head1 NAME

Net::WebSocket::Frame::binary

=head1 SYNOPSIS

    my $frm = Net::WebSocket::Frame::binary->new(

        #This flag defaults to on
        fin => 1,

        #Optional, can be either empty (default) or four random bytes
        mask => q<>,

        payload => $payload_octet_string,
    );

    $frm->get_type();           #"binary"

    $frm->is_control_frame();   #0

    my $mask = $frm->get_mask_bytes();

    my $payload = $frm->get_payload();

    my $serialized = $frm->to_bytes();

    $frm->set_fin();    #turns on

=cut

use parent qw(
    Net::WebSocket::Base::DataFrame
);

use constant get_opcode => 2;

1;
