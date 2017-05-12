package RDF::Server::Role::Resource;

use Moose::Role;

use MooseX::Types::Moose qw( HashRef ArrayRef );
use RDF::Server::Types qw( Model );
use RDF::Server::Constants qw( RDF_NS );
use XML::Simple;

has model => (
    is => 'rw',
    isa => Model
);

has id => (
    is => 'ro',
    isa => 'Str'
);

requires 'update';   # POST

requires 'fetch';   # GET

requires 'purge';   # DELETE with content

sub add_triple {
    my($self, $s, $p, $o) = @_;

    $s ||= [ $self -> model -> namespace, $self -> id ];

    $self -> model -> add_triple($s, $p, $o);
}

sub has_triple {
    my($self, $s, $p, $o) = @_;

    $s ||= [ $self -> model -> namespace, $self -> id ];

    $self -> model -> has_triple($s, $p, $o);
}

sub get_value {
    my($self, $ns, $p) = @_;

    my $iter = $self -> model -> get_triples(
        [ $self -> model -> namespace, $self -> id],
        [ $ns, $p ],
        undef
    );

    my $v = $iter -> next;

    return $v -> [2] if $v;
    return;
}

sub uri { $_[0] -> model -> namespace . $_[0] -> id }

sub data {
    my($self) = @_;

    # we want to return a hashref tree of ourselves
    # useful for JSON and other data structure style formats

    my $data = XML::Simple::XMLin($self -> fetch, NSExpand => 1)
                   -> {"{@{[RDF_NS]}}Description"};

    $self -> _collapse_containers( $data ) || { };
}

sub _collapse_containers {
    my($self, $d) = @_;

    my $method;

    if( is_ArrayRef( $d ) ) {
        return [ map { $self -> _collapse_containers($_) } @$d ];
    }

    return $d unless is_HashRef( $d );

    foreach my $k (keys %$d) {
        if( $k eq "{@{[RDF_NS]}}Description" ) {
            my $type = $d -> {$k} 
                          -> {"{@{[RDF_NS]}}type"} 
                          -> {"{@{[RDF_NS]}}resource"};

            $d -> {"{@{[RDF_NS]}}$1"} = $self -> $method(delete $d -> {$k})
                if $type =~ m{^@{[RDF_NS]}(.*)$} 
                   && ($method = $self -> can("_collapse_$1"));
        }
        else {
            $d -> {$k} = $self -> _collapse_containers($d -> {$k});
        }
    }
    return $d;
}

sub _collapse_Seq {
    my($self, $seq) = @_;

    my @items;

    foreach my $k (keys %$seq) {
        next unless $k =~ m{^{@{[RDF_NS]}}_(\d+)};
        push @items, [ $1, $self -> _collapse_containers($seq -> {$k}) ];
    }

    return [ map { is_ArrayRef($_) ? @$_ : $_ } map { $_ -> [1] } sort { $a->[0] <=> $b->[0] } @items ];
}

*_collapse_Alt = \&_collapse_Seq;
*_collapse_Bag = \&_collapse_Seq;

1;

__END__

=pod

=head1 NAME

RDF::Server::Role::Resource - expectations of a resource object

=head1 SYNOPSIS

 package My::Resource

 use Moose;
 with 'RDF::Server::Role::Resource';

 sub update { ... }
 sub fetch { ... }
 sub purge { ... }

=head1 DESCRIPTION

=head1 CONFIGURATION

=over 4

=item id : Str

=item model : Model

=back

=head1 REQUIRED METHODS

=over 4

=item update ($rdfxml)

Given an RDF document, this should add to the triple store all statements that
can be built from the document.  Special care should be taken with RDF
containers.

=item fetch : Str

This should return an RDF document describing all of the triples associated with
this resource.  References to other resources should be referenced only and not
followed.

=item purge : Bool

Given an RDF document, this should remove from the triple store all statements
that can be built from the document.

TODO: Security to make sure we don't stray into another resource.

=back

=head1 PROVIDED METHODS

=over 4

=item uri : Str

The URI of a resource defaults to the namespace of the model concatenated with
the C<id> of the resource.

=item add_triple ($s, $p, $o)

This will add the triple to the resource's model.  If the subject is
undefined, the resource's URI is substituted.

=item has_triple ($s, $p, $o)

This will query the resource's model on the existance of the given
triple.  If the subject is undefined, the resource's URI is substituted.

=item get_value ($namespace, $localname)

Given the namespace and localname of a predicate, this returns the value
associated with the predicate and the given resource.

=item data : HashRef

The Perl data structure representing the content of the resource is based on
the RDF returned by the C<fetch> method with some optimizations for RDF
containers.  Namespaces are expanded.

For example, if the following is the RDF for the resource:

 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xmlns:x="http://www.example.com/ns/">
  <rdf:Description>
    <x:foo>bar</x:foo>
    <x:stuff>
      <rdf:Description>
        <rdf:type rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag" />
        <rdf:_1>Red</rdf:_1>
        <rdf:_3>Blue</rdf:_3>
        <rdf:_1>Green</rdf:_1>
      </rdf:Description>
    </x:stuff>
  </rdf:Description>
 </rdf:RDF>

then the Perl data structure would be:

 {
   '{http://www.example.com/ns/}foo' => 'bar',
   '{http://www.example.com/ns/}stuff' => {
     '{http://www.w3.org/1999/02/22-rdf-syntax-ns#}Bag' => [
       'Red', 'Green', 'Blue'
     ]
   }
 }

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

