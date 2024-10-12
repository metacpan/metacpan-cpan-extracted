package Net::RDAP::Object::Nameserver;
use base qw(Net::RDAP::Object);
use Net::DNS::Domain;
use Net::IP;
use strict;
use warnings;

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

    $name = $domain->unicodeName;

Returns a string containing the DNS Unicode name of the domain (or C<undef>).

=cut

sub unicodeName { $_[0]->{'unicodeName'} }

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

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
