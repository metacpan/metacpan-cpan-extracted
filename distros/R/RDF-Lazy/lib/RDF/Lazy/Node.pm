use strict;
use warnings;
package RDF::Lazy::Node;
{
  $RDF::Lazy::Node::VERSION = '0.081';
}
#ABSTRACT: A node in a lazy RDF graph


use RDF::Lazy::Literal;
use RDF::Lazy::Resource;
use RDF::Lazy::Blank;
use RDF::Trine qw(iri);
use CGI qw(escapeHTML);
use Carp qw(carp);

our $AUTOLOAD;
our $rdf_type = iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');

sub trine { shift->[0]; }
sub graph { shift->[1]; }
sub esc { escapeHTML( shift->str ) }

sub is_literal  { shift->[0]->is_literal; }
sub is_resource { shift->[0]->is_resource; }
*is_uri = *is_resource;

sub is_blank    { shift->[0]->is_blank; }

sub AUTOLOAD {
    my $self = shift;
    return if !ref($self) or $AUTOLOAD =~ /^(.+::)?DESTROY$/;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    return $self->_autoload( $method, @_ );
}

sub type {
    my $self = shift;
    if ( @_ ) {
        my $types = $self->rels( $rdf_type ); # TODO use filter?
        foreach ( @_ ) {
            my $type = $self->graph->uri( $_ ) or next;
            return 1 if (grep { $_->str eq $type->str } @$types);
        }
        return 0;
    } else {
        $self->rel( $rdf_type );
    }
}

*a = *type;

sub types {
    my $self = shift;
    $self->rels( $rdf_type );
}

sub is {
    my $self = shift;
    return 1 unless @_;

    foreach my $check (@_) {
        if ($self->is_literal) {
            return 1 if $check eq '' or $check eq 'literal';
            return 1 if $check eq '@' and $self->lang;
            return 1 if $check =~ /^@(.+)/ and $self->lang($1);
            return 1 if $check =~ /^\^\^?$/ and $self->datatype;
            return 1 if $check =~ /^\^\^?(.+)$/ and $self->datatype($1);
        } elsif ($self->is_resource) {
            return 1 if $check eq ':' or $check eq 'resource';
        } elsif ($self->is_blank) {
            return 1 if $check eq '-' or $check eq 'blank';
        }
    }

    return 0;
}

sub ttl    { $_[0]->graph->ttl( @_ ); }
sub ttlpre { $_[0]->graph->ttlpre( @_ ); }

sub rel  { $_[0]->graph->rel( @_ ); }
sub rels { $_[0]->graph->rels( @_ ); }
sub rev  { $_[0]->graph->rev( @_ ); }
sub revs { $_[0]->graph->revs( @_ ); }

sub qname { "" };

sub _autoload {
    my $self     = shift;
    my $property = shift;
    return if $property =~ /^(query|lang)$/; # reserved words
    return $self->rel( $property, @_ );
}

1;



=pod

=head1 NAME

RDF::Lazy::Node - A node in a lazy RDF graph

=head1 VERSION

version 0.081

=head1 DESCRIPTION

You should not directly create instances of this class, but use L<RDF::Lazy> as
node factory to create instances of L<RDF::Lazy::Resource>,
L<RDF::Lazy::Literal>, and L<RDF::Lazy::Blank>.

    $graph->resource( $uri );    # returns a RDF::Lazy::Resource
    $graph->literal( $string );  # returns a RDF::Lazy::Literal
    $graph->blank( $id );        # returns a RDF::Lazy::Blank

A lazy node contains a L<RDF::Trine::Node> and a pointer to the
RDF::Lazy graph where the node is located in. You can create a
RDF::Lazy::Node from a RDF::Trine::Node just like this:

    $graph->uri( $trine_node )

=head1 DESCRIPTION

This class wraps L<RDF::Trine::Node> and holds a pointer to the graph
(L<RDF::Lazy>) which a node belongs to. In detail there are node types
L<RDF::Lazy::Literal>, L<RDF::Lazy::Resource>, and L<RDF::Lazy::Blank>.

=head1 METHODS

=head2 str

Returns a string representation of the node's value. Is automatically
called on string conversion (C<< "$x" >> equals C<< $x->str >>).

=head2 esc

Returns a HTML-escaped string representation. This can safely be used
in HTML and XML.

=head2 is_literal / is_resource / is_blank

Returns true if the node is a literal, resource, or blank node.

=head2 graph

Returns the underlying graph L<RDF::Lazy> that the node belongs to.

=head2 type ( [ @types ] )

Returns some rdf:type of the node (if no types are provided) or checks
whether this node is of any of the provided types.

=head2 a ( [ @types ] )

Shortcut for C<type>.

=head2 is ( $check1 [, $check2 ... ] )

Checks whether the node fullfills some matching criteria, for instance

    $x->is('')     # is_literal
    $x->is(':')    # is_resource
    $x->is('-')    # is_blank
    $x->is('@')    # is_literal and has language tag
    $x->is('@en')  # is_literal and has language tag 'en' (is_en)
    $x->is('@en-') # is_literal and is_en_
    $x->is('^')    # is_literal and has datatype
    $x->is('^^')   # is_literal and has datatype

=head2 ttl

Returns an RDF/Turtle representation of the node's bounded connections.

=head2 rel ( $property [, @filters ] )

Traverse the graph and return the first matching object.

=head2 rels

Traverse the graph and return all matching objects.

=head2 rev ( $property [, @filters ] )

Traverse the graph and return the first matching subject.

=head2 revs

Traverse the graph and return all matching subjects.

=head2 trine

Returns the underlying L<RDF::Trine::Node>. DO NOT USE THIS METHOD!

=head2 qname

Returns a qualified string, if possible, or the empty string.

=head1 TRAVERSING THE GRAPH

Any other method name is used to query objects. The following three statements
are equivalent:

    $x->rel('foaf:name');
    $x->graph->rel( $x, 'foaf_name' );
    $x->rel('foaf_name');
    $x->foaf_name;

You can also add filters in a XPath-like language (the use of RDF::Lazy
in a template is an example of a "RDFPath" language):

    $x->dc_title('@en')   # literal with language tag @en
    $x->dc_title('@en-')  # literal with language tag @en or @en-...
    $x->dc_title('')      # any literal
    $x->dc_title('@')     # literal with any language tag
    $x->dc_title('^')     # literal with any datatype
    $x->foaf_knows(':')   # any resource
    ...

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

