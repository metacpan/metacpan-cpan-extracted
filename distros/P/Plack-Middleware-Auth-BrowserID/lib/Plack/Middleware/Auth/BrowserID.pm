package Plack::Middleware::Auth::BrowserID;

BEGIN {
    $Plack::Middleware::Auth::BrowserID::AUTHORITY = 'cpan:BOLILA';
}
use strict;
use warnings;

use Carp 'croak';

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( audience );
use Plack::Response;
use Plack::Session;

use LWP::Protocol::https;
use LWP::UserAgent;
use JSON;


sub prepare_app {
    my $self = shift;

    $self->audience or croak 'audience is not set';
}

sub call {
    my ( $self, $env ) = @_;

    my $req     = Plack::Request->new($env);
    my $session = Plack::Session->new($env);

    if ( $req->method eq 'POST' ) {
        my $uri  = 'https://verifier.login.persona.org/verify';
        my $json = {
            assertion => $req->body_parameters->{'assertion'},
            audience  => $self->audience
        };
        my $persona_req = HTTP::Request->new( 'POST', $uri );
        $persona_req->header( 'Content-Type' => 'application/json' );
        $persona_req->content( to_json( $json, { utf8 => 1 } ) );

        my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 1 } );

        my $res      = $ua->request($persona_req);
        my $res_data = from_json( $res->decoded_content );

        if ( $res_data->{'status'} eq 'okay' ) {
            $session->set( 'email', $res_data->{'email'} );
            return [
                200, [ 'Content-type' => 'text' ],
                [ 'welcome! ' . $res_data->{'email'} ]
            ];
        }
        else {
            return [
                500, [ 'Content-type' => 'text' ],
                ['nok']
            ];
        }

    }

    # Logout
    $session->remove('email');

    my $res = Plack::Response->new;
    $res->cookies->{email} = { value => undef, path => '/' };
    $res->redirect('/');
    return $res->finalize;
}

1;

#ABSTRACT: Plack Middleware to integrate with Mozilla Persona (Auth by email)

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Auth::BrowserID - Plack Middleware to integrate with Mozilla Persona (Auth by email)

=head1 VERSION

version 0.0.7

=head1 SYNOPSIS

    #.. on PSGI file

    use Plack::Builder;
    use Plack::Session;

    ##..

    builder {
        enable 'Session', store => 'File';

        mount '/auth' => builder {
            enable 'Auth::BrowserID', audience => 'http://localhost:8082/';
        };

        mount '/'     => $app;
    };

=head1 DESCRIPTION

Mozilla Persona is a secure solutions, to identify users based on email address.

"Simple, privacy-sensitive single sign-in: let your users sign into your website with their email address, and free yourself from password management."

Some Javascript code is needed in the client side. First include the dependencies:

    <script src="//cdnjs.cloudflare.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/jquery-cookie/1.3.1/jquery.cookie.min.js"></script>
    <script src="https://login.persona.org/include.js"></script>"

Setup the watch with email and url's for login and logout (as defined in the PSGI "mount '/auth'"):

    email = $.cookie('email') || null;

    navigator.id.watch({
      loggedInUser: email,
      onlogin: function(assertion) {
        return $.post('/auth/signin', {
          assertion: assertion
        }, function(data) {
          return window.location.reload();
        });
      },
      onlogout: function() {
        return window.location = '/auth/signout';
      }
    });

And map the events in the DOM with the watch from Mozilla:

    var signinLink = document.getElementById('signin');
    if (signinLink) {
      signinLink.onclick = function() { navigator.id.request(); };
    }

    var signoutLink = document.getElementById('signout');
    if (signoutLink) {
      signoutLink.onclick = function() { navigator.id.logout(); };
    }

Please look for the example and read the L<Mozilla Persona|https://developer.mozilla.org/en-US/Persona> info on MDN.

In the web application get the L<Plack::Session> (example):

    use Dancer2;
    use Plack::Session;

    get '/' => sub {
        my $session = Plack::Session->new( shift->env );
        'Hi! do you wanna dance? ' . $session->get('email');
    };

See the functional example on the examples folder.

  plackup -s Starman -r -p 8082 -E development -I lib example/app.psgi

=head1 SEE ALSO

L<Plack::Middleware::Session>
L<LWP::Protocol::https>
L<Net::BrowserID::Verify>

=head1 AUTHOR

João Bolila <bolila@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by J. Bolila.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
