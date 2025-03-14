package Net::RDAP::Service;
use Storable qw(dclone);
use Net::RDAP;
use strict;
use warnings;

sub new {
    my ($package, $base, $client) = @_;
    return bless({
        'base'      => $base->isa('URI') ? $base : URI->new($base),
        'client'    => $client || Net::RDAP->new,
    }, $package);
}

sub new_for_tld {
    my ($package, $tld) = @_;

    foreach my $service (Net::RDAP::Registry->load_registry(Net::RDAP::Registry::DNS_URL)->services) {
        foreach my $zone ($service->registries) {
            if (lc($zone) eq lc($tld)) {
                return $package->new(Net::RDAP::Registry->get_best_url($service->urls));
            }
        }
    }

    return undef;
}

sub fetch {
    my ($self, $type, $segments, %params) = @_;

    my $uri = dclone($self->base);

    $uri->path_segments(grep { defined && length > 0 } (
        $uri->path_segments,
        $type,
        'ARRAY' eq ref($segments) ? @{$segments} : $segments
    ));

    $uri->query_form(%params);

    my %opt;
    $opt{'class_override'} = 'help' if ('help' eq $type);

    return $self->client->fetch($uri, %opt);
}

sub base        { shift->{'base'}                                     }
sub client      { shift->{'client'}                                   }
sub help        { shift->fetch('help'                               ) }
sub domain      { shift->fetch('domain',        pop->name           ) }
sub ip          { shift->fetch('ip',            pop->prefix         ) }
sub autnum      { shift->fetch('autnum',        pop->toasplain      ) }
sub entity      { shift->fetch('entity',        pop->handle         ) }
sub nameserver  { shift->fetch('nameserver',    pop->name           ) }
sub domains     { shift->fetch('domains',       [], @_              ) }
sub nameservers { shift->fetch('nameservers',   [], @_              ) }
sub entities    { shift->fetch('entities',      [], @_              ) }

1;

__END__

=pod

=head1 NAME

L<Net::RDAP::Service> - a module which provides an interface to an RDAP server.

=head1 SYNOPSIS

    use Net::RDAP::Service;

    #
    # create a new service object:
    #

    my $svc = Net::RDAP::Service->new('https://www.example.com/rdap');

    #
    # get a domain:
    #

    my $domain = $svc->domain(Net::DNS::Domain->new('example.com'));

    #
    # do a search:
    #

    my $result = $svc->domains('name' => 'ex*mple.com');

    #
    # get help:
    #

    my $help = $svc->help;

=head1 DESCRIPTION

While L<Net::RDAP> provides a unified interface to the universe of
RIR, domain registry, and domain registrar RDAP services,
L<Net::RDAP::Service> provides an interface to a specify RDAP service.

You can do direct lookup of objects using methods of the same name that
L<Net::RDAP> provides. In addition, this module allows you to perform
searches.

=head1 METHODS

=head2 Constructor

    my $svc = Net::RDAP::Service->new($url);

Creates a new L<Net::RDAP::Service> object. C<$url> is a string or a
L<URI> object representing the base URL of the service.

You can also provide a second argument which should be an existing
L<Net::RDAP> instance. This is used when fetching resources from the
server.

=head3 TLD Service Constructor

    my $svc = Net::RDAP::Service->new_for_tld($tld);

This method searches the IANA registry for an entry for the TLD in C<$tld> and
returns the corresponding L<Net::RDAP::Service> object.

=head2 Lookup Methods

You can do direct lookups of objects using the following methods:

=over

=item * C<domain()>

=item * C<ip()>

=item * C<autnum()>

=item * C<entity()>

=item * C<nameserver()>

=back

They all work the same way as the methods of the same name on
L<Net::RDAP>.

=head2 Search Methods

You can perform searches using the following methods. Note that
different services will support different search functions.

    $result = $svc->domains(%QUERY);

    $result = $svc->entities(%QUERY);

    $result = $svc->nameservers(%QUERY);

In all cases, C<%QUERY> is a set of search parameters. Here are some
examples:

    $result = $svc->domains('name' => 'ex*mple.com');

    $result = $svc->entities('fn' => 'Ex*ample, Inc');

    $result = $svc->nameservers('ip' => '192.168.0.1');

The following parameters can be specified:

=over

=item * domains: C<name> (domain name), C<nsLdhName> (nameserver
name), C<nsIp> (nameserver IP address)

=item * nameservers: C<name> (host name), C<ip> (IP address)

=item * entities: C<handle>, C<fn> (Formatted Name)

=back

Search parameters can contain the wildcard character "*" anywhere
in the string.

These methods all return L<Net::RDAP::SearchResult> objects.

=head2 Help

Each RDAP server has a "help" endpoint which provides "helpful
information" (command syntax, terms of service, privacy policy,
rate-limiting policy, supported authentication methods, supported
extensions, technical support contact, etc.). This information may be
obtained by performing a C<help> query:

    my $help = $svc->help;

The return value is a L<Net::RDAP::Help> object.

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
