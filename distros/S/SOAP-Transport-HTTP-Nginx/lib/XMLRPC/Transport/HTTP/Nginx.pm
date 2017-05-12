package XMLRPC::Transport::HTTP::Nginx;
use warnings;
use strict;
use XMLRPC::Transport::HTTP;
use base qw(SOAP::Transport::HTTP::Nginx);

=head1 NAME

XMLRPC::Transport::HTTP::Nginx - transport for nginx (L<http://nginx.net/>) http server for XMLRPC::Lite module.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Provide support for HTTP Nginx transport.

=head1 FUNCTIONS

=over

=item initialize

Initializes server. "Autocalled" from server initialization.

=cut

sub initialize; *initialize = \&XMLRPC::Server::initialize;

=item make_fault

Make fault. "Autocalled" from server side on fault.

=cut

sub make_fault; *make_fault = \&XMLRPC::Transport::HTTP::CGI::make_fault;

=item make_response

Make response. "Autocalled" from server side on response.

=cut

sub make_response; *make_response = \&XMLRPC::Transport::HTTP::CGI::make_response;

=back

=head1 DEPENDENCIES

 XMLRPC::Transport::HTTP   base HTTP transport module

=head1 SEE ALSO

 See XMLRPC::Lite for details.
 See examples/* for examples.
 See http://httpnginx.sourceforge.net, http://sourceforge.net/scm/?type=svn&group_id=257229 for project details/svn_code.

=head1 AUTHOR

Alexander Soudakov, C<< <cygakoB at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-soap-transport-http-nginx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SOAP-Transport-HTTP-Nginx>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XMLRPC::Transport::HTTP::Nginx

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SOAP-Transport-HTTP-Nginx>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SOAP-Transport-HTTP-Nginx>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SOAP-Transport-HTTP-Nginx>

=item * Search CPAN

L<http://search.cpan.org/dist/SOAP-Transport-HTTP-Nginx/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Alexander Soudakov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

12;
