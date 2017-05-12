package MyAttributes;

use Moose::Role;
use MooseX::MethodAttributes::Role;

sub attr : Attr {
    my ( $self, $ctx, $name ) = @_;
    $ctx->n->attribute($name);
}

sub te : Attr {
    my ( $self, $ctx, $name ) = @_;
    $ctx->n->tag eq $name ? 1 : undef;
}

package ToyXMLForester;

use Moose;
use MooseX::MethodAttributes;
use namespace::autoclean;
use TPath::Index;

with qw(TPath::Forester MyAttributes);

sub children             { my ( $self, $n )   = @_; $n->children }
sub tag                  { my ( $self, $n )   = @_; $n->tag }
sub tag_attr : Attr(tag) { my ( undef, $ctx ) = @_; $ctx->n->tag }
sub id                   { my ( $self, $n )   = @_; $n->attribute('id') }

sub autoload_attribute {
    my ( $self, $name ) = @_;
    return sub {
        my ( $self, $ctx ) = @_;
        return $ctx->n->attribute($name);
    };
}

sub BUILD { $_[0]->_node_type('Element') }

__PACKAGE__->meta->make_immutable;

1;
