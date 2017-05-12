package RDF::Server::Protocol::Embedded;

use Moose::Role;

with 'RDF::Server::Protocol';
with 'RDF::Server::Interface::REST';

use HTTP::Status qw(RC_OK RC_NOT_FOUND RC_METHOD_NOT_ALLOWED RC_INTERNAL_SERVER_ERROR);
use HTTP::Request;
use HTTP::Response;

use RDF::Server::Exception;

use RDF::Server::Types qw(Exception);


no Moose::Role;

sub handle {
    my($self, $method, $uri, $content) = @_;

    my $request = HTTP::Request -> new( $method => $uri );
    $request -> content( $content ) if defined $content;

    my $response = HTTP::Response -> new();

    $self -> handle_request($request, $response);

    return $response;
}

sub fetch {
    my( $self, $uri ) = @_;

    return unless defined wantarray;
    $self -> handle( GET => $uri ) -> content;
}

sub delete {
    my( $self, $uri, $content ) = @_;

    eval {
        $self -> handle( DELETE => $uri, $content );
    };
    return $@ eq '';
}

sub update {
    my( $self, $uri, $content ) = @_;

    my $r = $self -> handle( PUT => $uri, $content );
    return $r -> content if defined wantarray;
}

sub create {
    my( $self, $uri, $content ) = @_;

    my $r = $self -> handle( POST => $uri, $content );

    return unless defined wantarray;
    return ( $r -> header('Location'), $r -> content );
}

1;

__END__

=pod

=head1 NAME

RDF::Server::Protocol::Embedded - methods to use RDF::Server in another program

=head1 SYNOPSIS

 package My::Server;

 protocol 'Embedded';
 semantic ...;


 my $service = My::Server -> new( ... );

 $service -> create( $uri => $content );
 $content = $service -> fetch( $uri );
 $service -> update( $uri => $content );
 $service -> delete( $uri );
 $service -> delete( $uri => $content );

=head1 DESCRIPTION

The embedded protocol translates a simple Perl API into a REST-based set
of requests that are passed to the interface.

When using the embedded protocol, you do not need to load an interface since
the REST interface is already loaded by the protocol.

=head1 CONFIGURATION

There is no special configuration specific to this role.  See the documentation
for the interface and semantic roles for any configuration that might be
required.

=head1 METHODS

=over 4

=item handle ($method, $uri, $content)

Creates the request and passes it to the REST request handler.  Returns
the resulting response object.

This method is used to implement the other, more specific methods.

=item create ($uri, $content)

Creates a resource at the given URI.  This becomes a POST request internally.

=item fetch ($uri)

Returns the appropriate document for the given URI.  This becomes a GET
request internally.

=item update ($uri, $content)

Merges the provided document with any data already present in the triple store.
Internally, this becomes a PUT request.  

This will not replace the triples
associated with a resource.  To completely replace the existing information,
first delete the resource and then create a new version with the desired
information.

=item delete ($uri)

This form will remove all information associated with the given URI.
Internally, this becomes a DELETE request without a content body.

=item delete ($uri, $content)

This form will remove only the information contained in the provided content.
Internally, this becomes a DELETE request with a content body.

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

