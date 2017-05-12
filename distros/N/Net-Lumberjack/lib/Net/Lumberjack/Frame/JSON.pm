package Net::Lumberjack::Frame::JSON;

use Moose;

# ABSTRACT: class for parsing Lumberjack JSON frames
our $VERSION = '1.02'; # VERSION

extends 'Net::Lumberjack::Frame';

use JSON;

has 'type' => ( is => 'ro', isa => 'Str', default => 'J' );
has 'version' => ( is => 'rw', isa => 'Int', default => 2 );

has 'seq' => ( is => 'rw', isa => 'Maybe[Int]' );
has 'data' => ( is => 'rw', isa => 'Maybe[HashRef]' );

has 'payload' => (
  is => 'rw', isa => 'Str', lazy => 1,
  default => sub {
    my $self = shift;
    my $json_str = encode_json( $self->data );
    my $len = length($json_str);
    return pack('NN', $self->seq, $len).$json_str;
  },
);

sub _read_payload {
	my ( $self, $fh ) = @_;

  $self->seq( $self->_read_uint32($fh) );
  $self->data( decode_json($self->_read_data($fh)) );

  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Lumberjack::Frame::JSON - class for parsing Lumberjack JSON frames

=head1 VERSION

version 1.02

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
