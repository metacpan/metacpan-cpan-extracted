package RDF::Server::Model::RDFCore;

use Moose;
with 'RDF::Server::Role::Model';
with 'RDF::Server::Role::Resource';
with 'RDF::Server::Role::Mutable';

use MooseX::Types::Moose qw( ArrayRef );

use RDF::Core::Model;
use RDF::Server::Resource::RDFCore;
use Iterator::Simple qw( iterator );

has store => (
    is => 'rw',
    isa => 'RDF::Core::Model',
    lazy => 1,
    default => sub {
        Class::MOP::load_class('RDF::Core::Storage::Memory');
        new RDF::Core::Model( Storage => new RDF::Core::Storage::Memory )
    }
);

no Moose;

sub get_value { undef }

sub resource {
    my($self, $id) = @_;

    if( !is_ArrayRef($id) ) {
        $id = [ $self -> namespace, $id ];
    }

    return RDF::Server::Resource::RDFCore -> new(
        model => $self,
        namespace => $id -> [0],
        localname => $id -> [1],
        id => $id -> [1]
    );
}

sub resources {
    my($self, $namespace) = @_;

    $namespace = $self -> namespace unless defined $namespace;

    # return a list of Resource objects for subjects in the namespace
    # or an iterator if we can

    my $iter = $self -> store -> getStmts();
    my $next = $iter -> getFirst();
    my %seen_subjects;
    iterator {
        while( 
            defined( $next )
            && ( $seen_subjects{ $next -> getSubject -> getURI }++
                 || index($next -> getSubject -> getURI, $namespace) != 0 
               ) 
        ) {
            $next = $iter -> getNext();
        }
        return unless defined $next;
        RDF::Server::Resource::RDFCore -> new(
            model => $self,
            namespace => $namespace,
            id => substr( $next -> getSubject -> getURI, length($namespace) )
        );
    };
}

sub resource_exists {
   my($self, $namespace, $id) = @_;

   $self -> has_triple( [ $namespace, $id ] );
}

sub has_triple {
    my($self, $s, $p, $o) = @_;

    $self -> store -> existsStmt(
        $self -> _make_resource( $s ),
        $self -> _make_resource( $p ),
        is_ArrayRef( $o ) ? $self -> _make_resource( $o ) 
                          : $self -> _make_literal( $o )
    );
}

sub get_triples {
    my($self, $s, $p, $o) = @_;

    my $iter = $self -> store -> getStmts(
        $self -> _make_resource( $s ),
        $self -> _make_resource( $p ),
        is_ArrayRef( $o ) ? $self -> _make_resource( $o ) 
                          : $self -> _make_literal( $o )
    );

    my $e = $iter -> getFirst;
    my $t;
    iterator {
        return unless $e;
        $t = [ 
            [ $e -> getSubject -> getNamespace, $e -> getSubject -> getLocalValue ],
            [ $e -> getPredicate -> getNamespace, $e -> getPredicate -> getLocalValue ],
            ( $e -> getObject -> isa('RDF::Core::Literal') ? $e -> getObject -> getValue : [ $e -> getObject -> getNamespace, $e -> getObject -> getLocalValue ] )
        ];
        $e = $iter -> getNext;
        $t;
    };
}

sub add_triple {
    my($self, $s, $p, $o) = @_;

    return unless defined($s) && defined($p) && defined($o);

    $self -> store -> addStmt( RDF::Core::Statement -> new(
        $self -> _make_resource($s),
        $self -> _make_resource($p),
        is_ArrayRef($o) ? $self -> _make_resource( $o )
                        : $self -> _make_literal( $o )
    ) );
}

sub _make_resource {
    my($self, $r) = @_;

    return undef unless defined $r;

    return $r if blessed($r) && (
        $r -> isa('RDF::Core::Literal') 
        || $r -> isa('RDF::Core::Resource')
    );

    if(is_ArrayRef( $r )) {
        RDF::Core::Resource -> new( @$r );
    }
    else {
        RDF::Core::Resource -> new( $r );
    }
}

sub _make_literal {
    my($self, $l) = @_;

    return undef unless defined $l;

    return $l if blessed($l) && (
        $l -> isa('RDF::Core::Literal') 
        || $l -> isa('RDF::Core::Resource')
    );

    RDF::Core::Literal -> new( $l );
}

