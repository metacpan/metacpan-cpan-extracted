#!/bin/env perl

use strict;
use warnings;

use Plack::Request;
use Plack::Response;
use Plack::Builder;

use FindBin;
use lib "$FindBin::Bin/../lib";
use OAuth2::Google::Plus;
use OAuth2::Google::Plus::UserInfo;

sub google_plus {
    my $plus = OAuth2::Google::Plus->new(
        client_id     => $ENV{client_id},
        client_secret => $ENV{client_secret},
        redirect_uri  => 'http://localhost:5000/',
    );

    return $plus;
}

{
    my $app = sub {
        my $env     = shift;
        my $session = $env->{'psgix.session'};
        my $request = Plack::Request->new($env);
        my $response = do_app( $request, $session );

        return $response->finalize;
    };

    builder {
        enable 'Session';
        $app;
    };
}

sub do_app {
    my ( $request, $session ) = @_;

    if( $session->{access_token} ) {
        my $info = OAuth2::Google::Plus::UserInfo->new( access_token => $session->{access_token} );
        my $hello = sprintf('<p>Hello %s, your google id = %s, did you verifiy your email? %s.', $info->email, $info->id, $info->verified_email );

        return plack_response(sprintf(HTML(), $hello));
    }

    if ( my $code = $request->param('code') ) {
        my $plus = google_plus();

        $session->{access_token} = $plus->authorize( authorization_code => $code );

        return plack_redirect('/');
    }

    my $html = sprintf('<a href="%s"><img src="https://developers.google.com/+/images/branding/sign-in-buttons/Red-signin_Medium_base_44dp.png" />login here...</a>', google_plus()->authorization_uri );

    return plack_response(sprintf(HTML(), $html));
}

sub plack_response {
    my ( $content ) = @_;

    my $res = Plack::Response->new();
    $res->status( 200 );
    $res->body( $content );

    return $res;
}

sub plack_redirect {
    my ( $url ) = @_;

    my $res = Plack::Response->new();
    $res->redirect( $url );

    return $res;
}


sub HTML {
return <<"HTML";
<html>
    <head><title>Really simple demo</title></head>
    <body>
        <p>This is a really simple demo to show off OAuth2::Google::Plus.</p>
        <p>It allows you to login, and store the access token in a cookie</p>
        <hr/>
        <div>
        %s
        </div>
    </body>
</html>
HTML

}
