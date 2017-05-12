# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/Meta/LibXML.pm 68283 2008-08-12T02:34:53.003080Z daisuke  $

package MooseX::DOM::Meta::LibXML;
use Moose;

extends 'Moose::Meta::Class';

has 'dom_root' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

has 'dom_attributes' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

has 'dom_children' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub assert_root_node {
    my ($self, $object, $node) = @_;

    my $tag = $self->dom_root->{tag};
    $node ||= $object->node;
    if ($node && $node->getName ne $tag) {
        confess "given node does not have required root node $tag";
    }
}

sub create_root_node {
    my ($self, $object) = @_;
    return if $object->node;

    my $root = $self->dom_root;
    confess "No root node defined" unless $root;

    my $tag = $root->{tag};
    my $attrs = $root->{attributes};
    my $doc = XML::LibXML::Document->new( '1.0' => 'UTF-8' );
    my $node = $doc->createElement($tag);
    while (my($name, $value) = each %$attrs) {
        $node->setAttribute($name, $value);
    }

    $node = MooseX::DOM::LibXML::ContextNode->new(node => $node);
    $object->node( $node );

    return $node;
}

sub register_dom_attribute {
    my ($self, $name) = @_;
    $self->dom_attributes->{$name}++;
}

sub register_dom_child {
    my ($self, $name, $spec) = @_;
    $self->dom_children->{$name} = $spec;
}

sub get_dom_attribute {
    my ($self, $object, $name) = @_;
    my $node = $object->node;
    return () unless $node;
    $node->getAttribute($name);
}

sub set_dom_attribute {
    my ($self, $object, $name, $value) = @_;
    my $node = $object->node;
    if (! $node) {
        $node = $self->create_root_node( $object );
    }

    $node->setAttribute($name, $value);
}

sub get_dom_children {
    my ($self, $object, $name) = @_;

    my $node = $object->node;
    return () unless $node;

    my $spec = $self->dom_children->{ $name };
    return () unless $spec;

    my $tagname = $spec->{tag} || $name;
    my $nsuri = $spec->{namespace} ? $object->namespaces->{ $spec->{namespace} } : undef;

    my @children = ($nsuri) ?
        $node->getChildrenByTagNameNS($nsuri, $tagname):
        $node->getChildrenByTagName($tagname)
    ;

    return $spec->{filter}->( $object, @children );
}

sub set_dom_children {
    my ($self, $object, $name, @args) = @_;

    my $node = $object->node;
    if (! $node) {
        $node = $self->create_root_node( $object );
    }

    my $spec = $self->dom_children->{ $name };
    return () unless $spec;

    my $tagname = $spec->{tag};
    my $nsuri = $spec->{namespace} ? $object->namespaces->{ $spec->{namespace} } : undef;

    my @children = ($nsuri) ?
        $node->getChildrenByTagNameNS($nsuri, $tagname):
        $node->getChildrenByTagName($tagname)
    ;
    $node->removeChild($_) for @children;

    return $spec->{create}->( $object, tag => $tagname, namespace => $spec->{namespace}, values => \@args );
}

1;