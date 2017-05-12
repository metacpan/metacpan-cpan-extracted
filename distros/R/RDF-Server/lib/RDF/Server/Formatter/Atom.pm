package RDF::Server::Formatter::Atom;

use Moose;
with 'RDF::Server::Formatter';

use MooseX::Types::Moose qw(ArrayRef Str);
use RDF::Server::Constants qw(:ns);
use RDF::Server::XMLDoc;
use XML::LibXML;
use RDF::Server::Exception;
use RDF::Server::Types qw( UUID );
use RDF::Server ();

# we need a way to communicate the mime type

sub wants_rdf { 1 }

###
# Entry / Resource formatting
###

sub _define_namespace {
    my($self, $e, $ns, $uri, $prefix) = @_;

    return if defined( $ns -> {$uri} ) && $ns -> {$uri} ne '';

    if( defined $ns -> {$uri} ) {
        $e -> setNamespaceDeclPrefix( '', $prefix );
    }
    else {
        $e -> setNamespace( $uri, $prefix, 1 );
    }

    $ns -> {$uri} = $prefix;
}

my @atom_elements = (
    [ ATOM_NS, 'category',   ATOM_NS, 'category' ],
    [ ATOM_NS, 'contributor',DC_NS,   'contributor' ],
    [ ATOM_NS, 'author',     DC_NS,   'creator' ],
    [ ATOM_NS, 'published',  DC_NS,   'publisher' ],
    [ ATOM_NS, 'rights',     DC_NS,   'rights' ],
    [ ATOM_NS, 'source',     DC_NS,   'source' ],
    [ ATOM_NS, 'summary',    DC_NS,   'description' ],
    [ ATOM_NS, 'title',      DC_NS,   'title' ],
    [ ATOM_NS, 'updated',    ATOM_NS, 'updated' ],
);

sub resource {
    my($self, $rdf) = @_;

    # now we need to wrap this in whatever is needed for Atom
=pod

=for Atom spec

atom:category (0 or more)
atom:content (0 or 1)
atom:contributor (0 or more)
atom:id (1)
atom:link (0 or more)
atom:published (0 or 1)
atom:rights (0 or 1)
atom:source (0 or 1)
atom:summary (0 or 1)
atom:title (1)
atom:updated (1)
extensionElements: (0 or more)


root element: atom:entry
=end Atom spec

=cut

    # categories... ?
    # we want to replace the <rdf:RDF /> with <atom:entry />
    # we want to 'unserialize' atom:content elements

    my $doc = RDF::Server::XMLDoc -> new( $rdf );

    my $root = $doc -> document -> documentElement();

    my %namespaces = map { $_ -> declaredURI => $_ -> declaredPrefix } $root -> getNamespaces;

    $self -> _define_namespace( $root, \%namespaces, ATOM_NS, 'xxatom');
    $self -> _define_namespace( $root, \%namespaces, APP_NS, 'xxapp');
    $self -> _define_namespace( $root, \%namespaces, RDF_NS, 'xxrdf');
    $self -> _define_namespace( $root, \%namespaces, DC_NS, 'xxdc');

    $root -> setNodeName( 'entry' );
    $root -> setNamespace( ATOM_NS, $namespaces{+ATOM_NS}, 1);

    my @content = $root -> findnodes( "/$namespaces{+ATOM_NS}:entry/$namespaces{+RDF_NS}:Description" );

    if( @content ) {
        $content[0] -> setNodeName( 'content' );
        $content[0] -> setNamespace( ATOM_NS, $namespaces{+ATOM_NS}, 1);
        $content[0] -> setAttribute( type => 'application/rdf+xml' );
    }

    my($e, $a);

    foreach my $translation ( @atom_elements ) {
        foreach $e ( $root -> findnodes( "/$namespaces{+ATOM_NS}:entry/$namespaces{+ATOM_NS}:content/$namespaces{$translation->[2]}:$translation->[3]") ) {
            $e -> setNodeName( $translation->[1] );
            $e -> setNamespace( $translation->[0], $namespaces{$translation->[0]}, 1);

            # check for rdf:resource attributes and change them to href
            if( $a = $e -> getAttributeNodeNS( RDF_NS, 'resource' ) ) {
                $e -> setAttribute( href => $a -> getValue );
                $e -> removeAttributeNS( RDF_NS, 'resource' );
            }
            $root -> insertBefore($e, $content[0]);
        }
    }

    if( $content[0] -> hasAttributeNS( RDF_NS, 'about' ) ) {
        my $id = $content[0] -> getAttributeNodeNS( RDF_NS, 'about' );
        my $idv = $id -> getValue();
        my $url = '';
        if( is_UUID($idv) ) {
            $url = 'urn:uuid:' . $idv;
        }
        else {
            $url = $idv;
        }
        my $textnode = $doc -> document -> createElement( 'id' );

        $textnode -> setNamespace( ATOM_NS, $namespaces{+ATOM_NS}, 1);
        $textnode -> appendText( $url );
        $root -> insertBefore( $textnode, $content[0] );
        $id -> unbindNode();
    }

    
    return( 'application/atom+xml', $doc );
}

