package Plack::Middleware::Auth::BrowserID;

use 5.012;
use warnings;
use Carp 'croak';

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( realm audience );
use Plack::Response;
use Plack::Session;

use LWP::UserAgent;
use Mozilla::CA;
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

        my $ua = LWP::UserAgent->new(
            ssl_opts    => { verify_hostname => 1 },
            SSL_ca_file => Mozilla::CA::SSL_ca_file()
        );

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

#ABSTRACT: TODO fill this

__END__

==head1 SYNOPSIS

use Plack::Builder;

builder {
    enable 'Session', store => 'File';

    mount '/auth' => builder {
        enable 'Auth::BrowserID', audience => 'http://localhost:8082/';
    };
    mount '/'      => $app;
}

==cut
