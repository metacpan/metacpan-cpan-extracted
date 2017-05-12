package RDF::Server::Formatter::JSON;

use Moose;
with 'RDF::Server::Formatter';

use MooseX::Types::Moose qw(ArrayRef Str);
use RDF::Server::Constants qw(:ns);
use JSON::Any;
use RDF::Server::Exception;

# we need a way to communicate the mime type

our $JSON = JSON::Any -> new;

sub wants_rdf { 0 }

###
# Entry / Resource formatting
###

sub resource { return ( 'application/json', $JSON -> encode($_[1]) ); }

sub to_rdf {  
    my($self, $content) = @_;

    throw RDF::Server::Exception::BadRequest
       Content => 'Not implemented';

#    my $data = $JSON -> decode( $content );

    # now make RDF from the data structure
}

###
# List formatting
###

sub feed {
    my($self, @list) = @_;

    return( 'application/json', $JSON -> encode( \@list ) );
}

sub category {
    my($self, %c) = @_;

    return( 'application/json', $JSON -> encode( \%c ) );
}

sub collection {
    my($self, %c) = @_;

    return( 'application/json', $JSON -> encode( \%c ) );
}

sub workspace {
    my($self, %c) = @_;

    return( 'application/json', $JSON -> encode( \%c ) );
}

sub service {
    my($self, %c) = @_;

    return( 'application/json', $JSON -> encode( \%c ) );
}

1;

__END__

=pod

=head1 NAME

RDF::Server::Formatter::JSON - Work with JSON documents

=head1 SYNOPSIS

 package My::Server;

 protocol 'HTTP';
 interface 'REST';
 semantic 'Atom';

 format json => 'JSON';

=head1 DESCRIPTION

Formats documents as JSON for easy use by JavaScript programs.  This formatter
is currently for read-only operations and does not support submitting 
JSON to the server.

=head1 METHODS

All methods that return a document also return a mime type of
application/json as the first element of a two-element array.  The document
is the second element.

=over 4

=item wants_rdf

Returns false.  The JSON formatter works with perl data structures instead of
RDF documents.

=item resource

This will return the resource data encoded as JSON.

=item to_rdf

This will accept JSON and return RDF.  This method is not yet implemented.
This method does not return a mime type.

=item feed

Returns a JSON representation of a list of resources.

=item category

Returns a JSON representation of a document following the semantics of an
atom:category document.

=item collection

Returns a JSON representation of a document following the semantics of an
app:collection document: a list of categories.

=item workspace

Returns a JSON representation of a document following the semantics of an
app:workspace document: a list of collections.

=item service

Returns a JSON representation of a document following the semantics of an
app:service document: a list of workspaces.

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

