package Net::RDAP::Registry::IANARegistry;
use DateTime::Format::ISO8601;
use Net::RDAP::Registry::IANARegistry::Service;
use strict;

=pod

=head1 NAME

L<Net::RDAP::Registry::IANARegistry> - a class which represents an RDAP
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

Returns a L<DateTime> object corresponding to the date and time
that the registry was last updated.

    @services = $registry->services;

Returns an array of L<Net::RDAP::Registry::IANARegistry::Service>
objects corresponding to each of the RDAP services listed in the
registry.

=cut

sub description { $_[0]->{'description'} }
sub version     { $_[0]->{'version'} }
sub publication { DateTime::Format::ISO8601->parse_datetime($_[0]->{'publication'}) }

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

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. All rights reserved.

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