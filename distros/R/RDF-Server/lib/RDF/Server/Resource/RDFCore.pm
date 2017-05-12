BEGIN {

    package RDF::Server::Resource::RDFCore::Types;

    use MooseX::Types -declare => [qw(
        RDFCoreModel
    )];

    use RDF::Server::Types qw( Model );

    subtype RDFCoreModel,
        as Model,
        where { $_ -> isa( 'RDF::Server::Model::RDFCore' ) },
        message { 'Object is not an RDF::Core Model' }
    ;

}

package RDF::Server::Resource::RDFCore;

use Moose;
with 'RDF::Server::Role::Resource';
with 'RDF::Server::Role::Mutable';

use RDF::Core::Model::Serializer;
use RDF::Core::Statement;
use RDF::Core::Literal;
use RDF::Core::Parser;

use DateTime;

use XML::LibXML;

use XML::Simple;

use RDF::Server::Constants qw( :ns );
use RDF::Server::Types qw( Exception );

BEGIN {
    RDF::Server::Resource::RDFCore::Types -> import(qw(RDFCoreModel));
}

has '+model' => (
    isa => RDFCoreModel
);

has bnode_prefix => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { (shift) -> id() . ':' }
);

sub exists {
    my($self) = @_;

    $self -> model -> resource_exists( $self -> model -> namespace, $self -> id );
}

sub _resource {
    my($self, $n, $u) = @_;

    return RDF::Core::Resource -> new( $n, $u );
}

sub render { # GET
    my($self, $formatter) = @_;
   
    if( $formatter -> wants_rdf ) {
        return $formatter -> resource( $self -> fetch );
    }
    else {
        return $formatter -> resource( $self -> data );
    }
}

sub fetch {
    my($self) = @_;

    my $xml;
    my $serializer = new RDF::Core::Model::Serializer(
        Model => $self -> model -> store,
        Output => \$xml,
        BaseURI => $self -> model -> namespace,
        getSubjects => sub {   
            # we want all of the things that come from subject
            $self -> _get_subjects( $self -> _resource( $self -> model -> namespace, $self -> id ) );
        }
    );
    $serializer -> serialize;

    return $xml;
}

sub purge {
    my($self, $rdf) = @_;

    my %triples;
        
    my $parser = new RDF::Core::Parser(
        BaseURI => $self -> model -> namespace,
        BNodePrefix => $self -> bnode_prefix,
        Assert => sub {
            my $stmt = $self -> _triple(@_);
            push @{$triples{$stmt -> getSubject -> getURI} ||= [ ]}, $stmt;
        }
    );
    
    $parser -> parse( $self -> _add_subject( $rdf ) );
  
    $self -> _remove_statements( \%triples, $self -> uri );
}

sub remove {    # DELETE with content
    my($self, $formatter, $rdf) = @_;

    $rdf = $formatter -> to_rdf( $rdf ) if $formatter;

    $self -> purge( $rdf );
    # $self -> _add_atom_updated; # is there a way to delay this? :-/
    return $self -> render($formatter);
}

sub delete {         # DELETE without content
    my($self) = @_;

    my $original = $self -> fetch;
    $self -> purge( $original );
    if( $self -> exists ) {
        $self -> update( $original );
        return 0;
    }
    return 1;
}

sub _get_subjects {
    my( $self, $root ) = @_;

    my %subjects;

    $subjects{$root -> getURI} = [ $root, 0, 0 ];

    #print STDERR "_gs: ", $root -> getURI, "\n";
    my $iter = $self -> model -> store -> getStmts( $root, undef, undef );
    my $s = $iter -> getFirst;
    while(defined $s) {
        if( !$s -> getObject() -> isLiteral() &&
            !exists $subjects{$s -> getObject() -> getURI} &&
            $self -> _is_local_subject($s -> getObject() -> getURI) ) {
            %subjects = ( %subjects, %{$self -> _get_subjects( $s -> getObject() )
 } );   
        }
        $s = $iter -> getNext;
    }

    return \%subjects;
}

sub _is_local_subject {
    my($self, $s) = @_;

    (index( $s, $self -> model -> namespace) == 0 ||
     index( $s, '_:' . $self -> bnode_prefix) == 0)
    ;
}

