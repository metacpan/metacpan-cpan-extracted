package SignalWire::REST::Namespaces::Project;
use strict;
use warnings;
use Moo;

# --- ProjectTokens ---
package SignalWire::REST::Namespaces::Project::Tokens;
use Moo;
extends 'SignalWire::REST::Namespaces::Base';

sub create {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_base_path, body => \%kwargs);
}

sub update {
    my ($self, $token_id, %kwargs) = @_;
    return $self->_http->patch($self->_path($token_id), body => \%kwargs);
}

sub delete_token {
    my ($self, $token_id) = @_;
    return $self->_http->delete_request($self->_path($token_id));
}

# Python parity alias.
sub delete {
    my ($self, $token_id) = @_;
    return $self->_http->delete_request($self->_path($token_id));
}

# --- ProjectNamespace ---
package SignalWire::REST::Namespaces::Project;
use Moo;

has '_http'  => ( is => 'ro', required => 1 );
has 'tokens' => ( is => 'lazy' );

sub _build_tokens {
    my ($self) = @_;
    return SignalWire::REST::Namespaces::Project::Tokens->new(
        _http      => $self->_http,
        _base_path => '/api/project/tokens',
    );
}

1;
