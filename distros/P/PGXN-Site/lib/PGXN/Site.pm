package PGXN::Site;

use 5.10.0;
use utf8;
our $VERSION = v0.10.3;

sub version_string {
    sprintf 'v%vd', $VERSION;
}

1;

=head1 Name

PGXN::Site - Maintain and serve a PGXN web site

=head1 Synopsis

  pgxn_site_server --api-url     http://api.pgxn.org/ \
                   --errors-from oops@example.com \
                   --errors-to   alerts@example.com \
                   --feedback-to feedback@example.com

=head1 Description

L<PGXN|http://pgxn.org> is a L<CPAN|http://cpan.org>-inspired network for
distributing extensions for the L<PostgreSQL RDBMS|http://www.postgresql.org>.
All of the infrastructure tools, however, have been designed to be used to
create networks for distributing any kind of release distributions and for
providing a lightweight static file JSON REST API.

This module provides a simple PGXN web site. All it needs is a
L<PGXN::API>-powered API to get the data it needs. Such an API can be accessed
either remotely or via the local file system.

To run your own PGXN web server, just install this module and run the included
L<<pgxn_site_server> L<Plack> server, passing it the following options:

=over

=item C<api_url>

The URL to use to access the L<PGXN::API> server. Required.

=item C<private_api_url>

A private URL to use to access the L<PGXN::API>-powered API. Optional. Useful
if you're serving the site and the API from the same box (or with access to
the same file system) and want it to be fast: just specify a C<file:> URL here
and the API will be read directly from the file system. The C<api_url> option
will still be used for public URLs pointing to the API in the UI.

=item C<proxy_url>

If you need to access C<private_api_url> via a proxy server, provide the URL for that
proxy server in this option.

=item C<errors_to>

An email address to which error emails should be sent. In the event of an
internal server error, the server will send an email to this address with
diagnostic information.

=item C<errors_from>

An email address from which alert emails should be sent.

=item C<feedback_to>

An email address to which feedback emails should be sent. This email address
will be provided as a clickable link.

=back

=head1 Interface

The PGXN::Site class itself consists of a single class method.

=head2 Class Method

=head3 C<version_string>

  say 'PGXN::Site ', PGXN::Site->version_string;

Returns a string representation of the PGXN::Site version.

=head1 Author

David E. Wheeler <david.wheeler@pgexperts.com>

=head1 Copyright and License

Copyright (c) 2010-2013 David E. Wheeler.

This module is free software; you can redistribute it and/or modify it under
the L<PostgreSQL License|http://www.opensource.org/licenses/postgresql>.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement is
hereby granted, provided that the above copyright notice and this paragraph
and the following two paragraphs appear in all copies.

In no event shall David E. Wheeler be liable to any party for direct,
indirect, special, incidental, or consequential damages, including lost
profits, arising out of the use of this software and its documentation, even
if David E. Wheeler has been advised of the possibility of such damage.

David E. Wheeler specifically disclaims any warranties, including, but not
limited to, the implied warranties of merchantability and fitness for a
particular purpose. The software provided hereunder is on an "as is" basis,
and David E. Wheeler has no obligations to provide maintenance, support,
updates, enhancements, or modifications.

=cut

