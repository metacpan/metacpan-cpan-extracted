package SOAP::Transport::HTTP::Plack;

use 5.006;
use strict;
use warnings;

use SOAP::Transport::HTTP;
use base qw(SOAP::Transport::HTTP::Server);

=head1 NAME

SOAP::Transport::HTTP::Plack - transport for Plack (http://search.cpan.org/~miyagawa/Plack/) PSGI toolkit for SOAP::Lite module.

The module is quite similar to SOAP::Transport::HTTP::Apache. 

Docs were stolen completely from SOAP::Transport::HTTP::Nginx.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Provide support for HTTP Plack transport.

=head1 FUNCTIONS

=over

=item DESTROY

Destructor. Add tracing if object was initialized so.

=cut
sub DESTROY { SOAP::Trace::objects('()') }

=item new

Constructor. "Autocalled" from server side.

=cut
sub new { 
    my $self = shift;

    unless (ref $self) {
        my $class = ref($self) || $self;
        $self = $class->SUPER::new(@_);
        SOAP::Trace::objects('()');
    }
    return $self;
}

=item handler

Handler server function. "Autocalled" from server side.

=cut
sub handler { 
    my $self = shift->new; 
    my $r = shift;  

    $self->request(HTTP::Request->new( 
            $r->method => $r->uri,
            $r->headers,
            do { $r->content; } 
        ));
    $self->SUPER::handle;

    my $code = $self->response->code;
    my @headers;
    $self->response->headers->scan(sub { push @headers, @_ });
    return [$code, \@headers, [$self->response->content] ];
}

=item handle

Alias for handler.

=cut

{ 
    #just create alias
    sub handle; 
    *handle = \&handler 
} 

=back

=head1 AUTHOR

Elena Bolshakova, C<< <e.a.bolshakova at yandex.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-soap-transport-http-plack at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SOAP-Transport-HTTP-Plack>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SOAP::Transport::HTTP::Plack


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

1; # End of SOAP::Transport::HTTP::Plack
