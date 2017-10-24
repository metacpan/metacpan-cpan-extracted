package Net::WebSocket::Streamer;

=encoding utf-8

=head1 NAME

Net::WebSocket::Streamer - Stream a WebSocket message easily

=head1 SYNOPSIS

Here’s the gist of it:

    #Use the ::Client or ::Server subclass as needed.
    my $streamer = Net::WebSocket::Streamer::Client->new('binary');

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

Note that the receiving application won’t necessarily have access to the
individual message fragments (i.e., frames) that you send. Web browsers,
for example, only expose messages, not frames. You may thus be better off
sending full messages rather than frames.

=head1 EXTENSION SUPPORT

To stream custom frame types (or overridden classes), you can subclass
this module and define C<frame_class_*> constants, where C<*> is the
frame type, e.g., C<text>, C<binary>.

=cut

use strict;
use warnings;

use Net::WebSocket::Frame::continuation ();
use Net::WebSocket::X ();

use constant {

    #These can be overridden in subclasses.
    frame_class_text => 'Net::WebSocket::Frame::text',
    frame_class_binary => 'Net::WebSocket::Frame::binary',

    FINISHED_INDICATOR => __PACKAGE__ . '::__ALREADY_SENT_FINAL',
};

sub new {
    my ($class, $type) = @_;

    my $frame_class = $class->_load_frame_class($type);

    return bless { class => $frame_class, pid => $$ }, $class;
}

sub create_chunk {
    my $self = shift;

    my $frame = $self->{'class'}->new(
        fin => 0,
        $self->FRAME_MASK_ARGS(),
        payload_sr => \$_[0],
    );

    #The first $frame we create needs to be typed (e.g., text or binary),
    #but all subsequent ones must be continuation.
    if ($self->{'class'} ne 'Net::WebSocket::Frame::continuation') {
        $self->{'class'} = 'Net::WebSocket::Frame::continuation';
    }

    return $frame;
}

sub create_final {
    my $self = shift;

    my $frame = $self->{'class'}->new(
        $self->FRAME_MASK_ARGS(),
        fin => 1,
        payload_sr => \$_[0],
    );

    $self->{'finished'} = 1;

    return $frame;
}

sub _load_frame_class {
    my ($class, $type) = @_;

    my $frame_class = $class->can("frame_class_$type");
    if (!$frame_class) {
        die "Unknown frame type: “$type”!";
    }

    $frame_class = $frame_class->();
    if (!$frame_class->can('new')) {
        Module::Load::load($frame_class);
    }

    return $frame_class;
}

sub DESTROY {
    my ($self) = @_;

    if (($self->{'pid'} == $$) && !$self->{'finished'}) {
        die Net::WebSocket::X->create('UnfinishedStream', $self);
    }

    return;
}

1;
