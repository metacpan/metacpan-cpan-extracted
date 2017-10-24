package Net::WebSocket::PMCE::Data;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::WebSocket::PMCE::Data - Base class for PMCE data modules.

=head1 DESCRIPTION

=head1 METHODS

Available on all instances:

=head2 I<OBJ>->message_is_compressed( MESSAGE )

MESSAGE is an instance of L<Net::WebSocket::Message>.
The output is a Perl boolean that indicates whether the message
appears to be PMCE-compressed.

You can also call this as a class method, e.g.:

    Net::WebSocket::PMCE->message_is_compressed( $message_obj );

=cut

sub message_is_compressed {
    return ($_[1]->get_frames())[0]->has_rsv1();
}

=head2 INITIAL_FRAME_RSV()

Returns the numeric value of the RSV bits for PMCEs,
suitable for giving to a L<Net::WebSocket::Frame> subclass’s
constructor.

=cut

use constant {
    INITIAL_FRAME_RSV => 0b100,  #RSV1
};

1;
