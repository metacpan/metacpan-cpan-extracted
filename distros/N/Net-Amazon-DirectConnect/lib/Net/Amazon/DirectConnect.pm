package Net::Amazon::DirectConnect;

use 5.10.0;
use strict;
use warnings FATAL => 'all';

use Carp;
use JSON;
use YAML::Tiny;
use HTTP::Request;
use LWP::UserAgent;
use Net::Amazon::Signature::V4;

my $yaml = YAML::Tiny->read_string(do { local $/; <DATA> });
close(DATA);

=head1 NAME

Net::Amazon::DirectConnect - Perl interface to the Amazon DirectConnect API

=head1 VERSION

Version 0.13
DirectConnect API version 2012-10-25

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

    use Net::Amazon::DirectConnect;

    my $dc = Net::Amazon::DirectConnect->new(
        region => 'ap-southeast-2',
        access_key_id => 'access key',
        secret_key_id => 'secret key'
    );
    ...

=head1 SUBROUTINES/METHODS

=head2 new

    use Net::Amazon::DirectConnect;

    my $dc = Net::Amazon::DirectConnect->new(
        region => 'ap-southeast-2',
        access_key_id => 'access key',
        secret_key_id => 'secret key'
    );
    ...

=cut

sub new {
    my $self = bless {}, shift;
    return unless @_ % 2 == 0;

    my %args = @_;

    my %defaults = (
        region => 'us-west-1',
        access_key_id => $ENV{AWS_ACCESS_KEY_ID},
        secret_key_id => $ENV{AWS_SECRET_ACCESS_KEY},

        _ua => LWP::UserAgent->new(agent => __PACKAGE__ . '/' . $VERSION),
        _yaml => $yaml,
    );

    foreach (keys %defaults) {
        $self->{$_} = exists $args{$_} ? $args{$_} : $defaults{$_};
    }

    $self->{sig} = Net::Amazon::Signature::V4->new($self->{access_key_id}, $self->{secret_key_id}, $self->{region}, 'directconnect');

    return $self;
}

=head2 action

Perform action against the Amazon Direct Connect API. Actions are validated against an embedded copy of
DirectConnect-2012-10-25.yml for correctness before the call is made.

    # List connections
    my $connections = $dc->action('DescribeConnections');

    foreach my $dxcon (@{$connections->{connections}}) {
        say "$dxcon->{connectionId} -> $dxcon->{connectionName}";

        # List Virtual Interfaces
        my $virtual_interfaces = $dc->action('DescribeVirtualInterfaces', connectionId => $dxcon->{connectionId});
        foreach my $vif (@{$virtual_interfaces->{virtualInterfaces}}) {
            say "  $vif->{connectionId}";
        }
    }

=cut

sub action {
    my $self = shift;
    my $method = shift;
    return unless @_ % 2 == 0;
    my %args = @_;

    $self->_validate($method, \%args);

    my $response = $self->_request($method,
        content => encode_json \%args
    );

    return decode_json $response->content if $response->is_success;
}

=head2 ua

Get or set UserAgent object

    say ref($dc->ua);
    my $ua = my $lwp = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
    $ua->proxy('https', 'http://127.0.0.1:8080');
    $dc->ua($ua);

=cut

sub ua {
    ( ref $_[1] ) ? shift->{_ua} = $_[1] : shift->{_ua};
}

=head2 spec

Get or set YAML::Tiny object

    say ref($dc->spec);
    $dc->spec(YAML::Tiny->read('new-spec.yml'));

=cut

sub spec {
    ( ref $_[1] ) ? shift->{_yaml} = $_[1] : shift->{_yaml}->[0];
}

=head2 region

Get or set AWS region

    $dc->region('ap-southeast-2');
    say $dc->region;

=cut

sub region {
    my $self = shift;

    if (exists $_[0]) {
        $self->{region} = shift;
        $self->{sig} = Net::Amazon::Signature::V4->new($self->{access_key_id}, $self->{secret_key_id}, $self->{region}, 'directconnect');
    }

    return $self->{region};
}

=head2 credentials