sub _add_subject {
    my( $self, $body) = @_;

    my $xml_parser = XML::LibXML -> new();
    my $doc = $xml_parser -> parse_string($body);

    my $root = $doc -> documentElement();

    my $prefix = $root -> lookupNamespacePrefix( RDF_NS );
    if( $prefix eq '' ) {
        $root -> setNamespace( RDF_NS, 'xxrdf' );
        $prefix = 'xxrdf';
    }

    # we only want one child of the root element
    my @children = $root -> findnodes("/$prefix:RDF/$prefix:Description");

    if( @children && !$children[0] -> hasAttributeNS( RDF_NS, 'about' ) ) {
        $children[0] -> setAttributeNS( RDF_NS, 'about', $self -> uri );
    }
            
    return $doc -> serialize_c14n();
}   

sub _remove_statements {
    my($self, $triples, $root) = @_;

#    use Data::Dumper;
#    print STDERR join("\n", 
#                      map { 
#                            "$_:\n   " . 
#                            ( join("\n   ", 
#                                   map { $_ -> getLabel } @{$triples->{$_}} 
#                              )
#                            ) 
#                          } keys(%$triples) 
#                     ), "\n";

    my @delayed;

    foreach my $stmt ( @{ $triples -> { $root } || [] } ) {
        if( $stmt -> getObject -> isLiteral ) {
            if( $stmt -> getPredicate -> getNamespace eq RDF_NS &&
                $stmt -> getPredicate -> getLocalValue =~ /^_\d+$/ ) {
                # we have a temporary node for lists, etc.
                # so we look for subject, _, object and delete those
                my $iter = $self -> model -> store -> getStmts( $stmt -> getSubject, undef, $stmt -> getObject);
                my $s = $iter -> getFirst;
                if( defined $s ) {
                    #print STDERR 'Removing ', $s -> getLabel(), "\n";
                    $self -> model -> store -> removeStmt( $s );
                }
                $iter -> close;
            }
            else {
                $self -> model -> store -> removeStmt( $stmt );
            }
        }
        else { # we're dealing with something else
            if( $stmt -> getPredicate -> getNamespace eq RDF_NS &&
                $stmt -> getPredicate -> getLocalValue eq 'type' ) {
                my $cnt = $self -> model -> store -> countStmts( $stmt -> getSubject );
                #print STDERR "There are $cnt statements for ", $stmt -> getSubject -> getLabel(), "\n";
                if( $cnt < 2 ) {
                    # only thing in the set is the rdf:type declaration
                    #print STDERR 'Removing ', $stmt -> getLabel(), "\n";
                    $self -> model -> store -> removeStmt( $stmt );
                } 
                else {
                    push @delayed, $stmt;
                }
            }
            else {
                $self -> _remove_statements(
                             $triples, 
                             $stmt -> getObject -> getURI
                         ) if defined $triples->{$stmt -> getObject -> getURI};

                if( !$self -> model -> store -> existsStmt( $stmt -> getObject ) ) {
                    #print STDERR 'Removing ', $stmt -> getLabel(), "\n";
                    $self -> model -> store -> removeStmt( $stmt );
                }
                else {
                    push @delayed, $stmt;
                }
            }
        }
    }

    if( @delayed ) {
        foreach my $stmt (@delayed) {
            if( $stmt -> getPredicate -> getNamespace eq RDF_NS &&
                $stmt -> getPredicate -> getLocalValue eq 'type' ) {
                my $cnt = $self -> model -> store -> countStmts( $stmt -> getSubject );
                #print STDERR "There are $cnt statements for ", $stmt -> getSubject -> getLabel(), "\n";
                if( $cnt < 2 ) {
                    # only thing in the set is the rdf:type declaration
                    #print STDERR 'Removing ', $stmt -> getLabel(), "\n";
                    $self -> model -> store -> removeStmt( $stmt );
                }     
            }
            else {
                if( !$self -> model -> store -> existsStmt( $stmt -> getObject ) ) {
                    #print STDERR 'Removing ', $stmt -> getLabel(), "\n";
                    $self -> model -> store -> removeStmt( $stmt );
                }
            }
        }
    }

    1;
}

