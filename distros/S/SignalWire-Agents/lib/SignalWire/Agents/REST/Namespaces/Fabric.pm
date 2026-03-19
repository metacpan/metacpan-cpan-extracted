package SignalWire::Agents::REST::Namespaces::Fabric;
use strict;
use warnings;
use Moo;

# --- Fabric Resource (PATCH updates) ---
package SignalWire::Agents::REST::Namespaces::Fabric::Resource;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::CrudResource';

sub list_addresses {
    my ($self, $resource_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($resource_id, 'addresses'), params => $p);
}

# --- Fabric Resource with PUT updates ---
package SignalWire::Agents::REST::Namespaces::Fabric::ResourcePUT;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Fabric::Resource';
has '+_update_method' => ( default => sub { 'PUT' } );

# --- CallFlows ---
package SignalWire::Agents::REST::Namespaces::Fabric::CallFlows;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Fabric::ResourcePUT';

sub list_addresses {
    my ($self, $resource_id, %params) = @_;
    (my $path = $self->_base_path) =~ s/call_flows/call_flow/;
    my $p = %params ? \%params : undef;
    return $self->_http->get("$path/$resource_id/addresses", params => $p);
}

sub list_versions {
    my ($self, $resource_id, %params) = @_;
    (my $path = $self->_base_path) =~ s/call_flows/call_flow/;
    my $p = %params ? \%params : undef;
    return $self->_http->get("$path/$resource_id/versions", params => $p);
}

sub deploy_version {
    my ($self, $resource_id, %kwargs) = @_;
    (my $path = $self->_base_path) =~ s/call_flows/call_flow/;
    return $self->_http->post("$path/$resource_id/versions", body => \%kwargs);
}

# --- ConferenceRooms ---
package SignalWire::Agents::REST::Namespaces::Fabric::ConferenceRooms;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Fabric::ResourcePUT';

sub list_addresses {
    my ($self, $resource_id, %params) = @_;
    (my $path = $self->_base_path) =~ s/conference_rooms/conference_room/;
    my $p = %params ? \%params : undef;
    return $self->_http->get("$path/$resource_id/addresses", params => $p);
}

# --- Subscribers ---
package SignalWire::Agents::REST::Namespaces::Fabric::Subscribers;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Fabric::ResourcePUT';

sub list_sip_endpoints {
    my ($self, $subscriber_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($subscriber_id, 'sip_endpoints'), params => $p);
}

sub create_sip_endpoint {
    my ($self, $subscriber_id, %kwargs) = @_;
    return $self->_http->post($self->_path($subscriber_id, 'sip_endpoints'), body => \%kwargs);
}

sub get_sip_endpoint {
    my ($self, $subscriber_id, $endpoint_id) = @_;
    return $self->_http->get($self->_path($subscriber_id, 'sip_endpoints', $endpoint_id));
}

sub update_sip_endpoint {
    my ($self, $subscriber_id, $endpoint_id, %kwargs) = @_;
    return $self->_http->patch($self->_path($subscriber_id, 'sip_endpoints', $endpoint_id), body => \%kwargs);
}

sub delete_sip_endpoint {
    my ($self, $subscriber_id, $endpoint_id) = @_;
    return $self->_http->delete_request($self->_path($subscriber_id, 'sip_endpoints', $endpoint_id));
}

# --- CxmlApplications (no create) ---
package SignalWire::Agents::REST::Namespaces::Fabric::CxmlApplications;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Fabric::ResourcePUT';

sub create {
    die "cXML applications cannot be created via this API";
}

# --- GenericResources ---
package SignalWire::Agents::REST::Namespaces::Fabric::GenericResources;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $resource_id) = @_;
    return $self->_http->get($self->_path($resource_id));
}

sub delete_resource {
    my ($self, $resource_id) = @_;
    return $self->_http->delete_request($self->_path($resource_id));
}

sub list_addresses {
    my ($self, $resource_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($resource_id, 'addresses'), params => $p);
}

sub assign_phone_route {
    my ($self, $resource_id, %kwargs) = @_;
    return $self->_http->post($self->_path($resource_id, 'phone_routes'), body => \%kwargs);
}

sub assign_domain_application {
    my ($self, $resource_id, %kwargs) = @_;
    return $self->_http->post($self->_path($resource_id, 'domain_applications'), body => \%kwargs);
}

