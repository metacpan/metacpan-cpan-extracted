package RDF::Server::Formatter::RDF;

use Moose;
with 'RDF::Server::Formatter';

use MooseX::Types::Moose qw(ArrayRef Str);
use RDF::Server::Constants qw(:ns);
use RDF::Server::XMLDoc;
use XML::LibXML;
use RDF::Server::Exception;

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

sub resource { ( 'application/rdf+xml', $_[1] ) }

sub to_rdf { $_[1] }

###
# List formatting
###

sub feed {
    my($self, @list) = @_;

    throw RDF::Server::Exception::BadRequest
       Content => 'Not implemented';

#    my $doc;

#    return( 'application/rdf+xml', RDF::Server::XMLDoc -> new( document => $doc ) );
}

sub category {
    my($self, %c) = @_;

    throw RDF::Server::Exception::BadRequest
       Content => 'Not implemented';


#    my($doc, $root) = $self -> _new_xml_doc('RDF');

#    return( 'application/rdf+xml', $doc );
}

sub collection {
    my($self, %c) = @_;

    throw RDF::Server::Exception::BadRequest
       Content => 'Not implemented';

#    my($doc, $root) = $self -> _new_xml_doc('RDF');

#    return( 'application/rdf+xml', $doc );
}

sub workspace {
    my($self, %c) = @_;

    throw RDF::Server::Exception::BadRequest
       Content => 'Not implemented';

#    my($doc, $root) = $self -> _new_xml_doc('RDF');

#    return( 'application/rdf+xml', $doc );
}

sub service {
    my($self, %c) = @_;

    throw RDF::Server::Exception::BadRequest
       Content => 'Not implemented';

#    my($doc, $root) = $self -> _new_xml_doc('RDF');

#    return( 'application/rdf+xml', $doc );
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
        $ns = RDF_NS;
    }
    else {
        ($self, $ns, $root_element) = @_;
    }
    # produce an RDF document describing the workspaces (handlers)

    my $doc = XML::LibXML::Document -> new();

    my $root = $doc -> createElement($root_element);
    $root -> setNamespace( RDF_NS, 'rdf', $ns eq RDF_NS);
    #$root -> setNamespace( ATOM_NS, 'atom', $ns eq ATOM_NS);
    #$root -> setNamespace( $ns, 'a', 1) if $ns ne APP_NS && $ns ne ATOM_NS;
    $root -> setNamespace( $ns, 'a', 1) if $ns ne RDF_NS;

    $doc -> setDocumentElement( $root );

    return( RDF::Server::XMLDoc -> new($doc), $root );
}


1;

__END__

=pod

=head1 NAME

RDF::Server::Formatter::RDF - Work with RDF/RSS documents

=head1 SYNOPSIS

 package My::Server;

 protocol 'HTTP';
 interface 'REST';
 semantic 'Atom';

 format [qw(rdf rss)] => 'RDF';

=head1 DESCRIPTION

Creates RDF/RSS documents.  This is primarily a thin interface module since
the internal data is managed as RDF.

Most methods that return documents also return a mime type of
application/rdf+xml.

=head1 METHODS

=over 4

=item wants_rdf

This returns true.  The RDF formatter works with RDF when rendering
resources.

=item resource

Returns an RDF representation of a resource.

=item to_rdf

Returns the RDF representation of the given RDF document.

=item feed

Returns an RSS representation of a list of resources.

=item category

Returns an RDF document describing a category.  Categories are part of
the ATOM spec.

=item collection

Returns an RDF document describing a set of resources and categories.
Collections are part of the ATOM spec.

=item workspace

Returns an RDF document describing a set of collections.  Workspaces
are part of the ATOM spec.

=item service

Returns an RDF document describing a set of workspaces.  Services
are part of the ATOM spec.

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

