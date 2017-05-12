package RDF::Server::Interface::REST;

use Moose::Role;
with 'RDF::Server::Interface';

use RDF::Server::Types qw(Renderable Container Mutable);

use RDF::Server::Exception;
use RDF::Server::Constants qw(HTTP_OK);
use HTTP::Response;
use URI;


sub handle_request {
    my($self, $request, $response) = @_;

    my $method = $request -> method;

    my $uri_path = URI -> new( $request -> uri ) -> path;

    my $extension = '';
    if( $uri_path =~ s{\.([^/.]+)$}{} ) {
        $extension = $1;
    }
    my $formatter = $self -> formatter( $extension );

    my($handler, $path_info) = $self -> handler -> handles_path( '', $uri_path, ($method ne 'POST' ? 1 : 0) );

    if( !defined $handler ) { # no document found
        throw RDF::Server::Exception::NotFound;
    }

    #print STDERR "handler: $handler\n";
    my %allowed;

    if( is_Renderable( $handler ) ) {
        $allowed{GET}++;
    }

    if( is_Mutable( $handler ) ) {
        $allowed{PUT}++;
        $allowed{DELETE}++;
        $allowed{POST}++;
    }
    if( is_Container( $handler ) ) {
        $allowed{POST}++;
    }

    throw RDF::Server::Exception::MethodNotAllowed Allow => [keys %allowed]
        unless $allowed{$method};

    $response -> code( HTTP_OK );
    if( $method eq 'GET' ) {
        # build response
        my( $content_type, $content ) = $handler -> render( $formatter, $uri_path );
        $response -> content( $content );
        $response -> header( 'Content-Type' => $content_type );
    }
    elsif( $method eq 'DELETE' ) {
        if( $request -> content ) {
            $handler -> remove( $formatter, $request -> content );
            my( $content_type, $content ) = $handler -> render( $formatter, $uri_path );
            $response -> content( $content );
            $response -> header( 'Content-Type' => $content_type );
        }
        else {
            $handler -> delete;
        }
    }
    elsif( $method eq 'POST' ) {
        if( is_Container( $handler ) ) {
            if( $request -> content) {
                my $object = $handler -> create( $formatter, $path_info, $request -> content );
                if( is_Renderable( $object ) ) {
                    my( $content_type, $content ) = $object -> render( $formatter, $uri_path );
                    $response -> content( $content );
                    $response -> header( 'Content-Type' => $content_type );
                    $response -> code( 201 ); # created
                    $response -> header( Location => $object -> uri . ($extension ? '.' . $extension : '') );
                }
                else {
                    eval { $object -> purge; };
                    throw RDF::Server::Exception::InternalServerError(
                        Content => 'Did not get a renderable document!'
                    );

                }
            }
        }
        else {
            if( $request -> content ) {
                $handler -> replace( $formatter, $request -> content );
            }
            else {
                throw RDF::Server::Exception::BadRequest(
                    content => 'Did not supply a document!'
                );
            }
        }
    }
    elsif( $method eq 'PUT' ) {
        if( $request -> content) {
            my( $content_type, $content) = $handler -> modify( $formatter, $request -> content );
            $response -> content( $content );
            $response -> header( 'Content-Type' => $content_type );
        }
    }
    else {
        # we shouldn't ever get here
    }
}

1;

__END__

=pod

=head1 NAME

RDF::Server::Interface::REST - REST interface

=head1 SYNOPSIS

 package My::Server;

 use RDF::Server;
 interface 'REST';

=head1 DESCRIPTION

This module provides a REST interface based on the Atom specification 
(RFC 5023).

The top level handler can be any class that implements the 
RDF::Server::Role::Handler role.  All handlers should at least implement
the RDF::Server::Role::Renderable role if they are browsable.  Otherwise,
path components will resolve, but indexes will not be retrievable.

The leaf handlers should implement the RDF::Server::Role::Mutable role to
support the full REST protocol.

The Atom semantic allows easy configuration of an Atom document heirarchy.

=head1 METHODS

=over 4

=item handle_request

Given the request and response objects, this method will find the
proper handler and hand off handling to the proper handler method.
The response from the handler is then translated to the response object.

=back

=head1 SEE ALSO

L<RDF::Server::Role::Handler>,
L<RDF::Server::Role::Renderable>,
L<RDF::Server::Role::Container>,
L<RDF::Server::Role::Mutable>,
L<RDF::Server::Semantic::Atom>,
RDF 5023.

=head1 AUTHOR

James Smith, C<< <jsmith@cpan.org> >>

=head1 LICENSE

Copyright (c) 2008  Texas A&M University.

This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
