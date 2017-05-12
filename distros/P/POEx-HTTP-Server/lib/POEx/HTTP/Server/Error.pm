# $Id: Error.pm 909 2012-07-13 15:38:39Z fil $
# Copyright 2010 Philip Gwyn

package POEx::HTTP::Server::Error;

use strict;
use warnings;

use base qw( POEx::HTTP::Server::Response );

sub details
{
    my( $self, $op, $errnum, $errstr ) = @_;
    $self->{op} = $op;
    $self->{errnum} = $errnum;
    $self->{errstr} = $errstr;

    $self->content( "$op error [$errnum] $errstr" );
}

sub op     { $_[0]->{op} }
sub errnum { $_[0]->{errnum} }
sub errstr { $_[0]->{errstr} }
sub errstring { $_[0]->{errstring} }

1;

__END__

=head1 NAME

POEx::HTTP::Server::Error - Object encapsulating an error

=head1 SYNOPSIS

    use POEx::HTTP::Server;

    POEx::HTTP::Server->spawn( handlers => {
                on_error => 'poe:my-alias/error' );

    # events of session my-alias:
    sub error {
        my( $heap, $ereq ) = @_[HEAP,ARG0,ARG1];

        if( $err->op ) {
            warn $err->op, " error [", $err->errnum, "] ", $err->errstr;
        }
        else {
            warn $err->content;
        }
    }


=head1 DESCRIPTION

This object encapsulates a network error or an HTTP error for reporting
to L<POEx::HTTP::Server/on_error> special handlers.

Network errors are those reported by L<POE::Wheel::SocketFactory>,
L<POE::Wheel::ReadWrite> and L<Sys::Sendfile/sendfile> if that is used.

HTTP errors are those reported by L<POE::Filter::HTTPD> when it detects a
mal-formed header or errors internal to L<POEx::HTTP::Server>.  However,
errors reported with L<POEx::HTTP::Server::Response/error> do not invoke
C<on_error>.

HTTP errors are nearly always sent to the browser.  You may modify the
L<HTTP::Response/content> or prevent them being sent by setting
L<POEx::HTTP::Server::Response/sent>.

HTTP errors will always close the connection, even if keep-alive is set.

=head1 METHODS

As this is a sub-class of L<POEx::HTTP::Server::Response>, all that class's
methods are available.  Note, however, that
L<POEx::HTTP::Server::Response/request> might be C<undef>.

=head2 op

Returns the name of the operation that failed.
Can be one of C<read>, C<write>, C<bind> or C<sendfile>.

=head2 errnum

Returns the system error number; the numeric value of $!.

=head2 errstr

Returns the system error string; the string value of $!.

=head2 errstring

Same as L</errstr>.

=head1 SEE ALSO

L<POEx::HTTP::Server>, 
L<POEx::HTTP::Server::Response>, 
L<HTTP::Response>.


=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