sub to_rdf {
    my($self, $rdf) = @_;

    my $doc = RDF::Server::XMLDoc -> new( $rdf ); 

    my $root = $doc -> document -> documentElement();

    if($root -> localname ne 'entry' ||
       $root -> namespaceURI() ne ATOM_NS) {
        throw RDF::Server::Exception::BadRequest( Content => 'Document is not an atom:entry!' );
    }

    my %namespaces = map { $_ -> declaredURI => $_ -> declaredPrefix } $root -> getNamespaces;

    $self -> _define_namespace( $root, \%namespaces, ATOM_NS, 'xxatom');
    $self -> _define_namespace( $root, \%namespaces, APP_NS, 'xxapp');
    $self -> _define_namespace( $root, \%namespaces, RDF_NS, 'xxrdf');
    $self -> _define_namespace( $root, \%namespaces, DC_NS, 'xxdc');

    $root -> setNodeName( "$namespaces{+RDF_NS}:RDF" );
    $root -> setNamespace( RDF_NS, $namespaces{+RDF_NS}, 1 );
    
    my @content = $root -> findnodes( "$namespaces{+ATOM_NS}:content" );

    foreach my $e (@content) {
        my $type = $e -> getAttribute('type');
        confess "Undefined atom:content type" unless defined $type;
        if( $type ne 'application/rdf+xml' ) {
            confess "Unsupported atom:content type: $type";
        }
        $e -> setNodeName( 'Description' );
        $e -> setNamespace( RDF_NS, $namespaces{+RDF_NS}, 1);
        $e -> removeAttribute( 'type' );
    }

    foreach my $translation ( @atom_elements ) {
        my @elems = $root -> findnodes( "/$namespaces{+RDF_NS}:RDF/$namespaces{$translation->[0]}:$translation->[1]" );

        foreach my $e ( @elems ) {
            $e -> setNodeName( $translation->[3] );
    #        print STDERR "ns: ", join("; ", $translation->[2], $namespaces{$translation->[2]} ), "\n";
            $e -> setNamespace( $translation->[2], $namespaces{$translation->[2]}, 1);
            if( $a = $e -> getAttributeNode( 'href' ) ) {
                $e -> setAttributeNS( RDF_NS, resource => $a -> getValue );
                $e -> removeAttribute( 'href' );
            }
            $content[0] -> appendChild( $e );
        }
    }

    return $doc;
}

###
# List formatting
###

sub _add_text_node {
    my($self, $doc, $root, $e, $t) = @_;
    #print STDERR "_add_text_node($e => $t)\n";
    my $n = $doc -> createElement( $e );
    $n -> appendTextNode( $t );

    $root -> appendChild( $n );
}

#
# we expect: title, id, link
#     entries: iterator
#
sub feed {
    my($self, %c) = @_;

    my($doc, $root) = $self -> _new_xml_doc(ATOM_NS, 'feed');

    $self -> _add_text_node( $doc -> document, $root, 'atom:title', $c{title} );
    $self -> _add_text_node( $doc -> document, $root, 'atom:id', $c{id} );
    $self -> _add_text_node( $doc -> document, $root, 'atom:generator', "RDF::Server " . $RDF::Server::VERSION );

    my $n = $doc -> document -> createElement( 'atom:link' );
    $n -> setAttribute( href => $c{link} );
    $n -> setAttribute( rel => 'self' );


    my $e;
    if( $c{entries} ) {
        while( $e = $c{entries} -> next ) {
            my $eroot = $doc -> document -> createElement( 'atom:entry' );
            $self -> _add_text_node( $doc -> document, $eroot, 'atom:title', $e -> get_value(DC_NS, 'title') );
            $n = $doc -> document -> createElement( 'atom:link' );
            $n -> setAttribute( href => $e -> uri );
            $eroot -> appendChild( $n );
            my $id = $e -> id;
            if( is_UUID( $id ) ) {
                $id = "urn:uuid:$id";
            }
            else {
                $id = $e -> uri;
            }
            $self -> _add_text_node( $doc -> document, $eroot, 'atom:id', $id );
            $self -> _add_text_node( $doc -> document, $eroot, 'atom:updated', $e -> get_value(ATOM_NS, 'updated' ) || $e -> get_value(DC_NS, 'created') );
            $self -> _add_text_node( $doc -> document, $eroot, 'atom:summary', 'rdf content' );

            $root -> appendChild( $eroot );
        }
    }

    return( 'application/atom+xml', $doc );
}