sub update {   # POST
    my($self, $xml) = @_;

    my @stmts;

    my $parser = RDF::Core::Parser -> new(
        Assert => sub {
            push @stmts, RDF::Server::Resource::RDFCore -> _triple(@_);
        },
        BaseURI => $self -> namespace
    );

    $parser -> parse($xml);
    $self -> store -> addStmt( $_ ) foreach @stmts;
    return 1;
}

sub fetch {   # GET
    my($self) = @_;

    my $xml = '';
    my $serializer = new RDF::Core::Model::Serializer( 
        Model => $self -> store,
        Output => \$xml,
        BaseURI => $self -> namespace
    );
    $serializer -> serialize;
    return $xml;
}

sub purge { 
    my($self, $xml) = @_;

        my @stmts;

    my $parser = RDF::Core::Parser -> new(
        Assert => sub {
            push @stmts, RDF::Server::Resource::RDFCore -> _triple(@_);
        },
        BaseURI => $self -> namespace
    );

    $parser -> parse( $xml );

    foreach my $stmt (@stmts) {
        $self -> store -> removeStmt( $stmt );
    }
    return 1;
}

sub delete {  # remove resource completely
    my($self) = @_;

    $self -> purge($self -> fetch);
}

sub render {
    my($self, $formatter) = @_;

    if( $formatter -> wants_rdf ) {
        return $formatter -> resource( $self -> fetch );
    }
    else {
        return $formatter -> resource( $self -> data );
    }
}

sub modify {  # modify parts of a resource
    my($self, $formatter, $xml) = @_;

    $xml = $formatter -> to_rdf( $xml ) if $formatter;
    $self -> update( $xml );
    return $self -> render($formatter);
}

sub replace { # logically purge and create with supplied content
    my($self, $formatter, $xml) = @_;

    $xml = $formatter -> to_rdf( $xml ) if $formatter;
    my $old_xml = $self -> fetch;
    eval {
        $self -> purge($old_xml);
        $self -> update($xml);
    };
    if($@) {
        $self -> purge($self -> fetch);
        $self -> update($old_xml);
    }
}

sub remove {  # purge all content directly part of resource
    my($self, $formatter, $xml) = @_;

    $xml = $formatter -> to_rdf( $xml ) if $formatter;
    my $old_xml = $self -> fetch;
    eval {
        $self -> purge($xml);
    };
    if($@) {
        $self -> purge($self -> fetch);
        $self -> update($old_xml);
    }
}

1;

__END__

=pod

=head1 NAME

RDF::Server::Model::RDFCore

=head1 SYNOPSIS

=head1 DESCRIPTION

Manages a triple store based on RDF::Core.  Support is included for using
the model as a resource itself for the RDF semantic.

=head1 CONFIGURATION

=over 4

=item namespace

The default namespace in which resources are located.  While the store
can support resources in other namespaces, the RDF::Server modules expect
resources to be in this namespace.

=item store

The store is a RDF::Core::Model object that manages the triples.

=back

=head1 METHODS

=over 4

=item has_triple ($s, $p, $o)

Given a subject, predicate, and object, returns true if the store contains
the triple.  Any of the parameters may be undefined to serve as wildcards.

Each parameter may be a single value or an array ref.  

If the subject or predicate are an array ref, then the referenced 
array consists of two elements: the namespace and the local name.  
Otherwise, the string is the URI (namespace and local name combined) 
of the parameter.  

If the object is a string, then it is considered a literal.  Otherwise, 
it is interpreted in the same manner as the other parameters.

=item get_triples ($s, $p, $o)

=item add_triple ($s, $p, $o)

=item get_value

This method is only valid in resources that are part of a model.

=item resource ( $id | [ $namespace, $id ] )

Returns a RDF::Server::Resource::RDFCore object representing all the triples
in the store that are associated with the given either an array 
reference containing the namespace and the local name, or a string 
containing the local name.  The default namespace is the one defined 
for the model.

This will return an object regardless of the existance of the resource.  It
is not an error to have an empty RDF document associated with a URL.

=item resources ( $namespace )

Returns an iterator (see L<Iterator::Simple>) that will iterate over the
resources in the store in the provided namespace (or the model's namespace if
none is given).  Each iteration will return a
RDF::Server::Resource::RDFCore object.

=item resource_exists ( $namespace, $id )

Returns true if there is at least one triple in the store associated with the
provided namespace and local name.

=item fetch

Returns the RDF document representing all of the triples within the model.

=item data

Returns a refernce to an array of hashes, one for each resource in the model.

=item update

=item purge

=item render

=item delete

=item modify

=item replace

=item remove

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut
