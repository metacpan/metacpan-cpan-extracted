package XMLRPC::Transport::HTTP::Plack;

use 5.006;
use strict;
use warnings;

use XMLRPC::Transport::HTTP;
use base qw(SOAP::Transport::HTTP::Plack);

=head1 NAME

XMLRPC::Transport::HTTP::Plack - transport for Plack (http://search.cpan.org/~miyagawa/Plack/) PSGI toolkit for XMLRPC::Lite module.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Provide support for HTTP Plack transport.

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

=head1 AUTHOR

Elena Bolshakova, C<< <e.a.bolshakova at yandex.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-soap-transport-http-plack at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SOAP-Transport-HTTP-Plack>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XMLRPC::Transport::HTTP::Plack


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SOAP-Transport-HTTP-Plack>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SOAP-Transport-HTTP-Plack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SOAP-Transport-HTTP-Plack>

=item * Search CPAN

L<http://search.cpan.org/dist/SOAP-Transport-HTTP-Plack/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Elena Bolshakova.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of XMLRPC::Transport::HTTP::Plack
