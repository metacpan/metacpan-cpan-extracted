package OpenStack::MetaAPI::API::Network;

use strict;
use warnings;

use Moo;

extends 'OpenStack::MetaAPI::API::Service';

# roles
with 'OpenStack::MetaAPI::Roles::Listable';
with 'OpenStack::MetaAPI::Roles::GetFromId';

has '+name'           => (default => 'network');
has '+version_prefix' => (default => 'v2.0');
has '+version'        => (default => 'v2');        # use the v2 specs

## FIXME can be defined from specs
sub delete_floatingip {
    my ($self, $uid) = @_;

    my $uri = $self->root_uri('/floatingips/' . $uid);
    return $self->delete($uri);
}

# REQ: curl -g -i -X POST http://service01a-c2.cpanel.net:9696/v2.0/floatingips
# -H "Content-Type: application/json" -H "User-Agent: openstacksdk/0.27.0 keystoneauth1/3.13.1 python-requests/2.21.0 CPython/3.6.6" -H "X-Auth-Token: {SHA256}b0ba0e5595347e63c0b6f56e7f035977abe209f6fa034f41f7dfe491e6e984a1" -d '{"floatingip": {"floating_network_id": "8a10163f-072c-483a-9834-78395cf8a2e7"}}'

sub create_floating_ip {
    my ($self, $network_id) = @_;

    die "Missing network_id" unless defined $network_id;

    my $uri    = $self->root_uri('/floatingips');
    my $answer = $self->post(
        $uri,
        {floatingip => {floating_network_id => $network_id}});

    return $answer->{floatingip} if ref $answer && $answer->{floatingip};
    return $answer;
}

sub add_floating_ip_to_server {
    my ($self, $floatingip_id, $server_id) = @_;

    die "floatingip_id is required" unless defined $floatingip_id;
    die "server_id is required"     unless defined $server_id;

    my $uri = $self->root_uri('/ports');
    my $ports = $self->get($uri, device_id => $server_id);

    # pick the first port for now (maybe need to check the network_id...)
    my $port_id = eval { $ports->{ports}->[0]->{id} };
    die "Cannot find a port for server $server_id: $@" unless defined $port_id;

    # now link the floating ip to the port
    return $self->put(
        $self->root_uri('/floatingips/' . $floatingip_id),
        {floatingip => {port_id => $port_id}});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::API::Network

=head1 VERSION

version 0.003

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
