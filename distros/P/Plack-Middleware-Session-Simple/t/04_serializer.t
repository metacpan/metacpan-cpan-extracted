use HTTP::Request::Common;
use Plack::Builder;
use Cache::Memory::Simple;
use Test::More;
use Test::TCP;
use Plack::Loader;
use Plack::LWPish;
use HTTP::CookieJar;
use Test::Requires qw/JSON/;


my $cache = Cache::Memory::Simple->new;
my $JSON = JSON->new->utf8;

my $app = builder {
    enable 'Session::Simple',
        store => $cache,
        serializer => [ sub { $JSON->encode($_[0]) }, sub { $JSON->decode($_[0]) } ],
        cookie_name => 'myapp_session';
    mount '/' => sub {
        my $env = shift;
        my $body = 'TOP';
        if ( my $username = $env->{'psgix.session'}->{username} ) {
            $body = "TOP: Hello $username";
        }
        [200,[],[$body]];
    };
    mount '/login' => sub {
        my $env = shift;
        $env->{'psgix.session'}->{username} = "foo";
        [200,[],["LOGIN"]];
    };
    mount '/json' => sub {
        my $env = shift;
        my $json = $cache->get($env->{'psgix.session.options'}->{id});
        my $ref = $JSON->decode($json);
        my $name = $ref->{username};
        [200,[],["JSON $name,$json"]];
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
        {
            my $res = $ua->request(GET "http://localhost:$port/login");
            is($res->content, "LOGIN");
        }
        {
            my $res = $ua->request(GET "http://localhost:$port/");
            is($res->content, "TOP: Hello foo");
        }
        {
            my $res = $ua->request(GET "http://localhost:$port/json");
            is($res->content, q!JSON foo,{"username":"foo"}!);
        }
    }
);

done_testing;