# --- FabricAddresses (read-only) ---
package SignalWire::Agents::REST::Namespaces::Fabric::Addresses;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub get {
    my ($self, $address_id) = @_;
    return $self->_http->get($self->_path($address_id));
}

# --- FabricTokens ---
package SignalWire::Agents::REST::Namespaces::Fabric::Tokens;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub create_subscriber_token {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_path('subscribers', 'tokens'), body => \%kwargs);
}

sub refresh_subscriber_token {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_path('subscribers', 'tokens', 'refresh'), body => \%kwargs);
}

sub create_invite_token {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_path('subscriber', 'invites'), body => \%kwargs);
}

sub create_guest_token {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_path('guests', 'tokens'), body => \%kwargs);
}

sub create_embed_token {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_path('embeds', 'tokens'), body => \%kwargs);
}

# --- FabricNamespace (top-level grouping) ---
package SignalWire::Agents::REST::Namespaces::Fabric;
use Moo;

has '_http' => ( is => 'ro', required => 1 );

has 'swml_scripts'          => ( is => 'lazy' );
has 'relay_applications'    => ( is => 'lazy' );
has 'call_flows'            => ( is => 'lazy' );
has 'conference_rooms'      => ( is => 'lazy' );
has 'freeswitch_connectors' => ( is => 'lazy' );
has 'subscribers'           => ( is => 'lazy' );
has 'sip_endpoints'         => ( is => 'lazy' );
has 'cxml_scripts'          => ( is => 'lazy' );
has 'cxml_applications'     => ( is => 'lazy' );
has 'swml_webhooks'         => ( is => 'lazy' );
has 'ai_agents'             => ( is => 'lazy' );
has 'sip_gateways'          => ( is => 'lazy' );
has 'cxml_webhooks'         => ( is => 'lazy' );
has 'resources'             => ( is => 'lazy' );
has 'addresses'             => ( is => 'lazy' );
has 'tokens'                => ( is => 'lazy' );

my $base = '/api/fabric/resources';

sub _build_swml_scripts          { $_[0]->_mk('ResourcePUT', "$base/swml_scripts") }
sub _build_relay_applications    { $_[0]->_mk('ResourcePUT', "$base/relay_applications") }
sub _build_call_flows            { SignalWire::Agents::REST::Namespaces::Fabric::CallFlows->new(_http => $_[0]->_http, _base_path => "$base/call_flows") }
sub _build_conference_rooms      { SignalWire::Agents::REST::Namespaces::Fabric::ConferenceRooms->new(_http => $_[0]->_http, _base_path => "$base/conference_rooms") }
sub _build_freeswitch_connectors { $_[0]->_mk('ResourcePUT', "$base/freeswitch_connectors") }
sub _build_subscribers           { SignalWire::Agents::REST::Namespaces::Fabric::Subscribers->new(_http => $_[0]->_http, _base_path => "$base/subscribers") }
sub _build_sip_endpoints         { $_[0]->_mk('ResourcePUT', "$base/sip_endpoints") }
sub _build_cxml_scripts          { $_[0]->_mk('ResourcePUT', "$base/cxml_scripts") }
sub _build_cxml_applications     { SignalWire::Agents::REST::Namespaces::Fabric::CxmlApplications->new(_http => $_[0]->_http, _base_path => "$base/cxml_applications") }
sub _build_swml_webhooks         { $_[0]->_mk('Resource', "$base/swml_webhooks") }
sub _build_ai_agents             { $_[0]->_mk('Resource', "$base/ai_agents") }
sub _build_sip_gateways          { $_[0]->_mk('Resource', "$base/sip_gateways") }
sub _build_cxml_webhooks         { $_[0]->_mk('Resource', "$base/cxml_webhooks") }
sub _build_resources             { SignalWire::Agents::REST::Namespaces::Fabric::GenericResources->new(_http => $_[0]->_http, _base_path => $base) }
sub _build_addresses             { SignalWire::Agents::REST::Namespaces::Fabric::Addresses->new(_http => $_[0]->_http, _base_path => '/api/fabric/addresses') }
sub _build_tokens                { SignalWire::Agents::REST::Namespaces::Fabric::Tokens->new(_http => $_[0]->_http, _base_path => '/api/fabric') }

sub _mk {
    my ($self, $type, $path) = @_;
    my $class = "SignalWire::Agents::REST::Namespaces::Fabric::$type";
    return $class->new(_http => $self->_http, _base_path => $path);
}

1;
