package Net::Lumberjack::Frame::Compressed;

use Moose;

# ABSTRACT: class for parsing Lumberjack compressed frames
our $VERSION = '1.02'; # VERSION

extends 'Net::Lumberjack::Frame';

use Compress::Zlib;

has 'type' => ( is => 'rw', isa => 'Str', default => 'C' );
has 'stream' => ( is => 'rw', isa => 'Maybe[Str]' );

has 'payload' => (
  is => 'rw', isa => 'Str', lazy => 1,
  'default' => sub {
    my $self = shift;
    my $compressed = compress( $self->stream );
    my $len = length($compressed);
    return pack('N', $len).$compressed;
  },
);

sub _read_payload {
	my ( $self, $fh ) = @_;
  $self->stream( uncompress $self->_read_data($fh) );
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Lumberjack::Frame::Compressed - class for parsing Lumberjack compressed frames

=head1 VERSION

version 1.02

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
