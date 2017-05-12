use HTTP::Request::Common;
use Plack::Builder;
use Cache::Memory::Simple;
use Test::More;
use Test::TCP;
use Plack::Loader;
use Plack::LWPish;
use HTTP::CookieJar;
use JSON::WebToken qw/encode_jwt decode_jwt/;

my $cache = Cache::Memory::Simple->new;
my $app = builder {
    enable 'Session::Simple::JWSCookie',
        store => $cache,
        cookie_name => 'myapp_session',
        alg => 'HS256',
        secret => 'myapp_hmac_secret';

    mount '/' => sub {
        my $env = shift;
        my $body = 'TOP';
        if ( my $username = $env->{'psgix.session'}->{username} ) {
            $body = "TOP: Hello $username";
        }
        [200,[],[$body]];
    };
    mount '/counter' => sub {
        my $env = shift;
        $env->{'psgix.session'}->{counter}++;
        [200,[],["counter=>".$env->{'psgix.session'}->{counter}]];
    };
    mount '/login' => sub {
        my $env = shift;
        $env->{'psgix.session'}->{username} = "foo";
        [200,[],["LOGIN"]];
    };
    mount '/logout' => sub {
        my $env = shift;
        $env->{'psgix.session.options'}->{expire} = 1;
        [200,[],["LOGOUT"]];
    };
};

test_tcp(
    server => sub {
        my $port = shift;
        Plack::Loader->load('Standalone',port=>$port)->run($app);
        exit;
    },
    client => sub {
        my $port = shift;
        my $ua = Plack::LWPish->new(
            cookie_jar => HTTP::CookieJar->new
        );
        my $first_cookie;
        {
            my $res = $ua->request(GET "http://localhost:$port/");
            ok($res->content, "TOP");
            ok($res->header("Set-Cookie") =~ qr/myapp_session=(.+?);/);
            $first_cookie = $1;
            my $payload = decode_jwt($first_cookie, 'myapp_hmac_secret');
            ok($payload, q{cookie is jwt});
            ok($payload, q{cookie is jwt});
            ok($payload->{id}, q{cookie has sesion id});
            is($first_cookie, encode_jwt($payload, 'myapp_hmac_secret', 'HS256'), q{jwt signature});
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/login");
            is($res->content, "LOGIN");
            ok(!$res->header("Set-Cookie"));
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/");
            is($res->content, "TOP: Hello foo");
            ok(!$res->header("Set-Cookie"));
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/counter");
            is($res->content, "counter=>1");
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/counter");
            is($res->content, "counter=>2");
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/logout");
            is($res->content, "LOGOUT");
            ok($res->header("Set-Cookie") =~ qr/myapp_session=(.+?);/);
            is($1, $first_cookie);
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/");
            is($res->content, "TOP");
            ok($res->header("Set-Cookie") =~ qr/myapp_session=(.+?);/);
            isnt($1, $first_cookie);
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/counter");
            is($res->content, "counter=>1");
        }

    }
);

done_testing;

