package SOAP::Transport::HTTP::Nginx;
use warnings;
use strict;
use SOAP::Transport::HTTP;
use base qw(SOAP::Transport::HTTP::Server);
# can be required/evaled only from nginx environment
# preserve for other code
eval{ require nginx };

use constant HTTP_HEADERS => qw(
	Accept
	Accept-Charset
	Accept-Encoding
	Accept-Language
	Accept-Ranges
	Age
	Allow
	Authorization
	Cache-Control
	Connection
	Content-Disposition
	Content-Encoding
	Content-Language
	Content-Length
	Content-Location
	Content-MD5
	Content-Range
	Content-Type
	Cookie
	Date
	ETag
	Expires
	Host
	If-Modified-Since
	If-None-Match
	Last-Modified
	Location
	Referer
	Server
	Set-Cookie
	User-Agent
);

=head1 NAME

SOAP::Transport::HTTP::Nginx - transport for nginx (L<http://nginx.net/>) http server for SOAP::Lite module.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Provide support for HTTP Nginx transport.

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
    my $content = shift;
    my $cont_len = $r->header_in('Content-length');
    unless($cont_len > 0) {
	  no strict "subs";
      return HTTP_BAD_REQUEST;
    }

    $self->request(
		   HTTP::Request->new(
				      $r->request_method() => $r->uri,
				      HTTP::Headers->new(
							 map { $_ => $r->header_in($_) } &HTTP_HEADERS(),
							),
				      $content
				     )
		  );
    $self->SUPER::handle;

    # TODO: check this out
    # we will specify status manually for Apache, because
    # if we do it as it has to be done, returning SERVER_ERROR,
    # Apache will modify our content_type to 'text/html; ....'
    # which is not what we want.
    # will emulate normal response, but with custom status code
    # which could also be 500.
    $r->status($self->response->code);

    $r->print($self->response->content);
    return $self->{OK};
}

=item configure

Configure server. "Autocalled" from server side.

=cut

sub configure {
    my $self = shift->new;
    my $config = shift->dir_config;
    for (%$config) {
        $config->{$_} =~ /=>/
            ? $self->$_({split /\s*(?:=>|,)\s*/, $config->{$_}})
            : ref $self->$_()
                ? () # hm, nothing can be done here
                : $self->$_(split /\s+|\s*,\s*/, $config->{$_})
            if $self->can($_);
    }
    return $self;
}

{

=item handle

Alias for handler.

=cut

    # just create alias
    sub handle;
    *handle = \&handler
}

=back

=head1 DEPENDENCIES

 SOAP::Transport::HTTP    base HTTP transport module

=head1 SEE ALSO

 See SOAP::Lite for details.
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

    perldoc SOAP::Transport::HTTP::Nginx

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
