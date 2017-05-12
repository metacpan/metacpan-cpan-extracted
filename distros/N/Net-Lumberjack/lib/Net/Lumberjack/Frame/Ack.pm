package Net::Lumberjack::Frame::Ack;

use Moose;

# ABSTRACT: class for parsing Lumberjack ACK frames
our $VERSION = '1.02'; # VERSION

extends 'Net::Lumberjack::Frame';

has 'type' => ( is => 'rw', isa => 'Str', 'default' => 'A' );
has 'seq' => ( is => 'rw', isa => 'Maybe[Int]' );

has 'payload' => (
  is => 'rw', isa => 'Str', lazy => 1,
  'default' => sub {
    my $self = shift;
    return pack('N', $self->seq);
  },
);

sub _read_payload {
	my ( $self, $fh ) = @_;
  $self->seq( $self->_read_uint32($fh) );
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Lumberjack::Frame::Ack - class for parsing Lumberjack ACK frames

=head1 VERSION

version 1.02

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
