package Protocol::SPDY::Tracer;
$Protocol::SPDY::Tracer::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Base);

=head1 NAME

Protocol::SPDY::Tracer - helper class for tracing SPDY sessions

=head1 VERSION

version 1.001

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Protocol::SPDY> and L<Protocol::SPDY::Base>.

=cut

=head1 METHODS

=cut

=head2 control_frame_bytes

Returns byte representation of the given control frame.

 my $bytes = $tracer->control_frame_bytes(GOAWAY => [ ]);

=cut

sub control_frame_bytes {
	my $self = shift;
	my $type = shift;
	my $args = shift;
	Protocol::SPDY::Frame::Control->find_class_for_type($type)->new(
		version => $self->version,
		@$args,
	)->as_packet($self->sender_zlib)
}

=head2 dispatch_unhandled_frame

Ignore unhandled frames.

=cut

sub dispatch_unhandled_frame { }

=head2 write

Write requests are always ignored here.

=cut

sub write { }

1;

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
