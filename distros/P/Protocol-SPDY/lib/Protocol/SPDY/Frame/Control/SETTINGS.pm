package Protocol::SPDY::Frame::Control::SETTINGS;
$Protocol::SPDY::Frame::Control::SETTINGS::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Frame::Control);

=head1 NAME

Protocol::SPDY::Frame::Control::SETTINGS - connection settings information

=head1 VERSION

version 1.001

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Protocol::SPDY> and L<Protocol::SPDY::Base>.

=cut

use Protocol::SPDY::Constants ':all';

=head2 type_name

The string type for this frame ('SETTINGS').

=cut

sub type_name { 'SETTINGS' }

=head2 setting

Look up the given setting and return the current value.

=cut

sub setting {
	my $self = shift;
	my $k = shift;
	$k =~ s/^SETTINGS_//;
	my $id = SETTINGS_BY_NAME->{$k} or die "unknown setting $k";
	my ($v) = grep $_->[0] == $id, @{$self->{settings}};
	$v->[2]
}

=head2 all_settings

Returns a list of all settings:

 [ id, flags, value ]

=cut

sub all_settings { @{shift->{settings}} }

=head2 from_data

Instantiate from data.

=cut

sub from_data {
	my $class = shift;
	my %args = @_;
	my ($count) = unpack "N1", substr $args{data}, 0, 4, '';
	my @settings;
	for (1..$count) {
		my ($flags, $id, $id2, $v) = unpack 'C1n1C1N1', substr $args{data}, 0, 8, '';
		$id = ($id << 8) | $id2;
		push @settings, [ $id, $flags, $v ];
	}
	$class->new(
		%args,
		settings => \@settings,
	);
}

=head2 as_packet

Returns the byte data corresponding to this frame.

=cut

sub as_packet {
	my $self = shift;

	my @settings = @{$self->{settings}};
	my $payload = pack 'N1', scalar @settings;
	for (1..@settings) {
		my $item = shift @settings;
		my $v = $item->[0] & 0x00FFFFFF;
		$v ||= ($item->[1] & 0xFF) << 24;
		$payload .= pack 'N1N1', $v, $item->[2];
	}
	return $self->SUPER::as_packet(
		payload => $payload,
	);
}

=head2 to_string

String representation, for debugging.

=cut

sub to_string {
	my $self = shift;
	$self->SUPER::to_string . ', ' . join ',', map { (SETTINGS_BY_ID->{$_->[0]} or die "unknown setting $_->[0]") . '=' . $_->[2] } @{$self->{settings}};
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
