package OpenStack::MetaAPI::API::Specs::Compute::v2_1;

use strict;
use warnings;

use Moo;

with 'OpenStack::MetaAPI::API::Specs::Roles::Service';

1;

#
# API specs: incomplete need to be continued
# url:
#   https://developer.openstack.org/api-ref/network/v2/index.html?expanded=list-ports-detail#ports
#

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::API::Specs::Compute::v2_1

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
get:
  /servers/{server_id}:
    perl_api:
      method: server_from_uid
      type: getfromid
      uid: '{server_id}'
    request:
      path:
        server_id:
          required: 1
  /servers:
    perl_api:
      method: servers
      type: listable
      listable_key: 'servers'
    request:
      query:
        host: {}
        flavor: {}
        hostname: {}
        image: {}
        ip: {}
  /flavors:
    perl_api:
      method: flavors
      type: listable
      listable_key: 'flavors'
    request:
      query:
        sort_key: {}
        sort_dir: {}
        limit: {}
        marker: {}
        minDisk: {}
        minRam: {}
        isPublic: {}
  /os-keypairs:
    perl_api:
      method: keypairs
      type: listable
      listable_key: 'keypairs'
    request:
      query:
        user_id: {}
        limit: {}
        marker: {}
delete:
  /server/{server_id}:
    perl_api:
      method: delete_server_from_uid
      type: getfromid
      uid: '{server_id}'
    request:
      path:
        server_id:
          required: 1
