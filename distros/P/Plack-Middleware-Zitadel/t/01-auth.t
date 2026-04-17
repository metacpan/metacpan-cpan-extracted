use strict;
use warnings;

use FindBin;
BEGIN {
    my $path = "$FindBin::Bin/../../p5-www-zitadel/lib";
    require lib if -d $path;
    lib->import($path) if -d $path;
}

use Test::More;
use JSON::MaybeXS qw(decode_json encode_json);
use HTTP::Request::Common qw(GET);
use Plack::Builder;
use Plack::Test;

use Plack::Middleware::Zitadel;

{
    package Local::OIDC;

    sub new {
        my ($class, %args) = @_;
        bless { %args, calls => [] }, $class;
    }

    sub verify_token {
        my ($self, $token, %args) = @_;
        push @{ $self->{calls} }, { token => $token, args => { %args } };

        die "bad token\n" if $token eq 'bad';
        die "   leading and trailing space   \n\n"
            if $token eq 'whitespace-error';

        my $scopes = $token eq 'scoped' ? 'openid profile email'
                   : $token eq 'multi'  ? 'openid profile'
                   : 'openid';

        return {
            sub   => 'user-1',
            scope => $scopes,
            token => $token,
            %args,
        };
    }
}

my $echo_app = sub {
    my ($env) = @_;
    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        [ encode_json({
            default_claims => $env->{'zitadel.claims'},
            custom_claims  => $env->{'custom.claims'},
            token          => $env->{'zitadel.token'},
        }) ],
    ];
};

subtest 'prepare_app validates config' => sub {
    eval {
        my $mw = Plack::Middleware::Zitadel->new;
        $mw->prepare_app;
    };
    like $@, qr/issuer required/, 'issuer required when no oidc given';

    {
        package Local::NoVerify;
        sub new { bless {}, shift }
    }

    eval {
        my $mw = Plack::Middleware::Zitadel->new(
            oidc => Local::NoVerify->new,
        );
        $mw->prepare_app;
    };
    like $@, qr/verify_token/, 'oidc must implement verify_token';
};

subtest 'extract bearer token' => sub {
    my $oidc = Local::OIDC->new;
    my $app = builder {
        enable 'Plack::Middleware::Zitadel', oidc => $oidc;
        $echo_app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;

        my $no_auth = $cb->(GET 'http://localhost/');
        is $no_auth->code, 401, 'missing header -> 401';
        like $no_auth->header('WWW-Authenticate'),
            qr/error="invalid_request"/,
            'missing header surfaces invalid_request';
        like $no_auth->header('WWW-Authenticate'),
            qr/error_description="missing Authorization header"/,
            'description explains the reason';

        my $basic = GET 'http://localhost/';
        $basic->header(Authorization => 'Basic foo');
        my $basic_res = $cb->($basic);
        is $basic_res->code, 401, 'non-Bearer scheme -> 401';
        like $basic_res->header('WWW-Authenticate'),
            qr/Authorization must use Bearer token/,
            'non-Bearer description surfaced';

        for my $scheme ('Bearer', 'bearer', 'BEARER', 'BeArEr') {
            my $req = GET 'http://localhost/';
            $req->header(Authorization => "$scheme good");
            my $res = $cb->($req);
            is $res->code, 200,
                "scheme '$scheme' accepted (case-insensitive)";
        }
    };
};

subtest 'verify_token failure surfaces description' => sub {
    my $oidc = Local::OIDC->new;
    my $app = builder {
        enable 'Plack::Middleware::Zitadel', oidc => $oidc;
        $echo_app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;

        my $bad = GET 'http://localhost/';
        $bad->header(Authorization => 'Bearer bad');
        my $res = $cb->($bad);
        is $res->code, 401, 'bad token -> 401';
        like $res->header('WWW-Authenticate'),
            qr/error="invalid_token"/,
            'invalid_token code on verify failure';
        my $data = decode_json($res->decoded_content);
        is $data->{error}, 'invalid_token', 'JSON body has error';
        is $data->{error_description}, 'bad token',
            'description matches die message';

        my $ws = GET 'http://localhost/';
        $ws->header(Authorization => 'Bearer whitespace-error');
        my $ws_data = decode_json($cb->($ws)->decoded_content);
        is $ws_data->{error_description},
            '   leading and trailing space',
            'trailing whitespace stripped from die message';
    };
};

