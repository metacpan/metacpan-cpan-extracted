package OpenStack::MetaAPI::Routes;

use strict;
use warnings;

use Moo;

use OpenStack::MetaAPI::API ();
use YAML::XS;

use OpenStack::MetaAPI::Helpers::DataAsYaml;

has 'auth' => (is => 'ro');
has 'api'  => (is => 'ro');

our $ROUTES;

sub init_once {
    $ROUTES //= OpenStack::MetaAPI::Helpers::DataAsYaml::LoadData();
}

# cannot read from data block at compile time
#INIT { init_once() }

sub list_all {
    init_once();
    return sort keys %$ROUTES;
}

sub DESTROY {
}

our $AUTOLOAD;

sub AUTOLOAD {
    my (@args) = @_;
    my $call_for = $AUTOLOAD;

    $call_for =~ s/.*:://;

    if (my $route = $ROUTES->{$call_for}) {
        die "$call_for is a method call" unless ref $args[0] eq __PACKAGE__;
        my $self = shift @args;

        my $service = $self->service($route->{service});

        # not easy to overwrite can if Moo/XS::Accessor
        my $controller = $service->can_method($call_for);

        die "Invalid route '$call_for' for service '" . ref($service) . "'"
          unless defined $controller;

        return $controller->($service, @args);
    }

    die "Unknown function $call_for from AUTOLOAD";
}

sub service {
    my ($self, $name) = @_;

    # cache the service once
    my $k = '_service_' . $name;
    if (!$self->{$k}) {
        $self->{$k} = OpenStack::MetaAPI::API::get_service(
            name   => $name, auth => $self->auth,
            region => $ENV{'OS_REGION_NAME'},

            # backreference
            api => $self->api,
        );
    }

    return $self->{$k};
}

1;

## this data block describes the routes
#   this could be moved to a file...

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::Routes

=head1 VERSION

version 0.002

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
---
keypairs:
  service: compute
flavors:
  service: compute
servers:
  service: compute
delete_server:
  service: compute
server_from_uid:
  service: compute
create_server:
  service: compute
networks:
  service: network
add_floating_ip_to_server:
  service: network
floatingips:
  service: network
ports:
  service: network
delete_floatingip:
  service: network
port_from_uid:
  service: network
security_groups:
  service: network
create_floating_ip:
  service: network
image_from_uid:
  service: images
image_from_name:
  service: images


