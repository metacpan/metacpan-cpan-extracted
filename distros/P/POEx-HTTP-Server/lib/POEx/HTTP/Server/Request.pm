# $Id: Request.pm 909 2012-07-13 15:38:39Z fil $
# Copyright 2010 Philip Gwyn

package POEx::HTTP::Server::Request;

use strict;
use warnings;

use base qw( HTTP::Request );


sub connection
{
    my( $self, $connection ) = @_;
    my $rv = $self->{connection};
    $self->{connection} = $connection if 2==@_;
    return $rv;
}

1;

__END__

=head1 NAME

POEx::HTTP::Server::Request - Object encapsulating an HTTP request

=head1 SYNOPSIS

    use POEx::HTTP::Server;

    POEx::HTTP::Server->spawn( handler => 'poe:my-alias/handler' );

    # events of session my-alias:
    sub handler {
        my( $heap, $req, $resp ) = @_[HEAP,ARG0,ARG1];

        my $c = $req->connection;
        warn "Request to ", $c->local_addr, ":", $c->local_port;
        warn "Request from ", $c->remote_addr, ":", $c->remote_port;
    }


=head1 DESCRIPTION

A C<POEx::HTTP::Server::Request> object is supplied as C<ARG0> to each
C<POEx::HTTP::Server::> request handler.  

It is a sub-class of L<HTTP::Request>.


=head1 METHODS


=head2 connection

Returns an L<POEx::HTTP::Server::Connection> object.

=head1 SEE ALSO

L<HTTP::Request>,
L<POEx::HTTP::Server>, 
L<POEx::HTTP::Server::Response>, 
L<POEx::HTTP::Server::Connection>.


=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