subtest 'audience handling' => sub {
    my $oidc_with = Local::OIDC->new;
    my $app_with = builder {
        enable 'Plack::Middleware::Zitadel',
            oidc     => $oidc_with,
            audience => 'my-api';
        $echo_app;
    };

    test_psgi $app_with, sub {
        my ($cb) = @_;
        my $req = GET 'http://localhost/';
        $req->header(Authorization => 'Bearer good');
        my $res = $cb->($req);
        is $res->code, 200, 'ok with audience';
        is $oidc_with->{calls}[-1]{args}{audience}, 'my-api',
            'audience passed to verify_token';
    };

    my $oidc_without = Local::OIDC->new;
    my $app_without = builder {
        enable 'Plack::Middleware::Zitadel', oidc => $oidc_without;
        $echo_app;
    };

    test_psgi $app_without, sub {
        my ($cb) = @_;
        my $req = GET 'http://localhost/';
        $req->header(Authorization => 'Bearer good');
        is $cb->($req)->code, 200, 'ok without audience';
        ok !exists $oidc_without->{calls}[-1]{args}{audience},
            'no audience arg when not configured';
    };

    my $oidc_empty = Local::OIDC->new;
    my $app_empty = builder {
        enable 'Plack::Middleware::Zitadel',
            oidc     => $oidc_empty,
            audience => '';
        $echo_app;
    };

    test_psgi $app_empty, sub {
        my ($cb) = @_;
        my $req = GET 'http://localhost/';
        $req->header(Authorization => 'Bearer good');
        is $cb->($req)->code, 200, 'ok with empty audience';
        ok !exists $oidc_empty->{calls}[-1]{args}{audience},
            'empty-string audience is not passed through';
    };
};

subtest 'required_scopes as arrayref' => sub {
    my $oidc = Local::OIDC->new;
    my $app = builder {
        enable 'Plack::Middleware::Zitadel',
            oidc            => $oidc,
            required_scopes => ['openid', 'email'];
        $echo_app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;

        my $missing = GET 'http://localhost/';
        $missing->header(Authorization => 'Bearer good');
        my $missing_res = $cb->($missing);
        is $missing_res->code, 403, 'missing one of required scopes -> 403';
        my $data = decode_json($missing_res->decoded_content);
        is $data->{error}, 'insufficient_scope',
            'body contains insufficient_scope';
        is $data->{error_description}, 'required scopes are missing',
            'description surfaces';
        ok !$missing_res->header('WWW-Authenticate'),
            '403 response does not include WWW-Authenticate';

        my $scoped = GET 'http://localhost/';
        $scoped->header(Authorization => 'Bearer scoped');
        is $cb->($scoped)->code, 200, 'all required scopes present -> 200';
    };
};

subtest 'required_scopes as space-separated string' => sub {
    my $oidc = Local::OIDC->new;
    my $app = builder {
        enable 'Plack::Middleware::Zitadel',
            oidc            => $oidc,
            required_scopes => 'openid profile';
        $echo_app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;

        my $missing = GET 'http://localhost/';
        $missing->header(Authorization => 'Bearer good');
        is $cb->($missing)->code, 403,
            'string-form: missing one scope -> 403';

        my $multi = GET 'http://localhost/';
        $multi->header(Authorization => 'Bearer multi');
        is $cb->($multi)->code, 200,
            'string-form: all scopes present -> 200';
    };
};

subtest 'env injection: claims and token' => sub {
    my $oidc = Local::OIDC->new;
    my $app = builder {
        enable 'Plack::Middleware::Zitadel', oidc => $oidc;
        $echo_app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;
        my $req = GET 'http://localhost/';
        $req->header(Authorization => 'Bearer good');
        my $res = $cb->($req);
        is $res->code, 200, 'default env key works';
        my $data = decode_json($res->decoded_content);
        is $data->{default_claims}{sub}, 'user-1',
            'claims populated under zitadel.claims';
        is $data->{token}, 'good',
            'zitadel.token env var contains raw token';
    };
};

subtest 'custom claims_env_key and realm' => sub {
    my $oidc = Local::OIDC->new;
    my $app = builder {
        enable 'Plack::Middleware::Zitadel',
            oidc           => $oidc,
            claims_env_key => 'custom.claims',
            realm          => 'admin';
        $echo_app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;

        my $req = GET 'http://localhost/';
        $req->header(Authorization => 'Bearer good');
        my $data = decode_json($cb->($req)->decoded_content);
        is $data->{custom_claims}{sub}, 'user-1',
            'claims stored under custom env key';
        is $data->{default_claims}, undef,
            'zitadel.claims not populated when custom key configured';

        my $no_auth = $cb->(GET 'http://localhost/');
        like $no_auth->header('WWW-Authenticate'),
            qr/realm="admin"/,
            'custom realm surfaces in header';
    };
};

subtest 'WWW-Authenticate header format' => sub {
    my $oidc = Local::OIDC->new;
    my $app = builder {
        enable 'Plack::Middleware::Zitadel', oidc => $oidc;
        $echo_app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;
        my $res = $cb->(GET 'http://localhost/');
        my $header = $res->header('WWW-Authenticate');
        like $header,
            qr/^Bearer realm="api", error="invalid_request", error_description="missing Authorization header"$/,
            'full RFC 6750 challenge format with defaults';
    };
};

done_testing;
