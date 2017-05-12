package TestPR;

use strict;
use warnings;

use overload
    q(&{})   => sub { shift->psgi_app },
    fallback => 1;

use Plack::Request;
use Try::Tiny;
use Params::Validate;
use TestDataHandler;
use JSON::XS qw/decode_json encode_json/;

use Plack::Middleware::Auth::OIDC::ProtectedResource;

sub new {
    my $class = shift;
    bless { }, $class;
}

sub psgi_app {
    my $self = shift;
    return $self->{psgi_app}
        ||= $self->compile_psgi_app;
}

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
        realm        => 'resource.example.org',
        data_handler => 'TestDataHandler',
    );
}

sub handle_request {
    my ($self, $request) = @_;

    my $scope = ($request->env->{X_OAUTH_SCOPE}) ? $request->env->{X_OAUTH_SCOPE} : q{};
    my $claims = ($request->env->{X_OIDC_USERINFO_CLAIMS}) ? encode_json($request->env->{X_OIDC_USERINFO_CLAIMS}) : "[]";

    return $request->new_response(200,
        ["Content-Type" => "application/json"],
        [ sprintf("{user: '%s', scope: '%s', claims: %s, is_legacy: '%d'}",
            $request->env->{REMOTE_USER},
            $scope,
            $claims,
            $request->env->{X_OAUTH_IS_LEGACY})]
    );
}

1;
