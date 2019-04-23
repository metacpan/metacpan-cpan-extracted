package OpenStack::MetaAPI::API::Compute;

use strict;
use warnings;

use Moo;

# use Client::Lite::API role
#with 'OpenStack::MetaAPI::API'; ...

extends 'OpenStack::MetaAPI::API::Service';

# roles
#with    'OpenStack::MetaAPI::Roles::DataAsYaml';
with 'OpenStack::MetaAPI::Roles::Listable';
with 'OpenStack::MetaAPI::Roles::GetFromId';

has '+name' => (default => 'compute');

sub delete_server {
    my ($self, $uid) = @_;

    # first check that the server exists
    my $server = $self->api->server_from_uid($uid);
    return unless ref $server && $server->{id} eq $uid;

    my $api = $self->api;
    {
# delete floating ip for device [maybe provide its own helper at the main level of API]
        my $port_for_device = $api->ports(device_id => $uid);
        if ($port_for_device && $port_for_device->{id}) {

            my $port_id = $port_for_device->{id};
            my $floatingip = $api->floatingips(port_id => $port_id);

            if ($floatingip && $floatingip->{id}) {
                $api->delete_floatingip($floatingip->{id});
            }
        }
    }

    # maybe need to wait?
    my $uri = $self->root_uri('/servers/' . $uid);
    return $self->delete($uri);
}

#  FIXME should be generated from specs
sub create_server {
    my ($self, %opts) = @_;

    my $uri = $self->root_uri('/servers/');
    my $output = $self->post($uri, {server => {%opts}});
    return $output->{server} if ref $output;
    return $output;
}

### helpers

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::API::Compute

=head1 VERSION

version 0.002

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
