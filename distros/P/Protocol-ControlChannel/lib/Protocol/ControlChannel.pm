package Protocol::ControlChannel;
# ABSTRACT: trivial key/value binary protocol
use strict;
use warnings;

our $VERSION = '0.003';

=head1 NAME

Protocol::ControlChannel - simple binary protocol for exchanging key/value pairs

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $cc = Protocol::ControlChannel->new;
 my $data = $cc->create_frame(key => 'value');
 my $frame = $cc->extract_frame(\$data);
 print 'Key: ' . $frame->{key} . ', value ' . $frame->{value} . "\n";

=head1 DESCRIPTION

This is the abstract implementation for a wire protocol which can be used to exchange
data between two endpoints, as a series of key/value pairs.

Typical use-case is for passing events between remote processes/hosts.

The data packet looks like this:

=over 4

=item * packet_length - 32-bit network-order unsigned int - excludes the length field itself

=item * type - 16-bit network-order unsigned int - defines the type of this message, typically
describes the format of the value field

=item * name_length - 16-bit network-order unsigned int - length of the name field

=item * UTF-8 encoded name information - no null terminator

=item * remaining bytes are value information, content depends on 'type'

=back

Types are currently 0 for 'plain text', 1 for 'Storable::nfreeze'. It's quite possible that
L<Sereal> support will be added soon.

Usage is simple: instantiate, call methods, if anything returns undef then things have
gone wrong so you're advised to terminate that session. If you're exchanging packets
via UDP then this may not be so simple.

Note that content is either Perl data structures (i.e. a reference), or byte
data. If you have a string, you'll need to pick a suitable encoding and
decoding - probably UTF-8.

=cut

use Encode;
use Storable;

=head1 METHODS

=cut

=head2 new

Instantiate an object. Not technically necessary, since all the other methods could
just as well be class methods for the moment, but in future this is likely to change.

=cut

sub new { my $class = shift; bless {}, $class }

=head2 extract_frame

Given a scalar ref to a byte buffer, will attempt to extract the next frame.

If a full, valid frame was found, it will be decoded, removed from the buffer,
and returned as a hashref.

If not, you get undef.

If something went wrong, you'll probably get undef at the moment. In future this
may raise an exception.

=cut

sub extract_frame {
	my $self = shift;
	my $data = shift;
	my $len = length $$data;
	return undef unless $len > 4;

	my ($size) = unpack 'N1', substr $$data, 0, 4;
	$size += 4;
	return undef unless $len >= $size;

	my $frame = substr $$data, 0, $size, '';
	my (undef, $type, $key) = unpack 'N1n1n/a*', $frame;
	die "unknown type $type" unless $type == 0 || $type == 1;
	substr $frame, 0, 8 + length($key), '';
	$frame = Storable::thaw($frame) if $type == 1;
	return +{
		type => 'text',
		key => Encode::decode('UTF-8' => $key),
		value => $frame
	};
}

=head2 create_frame

Creates a frame. Takes a key => value pair, and returns them in packet form.

Key must be something that can be utf8-encoded - so 'a perl string', or an
object that stringifies sanely.

=cut

sub create_frame {
	my $self = shift;
	my $k = shift;
	my $v = shift;
	my $type = ref($v) ? 1 : 0;
	$v = Storable::nfreeze($v) if ref $v;
	my $packed = pack 'n1n/a*', $type, Encode::encode('UTF-8' => $k);
	$packed .= $v;
	return pack 'N/a*', $packed;
}

1;

__END__

=head1 SEE ALSO

Any of the other protocols that look very similar to this one...

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2013. Licensed under the same terms as Perl itself.
