# $Id: Response.pm 909 2012-07-13 15:38:39Z fil $
# Copyright 2010 Philip Gwyn

package POEx::HTTP::Server::Response;

use strict;
use warnings;

use Carp;
use POE;
use File::Basename;
use HTTP::Date;
use HTTP::Status qw( RC_NOT_FOUND RC_FORBIDDEN 
                     RC_NOT_MODIFIED RC_INTERNAL_SERVER_ERROR );

use base qw( HTTP::Response );

sub DEBUG () { 0 }

#######################################
# Get/set streaming status
sub streaming 
{
    my $self = shift;
    my $rv = $self->{__streaming};
    if (@_) { $self->{__streaming} = !!$_[0] }
    return $rv;
}

#######################################
# Get/set if the response header has been sent or not
sub headers_sent
{
    my $self = shift;
    my $rv = $self->{__headers_sent};
    if (@_) { $self->{__headers_sent} = !!$_[0] }
    return $rv;
}

#######################################
# End the request
sub done
{
    my( $self ) = @_;
    unless( $self->{__done} ) {
        carp "Only call ", ref($self), "->done once";
        return;
    }

    $poe_kernel->post( @{ delete $self->{__done} } );
}

sub finished { not exists $_[0]->{__done} }

#######################################
# Send some data.  But not all the data
sub send 
{
    my( $self, $something ) = @_;
    $self->__fix_headers;
    $poe_kernel->post( @{ $self->{__send} }, $something );
}

#######################################
# Send the response
sub respond
{
    my( $self ) = @_;

    croak "Responding more then once to a request" unless $self->{__respond};

    $self->__fix_headers;
    $poe_kernel->post( @{ delete $self->{__respond} } );
}

sub __fix_headers
{
    my( $self ) = @_;
    return if $self->headers_sent;
    my $req = $self->request;

    unless( $self->protocol ) {
        $self->protocol( $req->protocol );
    }

    unless( $self->header('Date') ) {
        $self->header( 'Date', time2str(time) );
    }

    if( not defined $self->header( 'Content-Length' ) and
        not $self->streaming and $req->method ne 'HEAD' ) {
        use bytes;
        my $c = $self->content;
        if( defined $c and $c ne '' ) {
            $self->header( 'Content-Length' => length $c );
        }
    }  
}

#######################################
# Helper routine for generating an error
sub error
{
    my( $self, $rc, $text ) = @_;

    $self->code( $rc );
    $self->content_type( 'text/plain' )
        unless defined $self->content_type;
    $self->content( $text );

    $self->respond;
    $self->done;

}

#######################################
# Send a file to the client
sub sendfile
{
    my( $self, $file, $ct ) = @_;

    DEBUG and warn "file=$file";

    my $path = $self->request->uri ?
               $self->request->uri->path : basename $file;
    unless( -f $file ) {
        $self->error( RC_NOT_FOUND, "No such file or directory $path" );
        return;
    }
    unless( -r $file ) {
        $self->error( RC_FORBIDDEN, "Denied $path: $!" );
        return;
    }

    # Info about the file
    my $lastmod = (stat $file)[9];
    my $size    = (stat $file)[7];
    DEBUG and warn "lastmod=$lastmod size=$size";

    # some required headers
    $self->header( 'Last-Modified' => time2str( $lastmod ) );
    unless( defined $self->content_type ) {
        $ct ||= 'application/octet-stream';
        DEBUG and warn "ct=$ct";
        $self->content_type( $ct );
    }

    # Bail early for HEAD requests
    if ( $self->request->method eq 'HEAD' and $size ) {
        $self->header( 'Content-Length' => $size );
        $self->respond;
        $self->done;
        return;
    }

    # Bail early for If-Modified-Since
    my $since = $self->request->header( 'If-Modified-Since' );
    if( $since ) {
        $since = str2time( $since );
        if ( $lastmod && $since && $since >= $lastmod ) {
            $self->remove_header( 'Last-Modified' );
            ## RFC 2616 section 4.3 says no content-length for 403
            # $response->content_length( $size );
            $self->code( RC_NOT_MODIFIED );  
            $self->respond;
            $self->done;
            return;
        }
    }

    $self->header( 'Content-Length' => $size );
    $self->__fix_headers;

    $poe_kernel->post( @{ $self->{__sendfile} }, $path, $file, $size );
}


1;

__END__

=head1 NAME

POEx::HTTP::Server::Response - Object encapsulating an HTTP response

=head1 SYNOPSIS

    use POEx::HTTP::Server;

    POEx::HTTP::Server->spawn( handler => 'poe:my-alias/handler' );

    # events of session my-alias:
    sub handler {
        my( $heap, $req, $resp ) = @_[HEAP,ARG0,ARG1];

        $resp->content_type( 'text/html' );
        $resp->content( $HTML );
        $resp->respond;
        $resp->done;
    }


=head1 DESCRIPTION

A C<POEx::HTTP::Server::Response> object is supplied as C<ARG1> to each
C<POEx::HTTP::Server::> request handler.  

It is a sub-class of L<HTTP::Response> with the following additions:


=head1 METHODS


=head2 done

    $req->done;

Finishes the request.  If keepalive isn't active, this will close the
connection.  Must be called after C<respond> or C<send>.  Having a seperate
L<done> and <respond> means that you can do some post processing after the
response was sent.

    $resp->content( $HTML );
    $resp->respond;
    $poe_kernel->yield( 'other_event', $resp );

    # Do some work in other_event
    $resp->done;

=head2 error

    $resp->error( $CODE, $TEXT );

Send C<$TEXT> as error message to the browser with status code of C<$CODE>.
The default I<Content-Type> is I<text/plain>, but this may be overridden by
setting the I<Content-Type> before hand.

When L</error> is called, the response is sent to the browser
(C<L</respond>>) and the request is finished (C<L</done>>).

=head2 finished

False; will be set to true when L</done> is called.

=head2 respond

    $resp->respond;

Sends the response to the browser.  Sends headers if they aren't already
sent.  No more content may be sent to the browser after this method call.
L</done> must still be called to finish the request.

=head2 send

    $resp->send( [$CONTENT] );

Sends the response header (if not already sent) and C<$CONTENT> to the
browser (if defined). The request is kept open and furthur calls to C<send>
are allowed to send more content to the browser.

=head3 sendfile

    $resp->sendfile( $FILE );
    $resp->sendfile( $FILE, $CONTENT_TYPE );

Sends the static file $FILE to the browser.  This method also deals with the
requirements of C<HEAD> requests and C<If-Modified-Since> requests.

You may specify the content-type of the file either by calling
L<content_type> directly or by passing C<$CONTENT_TYPE> as a parameter. If
the content-type hasn't already been selected, it defaults to
C<application/octet-stream>.

If L<Sys::Sendfile> is installed, C<sendfile> is used to efficiently send
the file over the socket.  Otherwise the file is sent in 
L<POEx::HTTP::Server/blocksize> sized chunks.

=head3 headers_sent

    unless( $resp->headers_sent ) {
        $resp->headers_sent( 1 );
        # ...
    }

Gets or sets the fact that a response header has already been sent.

=head3 streaming

    $resp->streaming( 1 );

Turns on streaming mode for the socket.  L</send> does this also.


=head1 SEE ALSO

L<POEx::HTTP::Server>, L<POEx::HTTP::Server::Response>.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
