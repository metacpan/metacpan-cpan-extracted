package RDF::AllegroGraph;

=pod

=head1 NAME

RDF::AllegroGraph - Client implementation for the AllegroGraph tuple server

=head1 DESCRIPTION

The AllegroGraph server is a tuple store server, produced by Franz Inc. (L<http://agraph.franz.com/allegrograph/>).
When running, you can communicate with it via a RESTful web interface, as described in

L<http://agraph.franz.com/support/documentation/3.2/new-http-server.html>

and
L<http://www.franz.com/agraph/support/documentation/v4/http-protocol.html>

respectively.

This package offers a client implementation of that protocol. With it you can either use
a rather orthodox style (L<RDF::AllegroGraph::Server>) or a quick-n-easy approach (L<RDF::AllegroGraph::Easy>).

B<NOTE>: This is still exploratory. See the TODO.

=head1 FAQ

=over

=item I<I receive a protocol error: 400 Bad Request from the server>

4xx responses normally mean that the client is to blame, but AG seems to send such responses also in
the case it has permission problems on the server. Maybe check that first.

=item I<The tests - with AG4_SERVER defined - run a bit slow...>

True, but that is because the many repository creations and deletions. That is not a fast operation.

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 20(0[9]|10|11) Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

Test data courtesy of Franz Inc.

=head1 SEE ALSO

L<RDF::AllegroGraph::Server4>, L<RDF::AllegroGraph::Easy>

=cut

our $VERSION = '0.04';

1;
