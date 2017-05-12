package Net::Lumberjack::Frame::Data;

use Moose;

# ABSTRACT: class for parsing Lumberjack data frames
our $VERSION = '1.02'; # VERSION

extends 'Net::Lumberjack::Frame';

has 'type' => ( is => 'ro', isa => 'Str', default => 'D' );

has 'seq' => ( is => 'rw', isa => 'Maybe[Int]' );
has 'data' => ( is => 'rw', isa => 'Maybe[HashRef]' );

has 'payload' => (
  is => 'rw', isa => 'Str', lazy => 1,
  default => sub {
    my $self = shift;
    my $pairs = scalar keys %{$self->data};
    my $data = '';
    foreach my $key ( keys %{$self->data} ) {
      # skip if emtpy or not a scalar
      if( ! defined $self->data->{$key}
          || ref($self->data->{$key}) ) {
        next;
      }
      my $keylen = length($key);
      $data .= pack('N', $keylen).$key;
      my $valuelen = length( $self->data->{$key} );
      $data .= pack('N', $valuelen).$self->data->{$key};
    }
    return pack('NN', $self->seq, $pairs).$data;
  },
);

sub _read_payload {
	my ( $self, $fh ) = @_;
  my $data = {};

  $self->seq( $self->_read_uint32($fh) );
  my $pairs = $self->_read_uint32($fh);
  for( my $i = 0 ; $i < $pairs ; $i++ ) {
    my $key = $self->_read_data($fh);
    my $value = $self->_read_data($fh);
    $data->{$key} = $value;
  }
  $self->data( $data );
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Lumberjack::Frame::Data - class for parsing Lumberjack data frames

=head1 VERSION

version 1.02

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