sub modify {
    my( $self, $formatter, $body ) = @_;
    
    $self -> update( $formatter -> to_rdf( $body ) );

    return $self -> render( $formatter );
}

sub update {
    my( $self, $rdf ) = @_;

    my $exists = $self -> exists;

    if( $rdf =~ m{\S} ) {

        my %triples;

        my $parser = new RDF::Core::Parser(
            BaseURI => $self -> model -> namespace,
            BNodePrefix => $self -> bnode_prefix,
            Assert => sub {
                my $stmt = $self -> _triple(@_);
                push @{$triples{$stmt -> getSubject -> getURI} ||= [ ]}, $stmt;
            }
        );
            
        my $new_xml = $self -> _add_subject( $rdf );
        $parser -> parse( $new_xml );
            
        if( keys %triples ) {
            $self -> _add_statements( \%triples, $self -> uri );
            if( $exists ) {
                $self -> _add_atom_updated;
            }
            else {
                $self -> _add_dc_created;
            }
        }
    }

    1;
}

sub replace { # PUT
    my( $self, $formatter, $body ) = @_;

    $body = $formatter -> to_rdf( $body ) if $formatter;

    my $old_rdf = $self -> fetch;

    #print STDERR "Old rdf: [$old_rdf]\nNew rdf: [$body]\n";
    eval {
        $self -> purge( $old_rdf );
        $self -> update( $body );
    };
    my $e = $@;
    if($e) {
        eval {
            $self -> purge( $body );
            $self -> update( $old_rdf );
        };

        $e -> throw if is_Exception( $e );
        throw RDF::Server::Exception::InternalServerError ( Content => $e );
    }
    return $self -> render( $formatter );
}


sub _triple {
    my($self, %params) = @_;
    my($subject, $predicate, $object);

    if( defined $params{subject_ns} && defined $params{subject_name} ) {
        $subject = new RDF::Core::Resource( @params{qw(subject_ns subject_name)} );     
    }
    else {
        $subject = new RDF::Core::Resource( $params{subject_uri} );
    } 
    
    if( defined $params{predicate_ns} && defined $params{predicate_name} ) {
        $predicate = new RDF::Core::Resource( @params{qw(predicate_ns predicate_name)} );
    }
    else {
        $predicate = new RDF::Core::Resource( $params{predicate_uri} );
    }   
        
    if( defined $params{object_literal} ) {  
        $object = new RDF::Core::Literal( @params{qw(object_literal object_lang object_datatype)} );
    }
    elsif( defined $params{object_ns} && defined $params{object_name} ) {
        $object = new RDF::Core::Resource( @params{qw(object_ns object_name)} );
    }
    else {
        $object = new RDF::Core::Resource( $params{object_uri} );
    }

    new RDF::Core::Statement( $subject, $predicate, $object );
}

