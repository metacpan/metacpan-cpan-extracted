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

sub base        { $_[0]->{'base'}   }
sub client      { $_[0]->{'client'} }
sub help        { $_[0]->fetch('help'                               ) }
sub domain      { $_[0]->fetch('domain',        $_[1]->name         ) }
sub ip          { $_[0]->fetch('ip',            $_[1]->prefix       ) }
sub autnum      { $_[0]->fetch('autnum',        $_[1]->toasplain    ) }
sub entity      { $_[0]->fetch('entity',        $_[1]->handle       ) }
sub nameserver  { $_[0]->fetch('nameserver',    $_[1]->name         ) }
sub domains     { $_[0]->fetch('domains',       undef, $_[1] => $_[2]) }
sub nameservers { $_[0]->fetch('nameservers',   undef, $_[1] => $_[2]) }
sub entities    { $_[0]->fetch('entities',      undef, $_[1] => $_[2]) }

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
