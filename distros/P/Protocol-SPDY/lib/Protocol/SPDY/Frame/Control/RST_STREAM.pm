package Protocol::SPDY::Frame::Control::RST_STREAM;
$Protocol::SPDY::Frame::Control::RST_STREAM::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Frame::Control);

=head1 NAME

Protocol::SPDY::Frame::Control::RST_STREAM - stream reset

=head1 VERSION

version 1.001

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Protocol::SPDY> and L<Protocol::SPDY::Base>.

=cut

use Protocol::SPDY::Constants ':all';

=head2 type_name

The string type for this frame ('RST_STREAM').

=cut

sub type_name { 'RST_STREAM' }

=head2 status_code

Status to return for this response.

=cut

sub status_code {
	my $self = shift;
	return $self->{status_code} unless @_;
	$self->{status_code} = shift;
	return $self;
}

=head2 from_data

Instantiate from data.

=cut

sub from_data {
	my $class = shift;
	my %args = @_;
	my ($stream_id, $status_code) = unpack "N1N1", substr $args{data}, 0, 8, '';
	$stream_id &= ~0x80000000;
	$class->new(
		%args,
		stream_id   => $stream_id,
		status_code => $status_code,
	);
}

=head2 new

Instantiate.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	$args{status_code} = RST_STATUS_CODE_BY_NAME->{delete $args{status}} if exists $args{status};
	$class->SUPER::new(%args)
}

=head2 status_code_as_text

Text representation for the status code.

=cut

sub status_code_as_text {
	my $self = shift;
	my $code = shift // $self->status_code;
	die "Invalid status code $code" unless exists RST_STATUS_CODE_BY_ID->{$code};
	return RST_STATUS_CODE_BY_ID->{$code};
}

=head2 stream_id

Which stream ID this applies to.

=cut

sub stream_id { shift->{stream_id} }

=head2 as_packet

Returns the packet as a byte string.

=cut

sub as_packet {
	my $self = shift;
	my $payload = pack 'N1N1', $self->stream_id & 0x7FFFFFFF, $self->status_code;
	return $self->SUPER::as_packet(
		payload => $payload,
	);
}

=head2 to_string

String representation, for debugging.

=cut

sub to_string {
	my $self = shift;
	$self->SUPER::to_string . ', stream ' . $self->stream_id . ', reason ' . $self->status_code_as_text;
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
