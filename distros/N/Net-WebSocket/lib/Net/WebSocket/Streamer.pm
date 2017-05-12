package Net::WebSocket::Streamer;

=encoding utf-8

=head1 NAME

Net::WebSocket::Streamer - Send a stream easily over WebSocket

=head1 SYNOPSIS

Here’s the gist of it:

    my $streamer = Net::WebSocket::Streamer->new('binary');

    my $frame = $streamer->create_chunk($buf);

    my $last_frame = $streamer->create_final($buf);

… but a more complete example might be this: streaming a file
of arbitrary size in 64-KiB chunks:

    my $size = -s $rfh;

    while ( read $rfh, my $buf, 65536 ) {
        my $frame;

        if (tell($rfh) == $size) {
            $frame = $streamer->create_final($buf);
        }
        else {
            $frame = $streamer->create_chunk($buf);
        }

        syswrite $wfh, $frame->to_bytes();
    }

You can, of course, create/send an empty final frame for cases where you’re
not sure how much data will actually be sent.

=head1 EXTENSION SUPPORT

To stream custom frame types (or overridden classes), you can subclass
this module and define C<frame_class_*> constants, where C<*> is the
frame type, e.g., C<text>, C<binary>.

=cut

use strict;
use warnings;

use Net::WebSocket::Frame::continuation ();

use constant {

    #These can be overridden in subclasses.
    frame_class_text => 'Net::WebSocket::Frame::text',
    frame_class_binary => 'Net::WebSocket::Frame::binary',

    FINISHED_INDICATOR => __PACKAGE__ . '::__ALREADY_SENT_FINAL',
};

sub new {
    my ($class, $type) = @_;

    my $frame_class = $class->_load_frame_class($type);

    #Store the frame class as the value of $$self.

    return bless \$frame_class, $class;
}

sub create_chunk {
    my $self = shift;

    my $frame = $$self->new(
        fin => 0,
        $self->FRAME_MASK_ARGS(),
        payload_sr => \$_[0],
    );

    #The first $frame we create needs to be text/binary, but all
    #subsequent ones must be continuation.
    if ($$self ne 'Net::WebSocket::Frame::continuation') {
        $$self = 'Net::WebSocket::Frame::continuation';
    }

    return $frame;
}

sub create_final {
    my $self = shift;

    my $frame = $$self->new(
        fin => 1,
        $self->FRAME_MASK_ARGS(),
        payload_sr => \$_[0],
    );

    substr( $$self, 0 ) = FINISHED_INDICATOR();

    return $frame;
}

sub _load_frame_class {
    my ($self, $type) = @_;

    my $class = $self->can("frame_class_$type");
    if (!$class) {
        die "Unknown frame type: “$type”!";
    }

    $class = $class->();
    if (!$class->can('new')) {
        Module::Load::load($class);
    }

    return $class;
}

sub DESTROY {
    my ($self) = @_;

    if (!$$self eq FINISHED_INDICATOR()) {
        die sprintf("$self DESTROYed without having sent a final fragment!");
    }

    return;
}

1;
