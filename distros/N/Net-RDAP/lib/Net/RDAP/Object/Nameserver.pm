package Net::RDAP::Object::Nameserver;
use base qw(Net::RDAP::Object);
use Net::DNS::Domain;
use Net::IP;
use strict;

=pod

=head1 NAME

L<Net::RDAP::Object::Nameserver> - a module representing a nameserver.

=head1 DESCRIPTION

L<Net::RDAP::Object::Nameserver> represents DNS servers to which domain
names are delegated.

L<Net::RDAP::Object::Nameserver> inherits from L<Net::RDAP::Object> so has
access to all that module's methods.

Other methods include:

    $name = $nameserver->name;

Returns a Net::DNS::Domain representing the name of the nameserver.

=cut

sub name { Net::DNS::Domain->new($_[0]->{'ldhName'}) }

=pod

    @addrs = $nameserver->addresses($version);

Returns a (potentially empty) array of L<Net::IP> objects representing
the nameserver's IP addresses. C<$version> can be either "v4" or "v6"
to restrict the addresses returned to IPv4 and IPv6, respectively (if
ommitted, all addresses are returned).

=cut

sub addresses {
    my ($self, $version) = @_;

    my @addrs;

    my @versions;
    if ($version) {
        push(@versions, $version);

    } else {
        push(@versions, qw(v4 v6));

    }

    foreach my $version (@versions) {
        if (defined($self->{'ipAddresses'}->{$version})) {
            foreach my $addr (@{$self->{'ipAddresses'}->{$version}}) {
                push(@addrs, Net::IP->new($addr));
            }
        }
    }

    return @addrs;
}

=pod

=head1 COPYRIGHT

Copyright CentralNic Ltd. All rights reserved.

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
