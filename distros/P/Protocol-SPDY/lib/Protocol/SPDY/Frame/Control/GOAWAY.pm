package Protocol::SPDY::Frame::Control::GOAWAY;
$Protocol::SPDY::Frame::Control::GOAWAY::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Frame::Control);

=head1 NAME

Protocol::SPDY::Frame::Control::GOAWAY - connection termination request

=head1 VERSION

version 1.001

=head1 SYNOPSIS

 use Protocol::SPDY;

=head1 DESCRIPTION

See L<Protocol::SPDY> and L<Protocol::SPDY::Base>.

=cut

use Protocol::SPDY::Constants ':all';

=head2 type_name

The string type for this frame ('GOAWAY').

=cut

sub type_name { 'GOAWAY' }

=head2 status_code

Numerical status code to use for the response.

=cut

sub status_code {
	my $self = shift;
	return $self->{status_code} unless @_;
	$self->{status_code} = shift;
	return $self;
}

=head2 from_data

Instantiates from the given data.

=cut

sub from_data {
	my $class = shift;
	my %args = @_;
	my ($stream_id, $status_code) = unpack "N1N1", substr $args{data}, 0, 8, '';
	$stream_id &= ~0x80000000;
	$class->new(
		%args,
		last_stream_id => $stream_id,
		status_code => $status_code,
	);
}

=head2 last_stream_id

The last stream ID we accepted, or 0 if no streams were accepted.

=cut

sub last_stream_id { shift->{last_stream_id} }

=head2 status_code_as_text

Text representation of the status code. You can pass a numerical code to look
up the text reason for that code rather than using the current value.

=cut

sub status_code_as_text {
	my $self = shift;
	my $code = shift // $self->status_code;
	die "Invalid status code $code" unless exists RST_STATUS_CODE_BY_ID->{$code};
	return RST_STATUS_CODE_BY_ID->{$code};
}

=head2 as_packet

Returns the packet as a byte string.

=cut

sub as_packet {
	my $self = shift;
	my $payload = pack 'N1N1', $self->last_stream_id & 0x7FFFFFFF, $self->status_code;
	return $self->SUPER::as_packet(
		payload => $payload,
	);
}

=head2 to_string

String representation, for debugging.

=cut

sub to_string {
	my $self = shift;
	$self->SUPER::to_string . ', stream ' . $self->last_stream_id . ', reason ' . $self->status_code_as_text;
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
