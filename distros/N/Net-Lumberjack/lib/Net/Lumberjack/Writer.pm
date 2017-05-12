package Net::Lumberjack::Writer;

use Moose;

# ABSTRACT: class to generate lumberjack frame stream
our $VERSION = '1.02'; # VERSION

use Net::Lumberjack::Frame;
use Net::Lumberjack::Frame::WindowSize;
use Net::Lumberjack::Frame::JSON;
use Net::Lumberjack::Frame::Compressed;

has 'handle' => ( is => 'ro', required => 1 );

has 'seq' => (
  is => 'ro', isa => 'Int', default => 0,
  traits => [ 'Counter' ],
  handles => {
    next_seq => 'inc',
  },
);
has 'last_ack' => ( is => 'rw', isa => 'Int', default => 0 );
has 'max_window_size' => ( is => 'rw', isa => 'Int', default => 2048 );

has 'current_window_size' => ( is => 'rw', isa => 'Int', default => 0 );

has 'frame_format' => ( is => 'ro', isa => 'Str', default => 'json');
has '_frame_class' => (
  is => 'ro', isa => 'Str', lazy => 1,
  default => sub {
    my $self = shift;
    if( $self->frame_format eq 'json' || $self->frame_format eq 'v2' ) {
      return "Net::Lumberjack::Frame::JSON";
    } elsif( $self->frame_format eq 'data' || $self->frame_format eq 'v1' ) {
      return "Net::Lumberjack::Frame::Data";
    } else {
      die('invalid frame format specified: '.$self->frame_format);
    }
  },
);

sub set_window_size {
	my ( $self, $size ) = @_;
  if( $self->current_window_size != $size ) {
    my $window = Net::Lumberjack::Frame::WindowSize->new(
      window_size => $size,
    );
    $self->handle->print( $window->as_string );
    $self->current_window_size( $size );
  }
  return;
}

sub send_data {
	my ( $self, @data ) = @_;

  if( ! @data ) {
    return;
  }

  while(@data) {
    my $num_bulk = scalar(@data) > $self->max_window_size ?
      $self->max_window_size : scalar(@data);
    $self->set_window_size( $num_bulk );
    my $stream = '';
    for( my $i = 0 ; $i < $num_bulk ; $i++ ) {
      my $frame_class = $self->_frame_class;
      my $frame = $frame_class->new(
        seq => $self->next_seq,
        data => shift(@data),
      );
      $stream .= $frame->as_string;
    }
    my $compressed = Net::Lumberjack::Frame::Compressed->new(
      stream => $stream,
    );
    $self->handle->print( $compressed->as_string );
    $self->wait_for_ack( $self->seq );
  }

  return;
}

sub wait_for_ack {
  my ( $self, $wait_for_seq ) = @_;
  while( my $frame = Net::Lumberjack::Frame->new_from_fh($self->handle) ) {
    if( ref($frame) eq 'Net::Lumberjack::Frame::Ack' ) {
      $self->last_ack( $frame->seq );
    }
    if( $self->last_ack >= $wait_for_seq ) {
      last;
    }
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Lumberjack::Writer - class to generate lumberjack frame stream

=head1 VERSION

version 1.02

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
