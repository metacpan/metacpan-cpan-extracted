package SignalWire::REST::Namespaces::Datasphere;
use strict;
use warnings;
use Moo;

# --- DatasphereDocuments ---
package SignalWire::REST::Namespaces::Datasphere::Documents;
use Moo;
extends 'SignalWire::REST::Namespaces::CrudResource';

sub search {
    my ($self, %kwargs) = @_;
    return $self->_http->post($self->_path('search'), body => \%kwargs);
}

sub list_chunks {
    my ($self, $document_id, %params) = @_;
    my $p = %params ? \%params : undef;
    return $self->_http->get($self->_path($document_id, 'chunks'), params => $p);
}

sub get_chunk {
    my ($self, $document_id, $chunk_id) = @_;
    return $self->_http->get($self->_path($document_id, 'chunks', $chunk_id));
}

sub delete_chunk {
    my ($self, $document_id, $chunk_id) = @_;
    return $self->_http->delete_request($self->_path($document_id, 'chunks', $chunk_id));
}

# --- DatasphereNamespace ---
package SignalWire::REST::Namespaces::Datasphere;
use Moo;

has '_http'     => ( is => 'ro', required => 1 );
has 'documents' => ( is => 'lazy' );

sub _build_documents {
    my ($self) = @_;
    return SignalWire::REST::Namespaces::Datasphere::Documents->new(
        _http      => $self->_http,
        _base_path => '/api/datasphere/documents',
    );
}

1;
