package RDF::Server::Protocol;

use Moose::Role;

sub log_request {
    my($self, $request, $response) = @_;
    # log the request and resulting return code
    my $logger = Log::Log4perl -> get_logger($self -> meta -> name);
#10.211.55.2 dev.local:81 - [08/Mar/2008:01:50:29 -0600] "GET /RDF-Server/cover_db/blib-lib-RDF-Server-Role-Mutable-pm.html HTTP/1.1" 200 3624 "http://dev.local:81/RDF-Server/cover_db/coverage.html" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-us) AppleWebKit/523.15.1 (KHTML, like Gecko) Version/3.0.4 Safari/523.15"

    my $request_string = $request -> method . ' ' . $request -> uri;
    $request_string =~ s{\s+}{ }g;
    $request_string =~ s{^\s+}{};
    $request_string =~ s{\s+$}{};
    $logger -> info(
        sprintf('"%s" %3d %d', 
                $request_string, 
                $response -> code,
                length( $response -> content )
        )
    );
}


1;

__END__

=pod

=head1 NAME

RDF::Server::Protocol - defines how RDF::Server communicates with the world

=head1 SYNOPSIS

 package My::Protocol;

 use Moose::Role;
 with 'RDF::Server::Protocol';

=head1 DESCRIPTION

A protocol module translates between the world and the interface module,
creating and using HTTP::Request and HTTP::Response objects as needed.

=head1 REQUIRED METHODS

No methods are required by this role.

=head1 PROVIDED METHODS

=over 4

=item log_request

This method will log the protocol equivalen of the
HTTP request, response code, and response content length.

=back

=head1 SEE ALSO

L<RDF::Server::Protocol::HTTP>

=head1 AUTHOR

James Smith, C<< <jsmith@cpan.org> >>

=head1 LICENSE

Copyright (c) 2008  Texas A&M University.

This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