Set AWS credentials

    $dc->credentials(
        access_key_id => 'MY_ACCESS_KEY',
        secret_key_id => 'MY_SECRET_KEY'
    );

=cut

sub credentials {
    my $self = shift;

    return unless @_ % 2 == 0;
    my %args = @_;

    foreach (qw(access_key_id secret_key_id)) {
        $self->{$_} = $args{$_};
    }

    return 1;
}

=head1 Internal subroutines

=head2 _request

Build and sign HTTP::Request object, return if successful or croak if error

=cut

sub _request {
    my $self = shift;
    my $operation = shift;
    return unless @_ % 2 == 0;
    my %args = @_;

    croak __PACKAGE__ . '->_request: Missing operation' unless $operation;
    croak __PACKAGE__ . '->_request: Invalid or empty region' unless $self->{region};

    my $host = sprintf 'directconnect.%s.amazonaws.com/', $self->{region};
    my $headers = [
        Version => $self->spec->{api_version},
        Host => $host,
        Date => POSIX::strftime( '%Y%m%dT%H%M%SZ', gmtime ),
        'Content-Type' => 'application/x-amz-json-1.1',
        'X-Amz-Target' => $self->spec->{target_prefix} . $operation,
        exists $args{headers} ? @{$args{headers}} : ()
    ];

    my $req = HTTP::Request->new(POST => "https://$host", $headers);
    $req->content($args{content}) if exists $args{content};

    $req = $self->{sig}->sign($req);

    my $response = $self->ua->request($req);
    if (!$response->is_success) {

        my $content = eval { decode_json($response->content) };
        $content ||= {};

        my $err_string = '';
        $err_string .= $content->{__type} if $content->{__type};
        $err_string .= ' ' . $content->{message} if $content->{message};
        $err_string = $response->content unless $err_string;

        croak __PACKAGE__ . sprintf('->_request: %s', $err_string);
    }

    return $response;
}

=head2 _validate

Validate the method and required arguments against the current version of the Direct Connect API (2012-10-25)

=cut

sub _validate {
    my $self = shift;
    my $method = shift;
    my $args = shift;

    my ($spec) = grep { $_->{name} eq $method } @{$self->spec->{operations}};
    return unless ref $spec;

    local *check_yaml = sub {
        my $s = shift;
        my $o = shift;

        foreach (keys %$s) {
            if (grep /^required$/, @{$s->{$_}}) {
                croak __PACKAGE__ . ": $method called without required field ($_)" unless exists $o->{$_};
            }

            if (ref $s->{$_}->[0] eq 'HASH') {
                return unless check_yaml($s->{$_}->[0]->{structure}, $o->{$_});
            }
        }

        return 1;
    };

    return check_yaml($spec->{inputs}, $args);
}

=head1 AUTHOR

Cameron Daniel, C<< <cameron.daniel at megaport.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command or at https://github.com/megaport/p5-net-amazon-directconnect/

    perldoc Net::Amazon::DirectConnect

=cut

1;

__DATA__
# Copyright 2011-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

---
json_version: '1.1'
target_prefix: OvertureService.
api_version: '2012-10-25'
operations:
- name: AllocateConnectionOnInterconnect
  method: allocate_connection_on_interconnect
  inputs:
    bandwidth:
    - string
    - required
    connectionName:
    - string
    - required
    ownerAccount:
    - string
    - required
    interconnectId:
    - string
    - required
    vlan:
    - integer
    - required
  outputs:
    ownerAccount:
      sym: owner_account
      type: string
    connectionId:
      sym: connection_id
      type: string
    connectionName:
      sym: connection_name
      type: string
    connectionState:
      sym: connection_state
      type: string
    region:
      sym: region
      type: string
    location:
      sym: location
      type: string
    bandwidth:
      sym: bandwidth
      type: string
    vlan:
      sym: vlan
      type: integer
    partnerName:
      sym: partner_name
      type: string
