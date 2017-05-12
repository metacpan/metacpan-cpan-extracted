use HTTP::Request::Common;
use Plack::Builder;
use Cache::Memory::Simple;
use Test::More;
use Test::TCP;
use Plack::Loader;
use Plack::LWPish;
use HTTP::CookieJar;
use Test::Requires qw/Plack::Middleware::Session Plack::Session::Store::Cache Plack::Session::State::Cookie/;

my $cache = Cache::Memory::Simple->new;
my $app = builder {
    mount '/simple' => builder {
        enable 'Session::Simple',
            store => $cache,
            cookie_name => 'myapp_session';
        sub {
            $env->{'psgix.session'}->{counter}++;
            [200,[],["counter=>".$env->{'psgix.session'}->{counter}]];
        };
    };
    mount '/session' => builder {
        enable 'Session',
            store => Plack::Session::Store::Cache->new(
                cache => $cache,
            ),
            state => Plack::Session::State::Cookie->new(
                session_key => 'myapp_session'
            );
        sub {
            $env->{'psgix.session'}->{counter}++;
            [200,[],["counter=>".$env->{'psgix.session'}->{counter}]];
        };
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
            my $res = $ua->request(GET "http://localhost:$port/simple");
            is($res->content, "counter=>1");
            ok($res->header("Set-Cookie") =~ qr/myapp_session=([a-f0-9]{40});/);
            $first_cookie = $1;
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/simple");
            is($res->content, "counter=>2");
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/session");
            is($res->content, "counter=>3");
        }

        {
            my $res = $ua->request(GET "http://localhost:$port/simple");
            is($res->content, "counter=>4");
        }

    }
);

done_testing;

