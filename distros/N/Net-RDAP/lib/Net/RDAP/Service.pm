package Net::RDAP::Service;
use Carp;
use List::Util qw(any);
use Net::RDAP;
use Storable qw(dclone);
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

#
# generate a URL given the params and fetch it. $type and $segments are used as
# path segments ($segments must be an arrayref, and may be empty). %args is used
# to construct query parameters.
#
sub fetch {
    my ($self, $type, $segments, %params) = @_;

    my $uri = dclone($self->base);

    $uri->path_segments(grep { defined && length > 0 } (
        $uri->path_segments,
        $type,
        @{$segments},
    ));

    $uri->query_form(%params);

    my %opt;
    $opt{'class_override'} = 'help' if ('help' eq $type);

    return $self->client->fetch($uri, %opt);
}

sub search {
    my ($self, $type, %params) = @_;

    if ('HASH' eq ref($params{entity})) {
        return $self->reverse_search($type, %{$params{entity}});

    } elsif ('ips' eq $type && (any { exists($params{$_}) } qw(up down top bottom))) {
        return $self->rir_reverse_search($type, %params);

    } else {
        return $self->fetch($type, undef, %params);

    }
}

sub reverse_search {
    my ($self, $type, %params) = @_;

    return $self->fetch($type, [qw(reverse_search entity)], %params);
}

sub rir_reverse_search {
    my ($self, $type, %params) = @_;

    my @rels = qw(up down top bottom);

    foreach my $rel (@rels) {
        if (exists($params{$rel})) {
            # remove this and any other relation
            map { delete($params{$_}) if (exists($params{$_})) } @rels;

            return $self->fetch('ips', ['rirSearch1', $rel], %params);
        }
    }

    return undef;
}

sub base        { shift->{'base'} }
sub client      { shift->{'client'} }

sub help        { shift->fetch('help',          []                  ) }
sub domain      { shift->fetch('domain',        [ pop->name      ]  ) }
sub ip          { shift->fetch('ip',            [ pop->prefix    ]  ) }
sub autnum      { shift->fetch('autnum',        [ pop->toasplain ]  ) }
sub entity      { shift->fetch('entity',        [ pop->handle    ]  ) }
sub nameserver  { shift->fetch('nameserver',    [ pop->name      ]  ) }

sub domains     { shift->search('domains',      @_                  ) }
sub nameservers { shift->search('nameservers',  @_                  ) }
sub entities    { shift->search('entities',     @_                  ) }
sub ips         { shift->search('ips',          @_                  ) }
sub autnums     { shift->search('autnums',      @_                  ) }

sub implements {
    my ($self, $token) = @_;

    my $help = $self->help;

    croak($help->title) if ($help->isa('Net::RDAP::Error'));

    my @tokens = $help->conformance;
    croak('Missing or empty rdapConformance property') if (scalar(@tokens) < 1);

    return any { $_ eq $token } @tokens;
}

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

While L<Net::RDAP> provides a unified interface to the universe of RIR, domain
registry, and domain registrar RDAP services, L<Net::RDAP::Service> provides an
interface to a specific RDAP service.

You can do direct lookup of objects using methods of the same name that
L<Net::RDAP> provides. In addition, this module allows you to perform searches.

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

    $result = $svc->ips(%QUERY);

    $result = $svc->autnums(%QUERY);

In all cases, C<%QUERY> is a set of search parameters. Here are some
examples:

    $result = $svc->domains(name => 'ex*mple.com');

    $result = $svc->entities(fn => 'Ex*ample, Inc');

    $result = $svc->nameservers(ip => '192.0.2.1');

    $result = $svc->ips(handle => 'FOOBAR-RIR');

    $result = $svc->autnums(handle => 'FOOBAR-RIR');

=head3 References

=over

=item * Domain search: L<Section 3.2.1 of RFC 9083|https://www.rfc-editor.org/rfc/rfc9082.html#section-3.2.1>

=item * Nameserver search: L<Section 3.2.2 of RFC 9083|https://www.rfc-editor.org/rfc/rfc9082.html#section-3.2.2>

=item * Entity search: L<Section 3.2.3 of RFC 9083|https://www.rfc-editor.org/rfc/rfc9082.html#section-3.2.3>

=item * "Reverse" search: L<RFC 9536|https://www.rfc-editor.org/rfc/rfc9536.html>

=item * IP search (B<EXPERIMENTAL>): L<Section 2.2 of draft-ietf-regext-rdap-rir-search-11|https://www.ietf.org/archive/id/draft-ietf-regext-rdap-rir-search-11.html#section-2.2>

=item * AS number search (B<EXPERIMENTAL>): L<Section 2.3 of draft-ietf-regext-rdap-rir-search-11|https://www.ietf.org/archive/id/draft-ietf-regext-rdap-rir-search-11.html#section-2.3>

=back

Note that not all RDAP servers support all search types or parameters.

The following parameters can be specified:

=over

=item * domains: C<name> (domain name), C<nsLdhName> (nameserver
name), C<nsIp> (nameserver IP address)

=item * nameservers: C<name> (host name), C<ip> (IP address)

=item * entities: C<handle>, C<fn> (Formatted Name)

=item * ips: C<handle>, C<name>

=item * autnums: C<handle>, C<name>

=back

Search parameters can contain the wildcard character "*" anywhere
in the string.

These methods all return L<Net::RDAP::SearchResult> objects.

=head2 "Reverse" Search

B<IMPORTANT NOTE:> due to a lack of server implementations to test against,
reverse search. functionality is I<experimental> and should not be relied upon
in production code.

Some RDAP servers implement "reverse search" which is specified in L<RFC
9536|https://www.rfc-editor.org/rfc/rfc9536.html>. This allows you to search for
objects based on their relationship to some other object: for example, to search
for domains that have a relationship to a specific entity.

To perform a reverse search (on a server that supports this), pass a set of
query parameters using the C<entity> parameter:

    $result = $svc->domains(entity => { handle => 9999 });

=head3 RIR Relation Searches

L<Section 3 of draft-ietf-regext-rdap-rir-search-11|https://www.ietf.org/archive/id/draft-ietf-regext-rdap-rir-search-11.html#section-3>
describes searches and link relations for finding objects and sets of objects
with respect to their position within a hierarchy.

Some examples:

    $svc->ips(up => q{2001:DB8::42});

Since this specification is in draft, this functionality may change
significantly in future versions of this module.

=head2 Help

Each RDAP server has a "help" endpoint which provides "helpful
information" (command syntax, terms of service, privacy policy,
rate-limiting policy, supported authentication methods, supported
extensions, technical support contact, etc). This information may be
obtained by performing a C<help> query:

    my $help = $svc->help;

The return value is a L<Net::RDAP::Help> object.

=head2 Extension Implementation

You can determine if an RDAP server implements a particular RDAP extension using
C<implements()>:

    $svc->implements('lunarNic');

This will return a true value if the RDAP server advertises support for the
C<lunarNic> extension. This methods works by checking the "help" response, and
will throw an exception if the help request fails.

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
