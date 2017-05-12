package RTSP::Proxy::StreamBuffer;

use Moose;

has stream_buffer_size => (
    is => 'rw',
    isa => 'Int',
    default => sub { 128 },
);

has _buf => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

sub add_packet {
    my ($self, $packet) = @_;
    
    push @{$self->_buf}, $packet;
    if (length @{$self->_buf} > $self->stream_buffer_size) {
        shift @{$self->_buf};
    }
    
    return $packet;
}

sub get_packet {
    my $self = shift;
    
    return shift @{$self->_buf};
}

sub clear_packets {
    my $self = shift;
    
    $self->_buf([]);
}

__PACKAGE__->meta->make_immutable;