- name: AllocatePrivateVirtualInterface
  method: allocate_private_virtual_interface
  inputs:
    connectionId:
    - string
    - required
    ownerAccount:
    - string
    - required
    newPrivateVirtualInterfaceAllocation:
    - structure:
        virtualInterfaceName:
        - string
        - required
        vlan:
        - integer
        - required
        asn:
        - integer
        - required
        authKey:
        - string
        amazonAddress:
        - string
        customerAddress:
        - string
    - required
  outputs:
    ownerAccount:
      sym: owner_account
      type: string
    virtualInterfaceId:
      sym: virtual_interface_id
      type: string
    location:
      sym: location
      type: string
    connectionId:
      sym: connection_id
      type: string
    virtualInterfaceType:
      sym: virtual_interface_type
      type: string
    virtualInterfaceName:
      sym: virtual_interface_name
      type: string
    vlan:
      sym: vlan
      type: integer
    asn:
      sym: asn
      type: integer
    authKey:
      sym: auth_key
      type: string
    amazonAddress:
      sym: amazon_address
      type: string
    customerAddress:
      sym: customer_address
      type: string
    virtualInterfaceState:
      sym: virtual_interface_state
      type: string
    customerRouterConfig:
      sym: customer_router_config
      type: string
    virtualGatewayId:
      sym: virtual_gateway_id
      type: string
    routeFilterPrefixes:
      sym: route_filter_prefixes
      type: hash
      members:
        cidr:
          sym: cidr
          type: string
- name: AllocatePublicVirtualInterface
  method: allocate_public_virtual_interface
  inputs:
    connectionId:
    - string
    - required
    ownerAccount:
    - string
    - required
    newPublicVirtualInterfaceAllocation:
    - structure:
        virtualInterfaceName:
        - string
        - required
        vlan:
        - integer
        - required
        asn:
        - integer
        - required
        authKey:
        - string
        amazonAddress:
        - string
        - required
        customerAddress:
        - string
        - required
        routeFilterPrefixes:
        - list:
          - structure:
              cidr:
              - string
        - required
    - required
  outputs:
    ownerAccount:
      sym: owner_account
      type: string
    virtualInterfaceId:
      sym: virtual_interface_id
      type: string
    location:
      sym: location
      type: string
    connectionId:
      sym: connection_id
      type: string
    virtualInterfaceType:
      sym: virtual_interface_type
      type: string
    virtualInterfaceName:
      sym: virtual_interface_name
      type: string
    vlan:
      sym: vlan
      type: integer
    asn:
      sym: asn
      type: integer
    authKey:
      sym: auth_key
      type: string
    amazonAddress:
      sym: amazon_address
      type: string
    customerAddress:
      sym: customer_address
      type: string
    virtualInterfaceState:
      sym: virtual_interface_state
      type: string
    customerRouterConfig:
      sym: customer_router_config
      type: string
    virtualGatewayId:
      sym: virtual_gateway_id
      type: string
    routeFilterPrefixes:
      sym: route_filter_prefixes
      type: hash
      members:
        cidr:
          sym: cidr
          type: string
- name: ConfirmConnection
  method: confirm_connection
  inputs:
    connectionId:
    - string
    - required
  outputs:
    connectionState:
      sym: connection_state
      type: string
- name: ConfirmPrivateVirtualInterface
  method: confirm_private_virtual_interface
  inputs:
    virtualInterfaceId:
    - string
    - required
    virtualGatewayId:
    - string
    - required
  outputs:
    virtualInterfaceState:
      sym: virtual_interface_state
      type: string
- name: ConfirmPublicVirtualInterface
  method: confirm_public_virtual_interface
  inputs:
    virtualInterfaceId:
    - string
    - required
  outputs:
    virtualInterfaceState:
      sym: virtual_interface_state
      type: string
- name: CreateConnection
  method: create_connection
  inputs:
    location:
    - string
    - required
    bandwidth:
    - string
    - required
    connectionName:
    - string
    - required
  outputs:
    ownerAccount:
      sym: owner_account
      type: string
    connectionId:
      sym: connection_id
      type: string
    connectionName:
      sym: connection_name
      type: string
    connectionState:
      sym: connection_state
      type: string
    region:
      sym: region
      type: string
    location:
      sym: location
      type: string
    bandwidth:
      sym: bandwidth
      type: string
    vlan:
      sym: vlan
      type: integer
    partnerName:
      sym: partner_name
      type: string
