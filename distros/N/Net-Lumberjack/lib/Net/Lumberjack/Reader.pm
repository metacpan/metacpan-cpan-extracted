package Net::Lumberjack::Reader;

use Moose;

# ABSTRACT: class to read lumberjack frame stream
our $VERSION = '1.02'; # VERSION

use Net::Lumberjack::Frame;
use Net::Lumberjack::Frame::Ack;
use IO::String;

has 'handle' => ( is => 'ro', required => 1 );

has 'unacked_frames' => (
  is => 'ro', isa => 'Int', default => 0,
  traits => [ 'Counter' ],
  handles => {
    inc_unacked_frames   => 'inc',
    reset_unacked_frames => 'reset',
  },
);
has 'last_seq' => ( is => 'rw', isa => 'Int', default => 0 );
has 'window_size' => ( is => 'rw', isa => 'Int', default => 1 );

sub read_data {
	my ( $self, $conn ) = @_;
  my $substream = 0;
  if( defined $conn ) {
    $substream = 1;
  } else {
    $conn = $self->handle;
  }
  my @data;

	while( my $frame = Net::Lumberjack::Frame->new_from_fh($conn) ) {
    if( $frame->can('data') ) {
      push(@data, $frame->data);
    } elsif( ! $substream
        && ref($frame) eq 'Net::Lumberjack::Frame::Compressed' ) {
      my $io_compressed = IO::String->new( $frame->stream );
	    while( my @subdata = $self->read_data($io_compressed) ) {
        push(@data, @subdata);
      }
    } elsif( ref($frame) eq 'Net::Lumberjack::Frame::WindowSize' ) {
      $self->window_size( $frame->window_size );
    }

    if( $frame->can('seq') ) {
      $self->last_seq( $frame->seq );
      $self->inc_unacked_frames();
    }
    if( $self->unacked_frames >= $self->window_size ) {
      $self->send_ack;
    }
    if( @data ) {
      return @data;
    }
	}
  return;
}

sub send_ack {
	my ( $self ) = @_;
  if( ! $self->unacked_frames ) {
    return; # nothing to ack
  }
  my $ack = Net::Lumberjack::Frame::Ack->new(
    'seq' => $self->last_seq,
  );
  $self->handle->print( $ack->as_string );
  $self->reset_unacked_frames;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Lumberjack::Reader - class to read lumberjack frame stream

=head1 VERSION

version 1.02

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