sub category {
    my($self, %c) = @_;

    my($doc, $root) = $self -> _new_xml_doc(ATOM_NS, 'category');

    $self -> _add_text_node( $doc -> document, $root, 'atom:title', $c{title} || $c{term} );

    $root -> setAttribute( scheme => $c{scheme} );
    $root -> setAttribute( term => $c{term} );

    return( 'application/atom+xml', $doc );
}

sub collection {
    my($self, %c) = @_;

    my($doc, $root) = $self -> _new_xml_doc('collection');

    $self -> _add_text_node( $doc -> document, $root, 'atom:title', $c{title} );

    foreach my $a ( @{ $c{accept} || [] }) {
        $self -> _add_text_node( $doc -> document, $root, 'app:accept', $a );
        #$n = $doc -> document -> createElement( 'app:accept' );
        #$n -> appendTextNode( $a );
        #$root -> appendChild( $n );
    }

    if( $c{categories} ) {
        my $cats_root = $doc -> document -> createElement( 'app:categories' );

        if(is_ArrayRef( $c{categories} ) ) {
            foreach my $c ( @{$c{categories}} ) {
                my($t, $c_doc) = $self -> category(%$c);
                my $c_root = $self -> _import_as_child_of( $doc, $cats_root, $c_doc );
            }
        }
        elsif(is_Str( $c{categories} ) ) {
            $cats_root -> setAttribute( href => $c{categories} );
        }
        $root -> appendChild( $cats_root );
    }

    return( 'application/atom+xml', $doc );
}

sub workspace {
    my($self, %c) = @_;

    my($doc, $root) = $self -> _new_xml_doc('workspace');

    $self -> _add_text_node( $doc -> document, $root, 'atom:title', $c{title} );
    #my $n = $doc -> document -> createElement( 'atom:title');
    #$n -> appendTextNode( $c{title} );

    #$root -> appendChild( $n );

    foreach my $c (@{$c{collections}}) {
        my($t, $c_doc) = $self -> collection(%$c);

        my $c_root = $self -> _import_as_child_of( $doc, $root, $c_doc );
        $c_root -> setAttribute( href => $c -> {link} );
    }

    return( 'application/atom+xml', $doc );
}

sub service {
    my($self, %c) = @_;

    my($doc, $root) = $self -> _new_xml_doc('service');

    foreach my $w ( @{$c{workspaces}} ) {
        my($t, $w_doc) = $self -> workspace(%$w);

        my $w_root = $self -> _import_as_child_of( $doc, $root, $w_doc );
    }

    return( 'application/atomsvc+xml', $doc );
}

sub _import_as_child_of {
    my($self, $doc, $root, $other_doc) = @_;

    my $o_root = $other_doc -> document -> documentElement();
    $doc -> document -> importNode( $o_root );
    $root -> addChild( $o_root );
    return $o_root;
}

sub _new_xml_doc {
    my($self, $ns, $root_element);

    if( @_ == 2 ) {
        ($self, $root_element) = @_;
        $ns = APP_NS;
    }
    else {
        ($self, $ns, $root_element) = @_;
    }
    # produce an Atom document describing the workspaces (handlers)

    my $doc = XML::LibXML::Document -> new();

    my $root = $doc -> createElement($root_element);
    $root -> setNamespace( APP_NS, 'app', $ns eq APP_NS);
    $root -> setNamespace( ATOM_NS, 'atom', $ns eq ATOM_NS);
    $root -> setNamespace( $ns, 'a', 1) if $ns ne APP_NS && $ns ne ATOM_NS;

    $doc -> setDocumentElement( $root );

    return( RDF::Server::XMLDoc -> new($doc), $root );
}


1;

__END__

=pod

=head1 NAME

RDF::Server::Formatter::Atom - Work with Atom documents

=head1 SYNOPSIS

 package My::Server;

 protocol 'HTTP';
 interface 'REST';
 semantic 'Atom';

 render xml => 'Atom';

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item wants_rdf

Returns true.  The Atom formatter works with RDF documents.

=item resource

=item to_rdf

=item feed

=item category

=item collection

=item workspace

=item service

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

