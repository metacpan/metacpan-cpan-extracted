package TestPR2;

use strict;
use warnings;

use parent 'TestPR';

sub compile_psgi_app {
    my $self = shift;
    my $app = sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $res; try {
            $res = $self->handle_request($req);
        } catch {
            $res = $req->new_response(500);
        };
        return $res->finalize;
    };
    return Plack::Middleware::Auth::OIDC::ProtectedResource->wrap($app,
        error_uri        => 'http://resource.example.org/error',
        data_handler => 'TestDataHandler',
    );
}

1;
