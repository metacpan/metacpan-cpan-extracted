package Protocol::SPDY::Frame::Control::HEADERS;
$Protocol::SPDY::Frame::Control::HEADERS::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Frame::HeaderSupport Protocol::SPDY::Frame::Control);

=head1 NAME

Protocol::SPDY::Frame::Control::HEADERS - header update packet

=head1 VERSION

version 1.001

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Protocol::SPDY> and L<Protocol::SPDY::Base>.

=cut

use Compress::Raw::Zlib qw(Z_OK WANT_GZIP_OR_ZLIB adler32);

use Protocol::SPDY::Constants ':all';

=head2 type_name

The string type for this frame ('HEADERS').

=cut

sub type_name { 'HEADERS' }

=head2 new

Instantiate.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	$args{headers} = $class->header_hashref_to_arrayref($args{headers}) if (ref($args{headers}) || '') eq 'HASH';
	$class->SUPER::new(%args)
}

=head2 from_data

Instantiate from the given data.

=cut

sub from_data {
	my $class = shift;
	my %args = @_;
	my ($stream_id) = unpack "N1", substr $args{data}, 0, 4, '';
	$stream_id &= ~0x80000000;

	my $zlib = delete $args{zlib};
	my $out = $zlib->decompress($args{data});
	my ($headers) = $class->extract_headers($out);
	$class->new(
		%args,
		stream_id => $stream_id,
		headers   => $headers,
	);
}

=head2 stream_id

Which stream this frame applies to.

=cut

sub stream_id { shift->{stream_id} }

=head2 as_packet

Byte representation for this packet.

=cut

sub as_packet {
	my $self = shift;
	my $zlib = shift;
	my $payload = pack 'N1', $self->stream_id & 0x7FFFFFFF;
	my $block = $self->pairs_to_nv_header(map {; $_->[0], join "\0", @{$_}[1..$#$_] } @{$self->headers});
	$payload .= $zlib->compress($block);
	return $self->SUPER::as_packet(
		payload => $payload,
	);
}

=head2 to_string

String representation, for debugging.

=cut

sub to_string {
	my $self = shift;
	$self->SUPER::to_string . ', id=' . $self->stream_id . ', ' . $self->header_line;
}

1;

__END__

=head1 COMPONENTS

Further documentation can be found in the following modules:

=over 4

=item * L<Protocol::SPDY> - top-level protocol object

=item * L<Protocol::SPDY::Frame> - generic frame class

=item * L<Protocol::SPDY::Frame::Control> - specific subclass for control frames

=item * L<Protocol::SPDY::Frame::Data> - specific subclass for data frames

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
