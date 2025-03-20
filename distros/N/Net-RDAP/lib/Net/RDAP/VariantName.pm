package Net::RDAP::VariantName;
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::VariantName> - a module representing a variant name in an
L<Net::RDAP::Variant> object.

=head1 DESCRIPTION

See L<Net::RDAP::Variant> for more information

=head1 METHODS

=cut

sub new {
    my ($package, $ref) = @_;
    return bless($ref, $package);
};

=pod

    $name = $variant->name;

Returns a L<Net::DNS::Domain> object representing the domain name.

=cut

sub name { Net::DNS::Domain->new($_[0]->{'ldhName'}) }

=pod

    $name = $domain->unicodeName;

Returns a string containing the DNS Unicode name of the domain.

=cut

sub unicodeName { $_[0]->{'unicodeName'} }

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