sub _add_statements {
    my( $self, $triples, $root, $mapping) = (@_, {});
    my %counts;
    my $index = 0;
  
    foreach my $stmt ( reverse @{ $triples -> {$root} || [] } ) {
        #print STDERR "a: ", $stmt -> getLabel(), "\n";
        if( defined $mapping -> {$stmt -> getSubject -> getURI} ) {
            $stmt = RDF::Core::Statement -> new (
                        $mapping -> { $stmt -> getSubject -> getURI },
                        $stmt -> getPredicate,
                        $stmt -> getObject
                    );
        }

        if( $stmt -> getObject -> isLiteral ) {
            if( index($stmt -> getSubject -> getURI, '_:') == 0 &&
                $stmt -> getPredicate -> getNamespace eq RDF_NS &&
                $stmt -> getPredicate -> getLocalValue =~ /^_\d+$/ ) {
                # we want to make sure we don't need to do a few things
                # we want to count how many of these we're getting
                # we have all of them locally though   
                $counts{$stmt -> getObject -> getLabel} = $self -> model -> store -> countStmts($stmt -> getSubject, undef, $stmt -> getObject) unless defined $counts{$stmt -> getObject -> getLabel};
                if( $counts{$stmt -> getObject -> getLabel} -- <= 0 ) {
                    # add the triple
                    $index++;
                    while( $self -> model -> store -> existsStmt( $stmt -> getSubject, RDF::Core::Resource -> new( RDF_NS, "_$index" ), $stmt -> getObject ) ) {
                        $index++;
                    }
                    $self -> model -> store -> addStmt(
                        RDF::Core::Statement -> new(
                            $stmt -> getSubject,
                            RDF::Core::Resource -> new( RDF_NS, "_$index" ),
                            $stmt -> getObject
                        )
                    );
                }
            }
            else {
                $self -> model -> store -> addStmt( $stmt );
            }
        }
        else {
            if( index( $stmt -> getObject -> getURI, '_:') == 0
                && $self -> model -> store -> existsStmt( $stmt -> getSubject,
                                                          $stmt -> getPredicate ) ) {
                my $iter = $self -> model -> store -> getStmts( $stmt -> getSubject,
                                                                $stmt -> getPredicate );
                my $s = $iter -> getFirst;
                my($new_object, $o);
                while(defined $s && !defined $new_object) {
                    $o = $s -> getObject;
                    if( !$o -> isLiteral &&
                        index($o -> getURI, '_:') == 0 ) {
                        $new_object = $o;
                    }
                    $s = $iter -> getNext;
                }
                $iter -> close;
                if( defined $new_object ) {
                    $mapping -> { $o -> getURI } = $new_object;
                }
            }
            if( defined $mapping -> { $stmt -> getObject -> getURI } ) {
                $stmt = RDF::Core::Statement -> new(
                    $stmt -> getSubject,
                    $stmt -> getPredicate,
                    $mapping -> { $stmt -> getObject -> getURI }
                )
            }
            $self -> model -> store -> addStmt( $stmt );
            $self -> _add_statements( $triples, $stmt -> getObject -> getURI, $mapping );
        }
    }
}

sub _add_atom_updated {
    my($self) = @_;

    #my $stmt = RDF::Core::Statement -> new(
    #    RDF::Core::Resource -> new( $self -> model -> namespace, $self -> id ),
    #    RDF::Core::Resource -> new( ATOM_NS, 'updated' ),
    #    undef
    #);

    my $iter = $self -> model -> store -> getStmts(
        RDF::Core::Resource -> new( $self -> model -> namespace, $self -> id ),
        RDF::Core::Resource -> new( ATOM_NS, 'updated' ),
        undef
    );

    my $stmt = $iter -> getFirst;

    while($stmt) {
        $self -> model -> store -> removeStmt( $stmt );
        $stmt  = $iter -> getNext;
    }
    #$self -> model -> store -> removeStmt( $stmt ) if $self -> model -> store -> existsStmt($stmt -> getSubject, $stmt -> getPredicate, undef );

    my $dt = DateTime -> now();

    $stmt = RDF::Core::Statement -> new(
        RDF::Core::Resource -> new( $self -> model -> namespace, $self -> id ),
        RDF::Core::Resource -> new( ATOM_NS, 'updated' ),
        new RDF::Core::Literal(DateTime -> now -> iso8601 . 'Z', '', 'xsd:date')
    );

    $self -> model -> store -> addStmt( $stmt );
}

sub _add_dc_created {
    my($self) = @_;

    my $stmt = RDF::Core::Statement -> new(
        RDF::Core::Resource -> new( $self -> model -> namespace, $self -> id ),
        RDF::Core::Resource -> new( DC_NS, 'created' ),
        new RDF::Core::Literal(DateTime -> now -> iso8601 . 'Z', '', 'xsd:date')
    );

    $self -> model -> store -> addStmt( $stmt );
}

1;

__END__

=pod

=head1 NAME

RDF::Server::Resource::RDFCore

=head1 SYNOPSIS

=head1 DESCRIPTION

This class manages triples associated with a particular resource URL.

=head1 CONFIGURATION

=over 4

=item model

The RDF::Server::Model::RDFCore object managing the triple store in which the
data associated with this resource is stored.

=item bnode_prefix

The prefix used to build blank node ids.

=back

=head1 METHODS

=over 4

=item exists : Bool

Returns true if the resource object represents a collection of triples in
the triple store.

=item render

=item fetch

=item purge

=item remove

=item delete

=item modify

=item update

=item replace

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

