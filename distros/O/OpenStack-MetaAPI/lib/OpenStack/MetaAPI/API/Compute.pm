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
# delete floating ips for all ports on this device (supports multi-homed VMs)
        my @ports_for_device = $api->ports(device_id => $uid);
        for my $port (@ports_for_device) {
            next unless ref $port && $port->{id};

            my $floatingip = $api->floatingips(port_id => $port->{id});
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

# What this project may have, and what it is already using.
#
# Both halves arrive in one response, which is what makes this the right thing
# to ask when deciding whether another guest fits.  /os-quota-sets gives only
# the allowance, leaving you to add the usage up yourself from the server list.
sub limits {
    my ($self) = @_;

    my $out = $self->get($self->root_uri('/limits'));

    return ref $out ? $out->{limits} : $out;
}

# Everything Nova models as an action on an existing server: snapshots, power
# state, rebuild.  They are all one POST to the same place with a different
# single-key body, so they are all this.
sub server_action {
    my ($self, $uid, $action) = @_;

    die "server id is required by server_action" unless defined $uid && length $uid;
    die "action must be a hash reference"        unless ref $action eq 'HASH';

    return $self->post($self->root_uri("/servers/$uid/action"), $action);
}

# Snapshot a server into a Glance image.
#
# Nova returns the new image's id in the Location header, and only puts it in
# the body from microversion 2.45 on -- so neither is worth relying on.  Ask
# Glance for the name afterwards instead.
sub create_image {
    my ($self, $uid, %opts) = @_;

    my $name = delete $opts{name};
    die "'name' is required by create_image" unless defined $name && length $name;

    return $self->server_action($uid, {createImage => {name => $name, %opts}});
}

# The flavor list is names and ids; this is the one that knows how many CPUs.
sub flavors_detail {
    my ($self, %filter) = @_;

    my $out = $self->get($self->root_uri('/flavors/detail'));
    my @all = ref $out ? @{$out->{flavors} // []} : ();

    foreach my $key (sort keys %filter) {
        @all = grep { defined $_->{$key} && $_->{$key} eq $filter{$key} } @all;
    }

    return @all;
}

# What the guest wrote to its serial console.  When a guest never comes up this
# is usually the only thing that says why.
sub console_output {
    my ($self, $uid, $length) = @_;

    my $out = $self->server_action($uid, {'os-getConsoleOutput' => {length => $length}});

    return ref $out ? $out->{output} : $out;
}

# Volumes are Cinder's, but attaching one to a server is Nova's.
sub server_volumes {
    my ($self, $uid) = @_;

    my $out = $self->get($self->root_uri("/servers/$uid/os-volume_attachments"));

    return ref $out ? @{$out->{volumeAttachments} // []} : ();
}

sub attach_volume {
    my ($self, $uid, $volume_id, %opts) = @_;

    die "volume id is required by attach_volume" unless defined $volume_id && length $volume_id;

    my $out = $self->post(
        $self->root_uri("/servers/$uid/os-volume_attachments"),
        {volumeAttachment => {volumeId => $volume_id, %opts}});

    return ref $out ? $out->{volumeAttachment} : $out;
}

sub detach_volume {
    my ($self, $uid, $volume_id) = @_;

    die "volume id is required by detach_volume" unless defined $volume_id && length $volume_id;

    return $self->delete($self->root_uri("/servers/$uid/os-volume_attachments/$volume_id"));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::API::Compute

=head1 VERSION

version 0.004

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
