package SignalWire::Agents::REST::Namespaces::Registry;
use strict;
use warnings;
use Moo;

# --- RegistryBrands ---
package SignalWire::Agents::REST::Namespaces::Registry::Brands;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub list {
    my ($self, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_base_path, params => $p);
}

sub create {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_base_path, body => \%kwargs);
}

sub get {
    my ($self, $brand_id) = @_;
    return $self->_http->get($self->_path($brand_id));
}

sub list_campaigns {
    my ($self, $brand_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($brand_id, 'campaigns'), params => $p);
}

sub create_campaign {
    my ($self, $brand_id, %kwargs) = @_;
    return $self->_http->post($self->_path($brand_id, 'campaigns'), body => \%kwargs);
}

# --- RegistryCampaigns ---
package SignalWire::Agents::REST::Namespaces::Registry::Campaigns;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub get {
    my ($self, $campaign_id) = @_;
    return $self->_http->get($self->_path($campaign_id));
}

sub update {
    my ($self, $campaign_id, %kwargs) = @_;
    return $self->_http->put($self->_path($campaign_id), body => \%kwargs);
}

sub list_numbers {
    my ($self, $campaign_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($campaign_id, 'numbers'), params => $p);
}

sub list_orders {
    my ($self, $campaign_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($campaign_id, 'orders'), params => $p);
}

sub create_order {
    my ($self, $campaign_id, %kwargs) = @_;
    return $self->_http->post($self->_path($campaign_id, 'orders'), body => \%kwargs);
}

# --- RegistryOrders ---
package SignalWire::Agents::REST::Namespaces::Registry::Orders;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub get {
    my ($self, $order_id) = @_;
    return $self->_http->get($self->_path($order_id));
}

# --- RegistryNumbers ---
package SignalWire::Agents::REST::Namespaces::Registry::Numbers;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

sub delete_number {
    my ($self, $number_id) = @_;
    return $self->_http->delete_request($self->_path($number_id));
}

# --- RegistryNamespace ---
package SignalWire::Agents::REST::Namespaces::Registry;
use Moo;

has '_http'     => ( is => 'ro', required => 1 );
has 'brands'    => ( is => 'lazy' );
has 'campaigns' => ( is => 'lazy' );
has 'orders'    => ( is => 'lazy' );
has 'numbers'   => ( is => 'lazy' );

my $base = '/api/relay/rest/registry/beta';

sub _build_brands    { SignalWire::Agents::REST::Namespaces::Registry::Brands->new(_http => $_[0]->_http, _base_path => "$base/brands") }
sub _build_campaigns { SignalWire::Agents::REST::Namespaces::Registry::Campaigns->new(_http => $_[0]->_http, _base_path => "$base/campaigns") }
sub _build_orders    { SignalWire::Agents::REST::Namespaces::Registry::Orders->new(_http => $_[0]->_http, _base_path => "$base/orders") }
sub _build_numbers   { SignalWire::Agents::REST::Namespaces::Registry::Numbers->new(_http => $_[0]->_http, _base_path => "$base/numbers") }

1;
