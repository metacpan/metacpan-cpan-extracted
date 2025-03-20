package Net::RDAP::Registry::IANARegistry;
use DateTime::Tiny;
use Net::RDAP::Registry::IANARegistry::Service;
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::Registry::IANARegistry> - a module which represents an RDAP
bootstrap registry.

=head1 DESCRIPTION

The IANA maintains a set of RDAP boostrap registries for IPv4 and IPv6
address blocks, top-level domains, AS number ranges, and object tags.

This class represents these registries.

This class is used internally by L<Net::RDAP::Registry>.

=head1 CONSTRUCTOR

    $registry = Net::RDAP::Registry::IANARegistry->new($data);

C<$data> is a hashref corresponding to the decoded JSON representation
of the IANA registry.

=cut

sub new {
    my ($package, $args, $url) = @_;
    my %self = %{$args};
    return bless(\%self, $package);
}

=pod

=head1 METHODS

    $description = $registry->description;

Returns a string containing the description of the registry.

    $version = $registry->version;

Returns a string containing the version of the registry.

    $date = $registry->publication;

Returns a L<DateTime::Tiny> object corresponding to the date and time
that the registry was last updated. The C<publication_tz()> method returns the
time zone portion of the publication date.

Prior to Net::RDAP v0.35, this method returned a L<DateTime>, but this was
switched to L<DateTime::Tiny> for performance reasons. If you need a
L<DateTime>, use C<$event-E<gt>date-E<gt>DateTime>.

    @services = $registry->services;

Returns an array of L<Net::RDAP::Registry::IANARegistry::Service>
objects corresponding to each of the RDAP services listed in the
registry.

=cut

sub description     { $_[0]->{'description'} }
sub version         { $_[0]->{'version'} }
sub publication     { DateTime::Tiny->from_string(substr($_[0]->{'publication'}, 0, 19)) }

sub publication_tz  {
    my $str = substr(shift->{publication}, 19);
    $str =~ s/^\.\d+//g;
    return $str;
}

sub services {
    my $self = shift;
    my @services;

    foreach my $svc (@{$self->{'services'}}) {
        push(@services, Net::RDAP::Registry::IANARegistry::Service->new(@{$svc}));
    }

    return @services;
}

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
