package Net::RDAP::Registry::IANARegistry::Service;
use URI;
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::Registry::IANARegistry::Service> - a module which represents
an RDAP service in an IANA bootstrap registry.

=head1 DESCRIPTION

Each of the entries in an IANA RDAP Bootstrap registry represen a
specific RDAP service that corresponds to the unique identifiers
associated with that entry (e.g. top-level domains, IP blocks, or AS
number ranges).

This class provides a representation of these entries.

This class is used internally by L<Net::RDAP::Registry>.

=head1 CONSTRUCTOR

The constructor accepts two or three arguments:

    $svc = Net::RDAP::Registry::IANARegistry::Service->new(
        $registryref,
        $urlref,
    );

    # or:

    $svc = Net::RDAP::Registry::IANARegistry::Service->new(
        $registrant,
        $registryref,
        $urlref,
    );

=over

=item * C<$registrant> is the email address of the registrant of the
service.

=item * C<$registryref> is a reference to an array of "registries",
i.e. top-level domains, IP address blocks, ASN ranges, or object
tags.

=item * C<$urlref> is a reference to an array of RDAP base URLs.

=back

=cut

sub new {
    my ($package, @args) = @_;
    my $self = bless({}, $package);

    # populate object proprties from @args, right to left:
    $self->{'urls'} = pop(@args);
    $self->{'registries'} = pop(@args);
    $self->{'registrant'} = pop(@args); # may be undefined

    return $self;
}

=pod

=head1 METHODS

    @urls = $svc->urls;

This method returns an array of C<URI> objects representing the
RDAP base URL(s) for the RDAP service.

    @registries = $svc->registries;

This method returns an array of "registries" (TLDs, IP blocks,
ASN ranges, etc) for which the RDAP service is authoritatie.

    $registrant = $svc->registrant;

This method returns the registrant of the entry into the
registry. This is typically an email address. Note that as of
writing, only entries in the Object Tag registry have registrants.

=cut

sub urls { map { URI->new($_) } @{$_[0]->{'urls'}} }
sub registries { @{$_[0]->{'registries'}} }
sub registrant { $_[0]->{'registries'} }

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
