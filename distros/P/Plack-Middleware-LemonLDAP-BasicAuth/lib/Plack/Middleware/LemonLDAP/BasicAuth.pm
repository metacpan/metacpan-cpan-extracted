package Plack::Middleware::LemonLDAP::BasicAuth;

# ABSTRACT: Middleware to provide LemonLDAP support for Plack applications

use strict;
use warnings;

use parent 'Plack::Middleware::Auth::Basic';

use HTTP::Headers;
use MIME::Base64 qw(decode_base64);
use SOAP::Lite;

use Plack::Util::Accessor qw(portal cookiename);

our $VERSION = 0.02;

sub prepare_app {
    my ($self) = shift;

    $self->authenticator( sub{ $self->_auth_lemonldap(@_) } );
    $self->cookiename( 'lemonldap' ) unless $self->cookiename;

    $self->SUPER::prepare_app( @_ );
}

sub call {
    my ($self, $env) = @_;

    $self->SUPER::call( $env );
}

sub _auth_lemonldap {
    my ($self, $user, $password, $env) = @_;

    my $xheader = $env->{'X_FORWARDED_FOR'};
    $xheader .= ", " if ($xheader);
    $xheader .= $env->{REMOTE_ADDR};

    my $soap_headers = HTTP::Headers->new( "X-Forwarded-For" => $xheader );

    my $soap = SOAP::Lite->proxy(
        $self->portal || '',
        default_headers => $soap_headers,
    )->uri('urn:Lemonldap::NG::Common::CGI::SOAPService');

    my $response = $soap->getCookies( $user, $password );
    my $cv;

    # Catch SOAP errors
    if ( $response->fault ) {
        return;
    }
    else {
        my $res = $response->result();

        # If authentication failed, display error
        if ( $res->{errorCode} ) {
            return;
        }

        $cv = $res->{cookies}->{ $self->cookiename };
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::LemonLDAP::BasicAuth - Middleware to provide LemonLDAP support for Plack applications

=head1 VERSION

version 0.02

=head1 DESCRIPTION

LemonLDAP is a great tool to implement Single-Sign-On for webapplications.
Unfortunately it doesn't support nginx yet, but is tied to Apache (as it
is implemented using mod_perl handlers).

This middleware is one way to add LemonLDAP support for applications that
supports HTTP BasicAuth for authentication.

=head1 Example

One application that supports HTTP BasicAuth for authentication is 
L<OTRS|http://otrs.org>. It has a basic PSGI support so that you can run
it with L<Starman>.

  starman -e 'enable "LemonLDAP::BasicAuth", portal => "http://auth.example.com"' app.psgi

If no user is logged in, 

=head1 AUTHOR

Renee Bäcker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Bäcker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