- name: CreateInterconnect
  method: create_interconnect
  inputs:
    interconnectName:
    - string
    - required
    bandwidth:
    - string
    - required
    location:
    - string
    - required
  outputs:
    interconnectId:
      sym: interconnect_id
      type: string
    interconnectName:
      sym: interconnect_name
      type: string
    interconnectState:
      sym: interconnect_state
      type: string
    region:
      sym: region
      type: string
    location:
      sym: location
      type: string
    bandwidth:
      sym: bandwidth
      type: string
- name: CreatePrivateVirtualInterface
  method: create_private_virtual_interface
  inputs:
    connectionId:
    - string
    - required
    newPrivateVirtualInterface:
    - structure:
        virtualInterfaceName:
        - string
        - required
        vlan:
        - integer
        - required
        asn:
        - integer
        - required
        authKey:
        - string
        amazonAddress:
        - string
        customerAddress:
        - string
        virtualGatewayId:
        - string
        - required
    - required
  outputs:
    ownerAccount:
      sym: owner_account
      type: string
    virtualInterfaceId:
      sym: virtual_interface_id
      type: string
    location:
      sym: location
      type: string
    connectionId:
      sym: connection_id
      type: string
    virtualInterfaceType:
      sym: virtual_interface_type
      type: string
    virtualInterfaceName:
      sym: virtual_interface_name
      type: string
    vlan:
      sym: vlan
      type: integer
    asn:
      sym: asn
      type: integer
    authKey:
      sym: auth_key
      type: string
    amazonAddress:
      sym: amazon_address
      type: string
    customerAddress:
      sym: customer_address
      type: string
    virtualInterfaceState:
      sym: virtual_interface_state
      type: string
    customerRouterConfig:
      sym: customer_router_config
      type: string
    virtualGatewayId:
      sym: virtual_gateway_id
      type: string
    routeFilterPrefixes:
      sym: route_filter_prefixes
      type: hash
      members:
        cidr:
          sym: cidr
          type: string
- name: CreatePublicVirtualInterface
  method: create_public_virtual_interface
  inputs:
    connectionId:
    - string
    - required
    newPublicVirtualInterface:
    - structure:
        virtualInterfaceName:
        - string
        - required
        vlan:
        - integer
        - required
        asn:
        - integer
        - required
        authKey:
        - string
        amazonAddress:
        - string
        - required
        customerAddress:
        - string
        - required
        routeFilterPrefixes:
        - list:
          - structure:
              cidr:
              - string
        - required
    - required
  outputs:
    ownerAccount:
      sym: owner_account
      type: string
    virtualInterfaceId:
      sym: virtual_interface_id
      type: string
    location:
      sym: location
      type: string
    connectionId:
      sym: connection_id
      type: string
    virtualInterfaceType:
      sym: virtual_interface_type
      type: string
    virtualInterfaceName:
      sym: virtual_interface_name
      type: string
    vlan:
      sym: vlan
      type: integer
    asn:
      sym: asn
      type: integer
    authKey:
      sym: auth_key
      type: string
    amazonAddress:
      sym: amazon_address
      type: string
    customerAddress:
      sym: customer_address
      type: string
    virtualInterfaceState:
      sym: virtual_interface_state
      type: string
    customerRouterConfig:
      sym: customer_router_config
      type: string
    virtualGatewayId:
      sym: virtual_gateway_id
      type: string
    routeFilterPrefixes:
      sym: route_filter_prefixes
      type: hash
      members:
        cidr:
          sym: cidr
          type: string
- name: DeleteConnection
  method: delete_connection
  inputs:
    connectionId:
    - string
    - required
  outputs:
    ownerAccount:
      sym: owner_account
      type: string
    connectionId:
      sym: connection_id
      type: string
    connectionName:
      sym: connection_name
      type: string
    connectionState:
      sym: connection_state
      type: string
    region:
      sym: region
      type: string
    location:
      sym: location
      type: string
    bandwidth:
      sym: bandwidth
      type: string
    vlan:
      sym: vlan
      type: integer
    partnerName:
      sym: partner_name
      type: string
