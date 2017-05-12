package Net::CDP::IPPrefix;

#
# $Id: IPPrefix.pm,v 1.6 2005/07/20 13:44:13 mchapman Exp $
#

use strict;
use Carp::Clan qw(^Net::CDP);

use vars qw($VERSION);

$VERSION = (qw$Revision: 1.6 $)[1];

use Net::CDP;

=head1 NAME

Net::CDP::IPPrefix - Cisco Discovery Protocol (CDP) IP prefix object

=head1 SYNOPSIS

  use Net::CDP::IPPrefix;

  # Constructors
  $prefix = new Net::CDP::IPPrefix($cidr);
  $prefix = new Net::CDP::IPPrefix($network, $mask);
  $prefix = new Net::CDP::IPPrefix($network, $length);
  $cloned = clone $prefix;
  
  # Object methods
  $cidr    = $prefix->cidr;
  $network = $prefix->network;
  $mask    = $prefix->mask;
  $length  = $prefix->length;

=head1 DESCRIPTION

A Net::CDP::IPPrefix object represents a single entry in the IP Prefixes
field of a CDP packet. Net::CDP::IPPrefix objects are immutable.

=head1 CONSTRUCTORS

=over

=item B<new>

    $prefix = new Net::CDP::IPPrefix($cidr)
    $prefix = new Net::CDP::IPPrefix($network, $mask)
    $prefix = new Net::CDP::IPPrefix($network, $length)

Returns a new Net::CDP::IPPrefix object.

If only one argument is provided, C<new> will attempt to parse it as an IPv4
network prefix in CIDR notation (eg, "192.168.0.0/24"), or as a prefix/netmask
pair (eg, "192.168.0.0/255.255.255.0").

Alternatively, you can provide two arguments to supply the network prefix and
mask or bit length separately.

=cut

sub new($$;$) {
	my $class = shift;
	croak 'Usage: Net::CDP::IPPrefix->new($cidr) or Net::CDP::IPPrefix->new($network, $mask) or Net::CDP::IPPrefix->new($network, $length)' unless defined $_[0];
	my $network;
	my $length;
	
	if (defined $_[1]) {
		($network, $length) = @_;
	} else {
		($network, $length) = split /\//, $_[0], 2;
	}
	$network = Net::CDP::_v4_pack($network);
	$length = Net::CDP::_mask_pack($length) if $length =~ /\./;

	unless (defined $network && defined $length) {
		croak "Cannot parse IP prefix ('$_[0]', '$_[1]')" if defined $_[1];
		croak "Cannot parse IP prefix '$_[0]'";
	}
	$network &= pack 'B32', 1 x $length;
	Net::CDP::_rethrow { $class->_new($network, $length) };
}

=item B<clone>

    $cloned = clone $prefix

Returns a deep copy of the supplied Net::CDP::IPPrefix object.

=back

=head1 OBJECT METHODS

=over

=item B<cidr>

    $cidr = $prefix->cidr()

Returns the IP prefix in CIDR notation (eg, "192.168.0.0/24").

=cut

sub cidr($) {
	my $self = shift;
	return $self->network . '/' . $self->length;
}

=item B<network>

    $cidr = $prefix->network()

Returns the network component of this IP prefix (eg, "192.168.0.0").

=cut

sub network($) {
	my $self = shift;
	return Net::CDP::_v4_unpack($self->_network);
}

=item B<mask>

    $cidr = $prefix->mask()

Returns the mask component of this IP prefix as dotted-quad (eg,
"255.255.255.0").

=cut

sub mask($) {
	my $self = shift;
	return Net::CDP::_mask_unpack($self->length);
}

=item B<length>

    $cidr = $prefix->length()

Returns the bit length of the mask component of this dotted-quad (eg, 24).

=back

=head1 SEE ALSO

L<Net::CDP>

=head1 AUTHOR

Michael Chapman, E<lt>cpan@very.puzzling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Michael Chapman

libcdp is released under the terms and conditions of the GNU Library General
Public License version 2. Net::CDP may be redistributed and/or modified under
the same terms as Perl itself.

=cut

1;
