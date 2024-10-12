package Net::RDAP::Object::Domain;
use Net::DNS::RR::DS;
use Net::DNS::RR::DNSKEY;
use Net::RDAP::Object::IPNetwork;
use base qw(Net::RDAP::Object);
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::Object::Domain> - a module representing a domain name.

=head1 DESCRIPTION

L<Net::RDAP::Object::Domain> represents a domain name - either a
"forward" domain such as C<example.com> or a "reverse" domain such as
C<1.168.192.in-addr.arpa>.

L<Net::RDAP::Object::Domain> inherits from L<Net::RDAP::Object> so has
access to all that module's methods.

Other methods include:

    $name = $domain->name;

Returns a L<Net::DNS::Domain> representing the name of the nameserver.

=cut

sub name { Net::DNS::Domain->new($_[0]->{'ldhName'}) }

=pod

    $name = $domain->unicodeName;

Returns a string containing the DNS Unicode name of the domain (or C<undef>).

=cut

sub unicodeName { $_[0]->{'unicodeName'} }

=pod

    @ns = $domain->nameservers;

Returns a (potentially empty) array of L<Net::RDAP::Object::Nameserver>
objects representing the domain's nameservers.

=cut

sub nameservers { $_[0]->objects('Net::RDAP::Object::Nameserver', $_[0]->{'nameservers'}) }

=pod

    $signed = $domain->zoneSigned;

Returns a true value if the zone has been signed.

    $signed = $domain->delegationSigned;

Returns a true value if true if there are DS records in the parent.

    $time = $domain->maxSigLife;

Returns an integer representing the signature lifetime in seconds to be
used when creating the RRSIG DS record in the parent zone.

=cut

sub zoneSigned          { $_[0]->{'secureDNS'}->{'zoneSigned'} }
sub delegationSigned    { $_[0]->{'secureDNS'}->{'delegationSigned'} }
sub maxSigLife          { $_[0]->{'secureDNS'}->{'maxSigLife'} }

=pod

    my @ds = $domain->ds();

Returns a (potentially empty) array of L<Net::DNS::RR::DS>
objects representing the domain's DS records.

=cut

sub ds {
    my $self = shift;

    my @ds;

    if (defined($self->{'secureDNS'}->{'dsData'})) {
        foreach my $data (@{$self->{'secureDNS'}->{'dsData'}}) {
            push(@ds, Net::DNS::RR->new(sprintf(
                '%s. 1 IN DS %u %u %u %s',
                $self->name->name,
                $data->{'keyTag'},
                $data->{'algorithm'},
                $data->{'digestType'},
                $data->{'digest'},
            )));
        }
    }

    return @ds;
}

=pod

    my @keys = $domain->keys();

Returns a (potentially empty) array of L<Net::DNS::RR::DNSKEY>
objects representing the domain's DNSSEC keys.

=cut

sub keys {
    my $self = shift;

    my @keys;

    if (defined($self->{'secureDNS'}->{'keyData'})) {
        foreach my $data (@{$self->{'secureDNS'}->{'keyData'}}) {
            push(@keys, Net::DNS::RR::DNSKEY->new(sprintf(
                '%s. 1 IN DNSKEY %u %u %u %s',
                $self->name->name,
                $data->{'flags'},
                $data->{'protocol'},
                $data->{'algorithm'},
                $data->{'publicKey'},
            )));
        }
    }

    return @keys;
}

=pod

    $network = $domain->network;

If this domain is a reverse domain, this method will return a
L<Net::RDAP::Object::IPNetwork> object which represents the IP network
corresponding to the domain.

=cut

sub network { Net::RDAP::Obect::IPNetwork->new($_[0]->{'network'}) }

=pod

    my @variants = $domain->variants;

Returns a (potentially empty) array of L<Net::RDAP::Variant> objects
representing variants of the domain name.

=cut

sub variants { $_[0]->objects('Net::RDAP::Variant', $_[0]->{'variants'}) }

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
