package Net::RDAP::Object::IPNetwork;
use base qw(Net::RDAP::Object);
use Net::IP;
use strict;

=head1 NAME

L<Net::RDAP::Object::IPNetwork> - an RDAP object representing an IP
address network.

=head1 DESCRIPTION

L<Net::RDAP::Object::IPNetwork> represents a block of IP addresses
(IPv4 or IPv6) allocated by an RIR.

L<Net::RDAP::Object::IPNetwork> inherits from L<Net::RDAP::Object> so has
access to all that module's methods.

Other methods include:

	$start = $network->start;

Returns a L<Net::IP> object representing the starting IP address of
the network.

	$end = $network->end;

Returns a L<Net::IP> object representing the ending IP address of
the network.

	$version = $network->version;

Returns a string signifying the IP protocol version of the network,
either "v4" or "v6".

	$name = $network->name;

Returns a string containing the identifier assigned to the network
registration by the registration holder.

	$type = $network->type;

Returns a string containing an RIR-specific classification of the
network.

	$country = $network->country;

Returns a string containing the two-character country code of the
network.

	$parentHandle = $network->parentHandle;

Returns a string containing an RIR-unique identifier of the parent
network of this network registration

=cut

sub start		{ Net::IP->new($_[0]->{'startAddress'})	}
sub end			{ Net::IP->new($_[0]->{'endAddress'})	}
sub version		{ $_[0]->{'ipVersion'}			}
sub name		{ $_[0]->{'name'}			}
sub type		{ $_[0]->{'type'}			}
sub country		{ $_[0]->{'country'}			}
sub parentHandle	{ $_[0]->{'parentHandle'}		}

=pod

	$range = $network->range;

Returns a L<Net::IP> object representing the range of addresses
between the start and end addresses.

=cut

sub range {
	my $self = shift;

	my $str = sprintf(
		'%s - %s',
		$self->start->ip,
		$self->end->ip,
	);

	return Net::IP->new($str);
}

=pod

	$url = $network->domain;

Returns a L<URI> object representing the RDAP URL of the "reverse"
domain object corresponding to this network. For example, if the IP
network is C<192.168.0.0/24>, then the corresponding reverse domain is
C<168.192.in-addr.arpa>. The URL is constructed using the base URL of
the RDAP service for the IP network.

You will need to fetch the object representing this domain yourself,
for example:

	$ip = $rdap->ip(Net::IP->new('192.168.0.0/24'));

	# $ip is a Net::RDAP::IPNetwork

	$url = $ip->domain;

	# $url is a URI

	$domain = $rdap->fetch($url);

	# domain is a Net::RDAP::Domain for 168.192.in-addr.arpa

=cut

sub domain {
	my $self = shift;
	URI->new_abs(sprintf('../../domain/%s', $self->start->reverse_ip), $self->self->href);
}

=pod

=head1 COPYRIGHT

Copyright 2019 CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