- name: DeleteInterconnect
  method: delete_interconnect
  inputs:
    interconnectId:
    - string
    - required
  outputs:
    interconnectState:
      sym: interconnect_state
      type: string
- name: DeleteVirtualInterface
  method: delete_virtual_interface
  inputs:
    virtualInterfaceId:
    - string
    - required
  outputs:
    virtualInterfaceState:
      sym: virtual_interface_state
      type: string
- name: DescribeConnections
  method: describe_connections
  inputs:
    connectionId:
    - string
  outputs:
    connections:
      sym: connections
      type: hash
      members:
        ownerAccount:
          sym: owner_account
          type: string
        connectionId:
          sym: connection_id
          type: string
        connectionName:
          sym: connection_name
          type: string
        connectionState:
          sym: connection_state
          type: string
        region:
          sym: region
          type: string
        location:
          sym: location
          type: string
        bandwidth:
          sym: bandwidth
          type: string
        vlan:
          sym: vlan
          type: integer
        partnerName:
          sym: partner_name
          type: string
- name: DescribeConnectionsOnInterconnect
  method: describe_connections_on_interconnect
  inputs:
    interconnectId:
    - string
    - required
  outputs:
    connections:
      sym: connections
      type: hash
      members:
        ownerAccount:
          sym: owner_account
          type: string
        connectionId:
          sym: connection_id
          type: string
        connectionName:
          sym: connection_name
          type: string
        connectionState:
          sym: connection_state
          type: string
        region:
          sym: region
          type: string
        location:
          sym: location
          type: string
        bandwidth:
          sym: bandwidth
          type: string
        vlan:
          sym: vlan
          type: integer
        partnerName:
          sym: partner_name
          type: string
- name: DescribeInterconnects
  method: describe_interconnects
  inputs:
    interconnectId:
    - string
  outputs:
    interconnects:
      sym: interconnects
      type: hash
      members:
        interconnectId:
          sym: interconnect_id
          type: string
        interconnectName:
          sym: interconnect_name
          type: string
        interconnectState:
          sym: interconnect_state
          type: string
        region:
          sym: region
          type: string
        location:
          sym: location
          type: string
        bandwidth:
          sym: bandwidth
          type: string
- name: DescribeLocations
  method: describe_locations
  inputs: {}
  outputs:
    locations:
      sym: locations
      type: hash
      members:
        locationCode:
          sym: location_code
          type: string
        locationName:
          sym: location_name
          type: string
- name: DescribeVirtualGateways
  method: describe_virtual_gateways
  inputs: {}
  outputs:
    virtualGateways:
      sym: virtual_gateways
      type: hash
      members:
        virtualGatewayId:
          sym: virtual_gateway_id
          type: string
        virtualGatewayState:
          sym: virtual_gateway_state
          type: string
- name: DescribeVirtualInterfaces
  method: describe_virtual_interfaces
  inputs:
    connectionId:
    - string
    virtualInterfaceId:
    - string
  outputs:
    virtualInterfaces:
      sym: virtual_interfaces
      type: hash
      members:
        ownerAccount:
          sym: owner_account
          type: string
        virtualInterfaceId:
          sym: virtual_interface_id
          type: string
        location:
          sym: location
          type: string
        connectionId:
          sym: connection_id
          type: string
        virtualInterfaceType:
          sym: virtual_interface_type
          type: string
        virtualInterfaceName:
          sym: virtual_interface_name
          type: string
        vlan:
          sym: vlan
          type: integer
        asn:
          sym: asn
          type: integer
        authKey:
          sym: auth_key
          type: string
        amazonAddress:
          sym: amazon_address
          type: string
        customerAddress:
          sym: customer_address
          type: string
        virtualInterfaceState:
          sym: virtual_interface_state
          type: string
        customerRouterConfig:
          sym: customer_router_config
          type: string
        virtualGatewayId:
          sym: virtual_gateway_id
          type: string
        routeFilterPrefixes:
          sym: route_filter_prefixes
          type: hash
          members:
            cidr:
              sym: cidr
              type: string
