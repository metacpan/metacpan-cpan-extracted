package OpenStack::MetaAPI::API::Specs::Network::v2;

use strict;
use warnings;

use Moo;

with 'OpenStack::MetaAPI::API::Specs::Roles::Service';

#
# API specs: incomplete need to be continued
# url:
#   https://developer.openstack.org/api-ref/network/v2/index.html?expanded=list-ports-detail#ports
#

1;

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::API::Specs::Network::v2

=head1 VERSION

version 0.003

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
---
get:
  /v2.0/floatingips:
    perl_api:
      method: floatingips
      type: listable
      listable_key: floatingips
    request:
      query: {}
  /v2.0/networks:
    perl_api:
      method: networks
      type: listable
      listable_key: networks
    request:
      query: {}
  /v2.0/security-groups:
    perl_api:
      method: security_groups
      type: listable
      listable_key: security_groups
    request:
      query: {}
  /v2.0/ports:
    perl_api:
      method: ports
      type: listable
      listable_key: ports
    request:
      query:
        admin_state_up:
          type: boolean
        binding:host_id: {}
        description: {}
        device_id: {}
        device_owner: {}
        fixed_ips: {}
        id: {}
        ip_allocation: {}
        mac_address: {}
        name: {}
        network_id: {}
        prokect_id: {}
        revision_number: {}
        sort_dir: {}
        sort_key: {}
        status: {}
        tenant_id: {}
        tags: {}
        tags-any: {}
        not-tags: {}
        not-tags-any: {}
        fields: {}
        mac_learning_enabled:
          type: boolean
put:
  /v2.0/ports/{port_id}:
    perl_api:
      method: port_from_uid
      type: getfromid
      uid: '{port_id}'
    request:
      path:
        port_id:
          required: 1
      body:
        port:
          required: 1
        admin_state_up: {}
        allowed_address_pairs:
          type: array
        binding:host_id: {}
        binding:profile:
          type: object
        binding:vnic_type: {}
        data_plane_status: {}
        description: {}
        device_id: {}
        device_owner: {}
        dns_domain: {}
        dns_name: {}
        extra_dhcp_opts:
          type: array
