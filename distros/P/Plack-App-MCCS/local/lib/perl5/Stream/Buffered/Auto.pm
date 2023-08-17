package Stream::Buffered::Auto;
use strict;
use warnings;
use base 'Stream::Buffered';

sub new {
    my($class, undef, $max_memory_size) = @_;
    bless {
        _buffer => Stream::Buffered->create('PerlIO'),
        _max => $max_memory_size,
    }, $class;
}

sub print {
    my $self = shift;
    $self->{_buffer}->print(@_);

    if ($self->{_max} && $self->{_buffer}->size > $self->{_max}) {
        my $buf = $self->{_buffer}->{buffer};
        $self->{_buffer} = Stream::Buffered->create('File'),
        $self->{_buffer}->print($buf);
        delete $self->{_max};
    }
}

sub size {
    my $self = shift;
    $self->{_buffer}->size;
}

sub rewind {
    my $self = shift;
    $self->{_buffer}->rewind;
}

1;
