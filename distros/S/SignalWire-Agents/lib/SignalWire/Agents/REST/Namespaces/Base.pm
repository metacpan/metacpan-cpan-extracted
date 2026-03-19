package SignalWire::Agents::REST::Namespaces::Base;
use strict;
use warnings;
use Moo;

# Base for all namespace/resource classes.
has '_http'      => ( is => 'ro', required => 1 );
has '_base_path' => ( is => 'ro', required => 1 );

sub _path {
    my ($self, @parts) = @_;
    return join('/', $self->_base_path, @parts);
}

# --- CrudResource ---
package SignalWire::Agents::REST::Namespaces::CrudResource;
use Moo;
extends 'SignalWire::Agents::REST::Namespaces::Base';

# Subclasses can override: 'PATCH' (default) or 'PUT'
has '_update_method' => ( is => 'ro', default => sub { 'PATCH' } );

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
    my ($self, $resource_id) = @_;
    return $self->_http->get($self->_path($resource_id));
}

sub update {
    my ($self, $resource_id, %kwargs) = @_;
    my $method = lc($self->_update_method);
    return $self->_http->$method($self->_path($resource_id), body => \%kwargs);
}

sub delete_resource {
    my ($self, $resource_id) = @_;
    return $self->_http->delete_request($self->_path($resource_id));
}

1;
