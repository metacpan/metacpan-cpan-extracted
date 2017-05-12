use Test::More tests => 3;
use OAuth::Lite::Consumer;

my $consumer = OAuth::Lite::Consumer->new(
    consumer_key    => 'example.com',
    consumer_secret => 'secret secret'
);
ok($consumer, 'new');

my @pairs = (
    a => 1,
    c => 'hi there',
    f => 25,
    f => 50,
    f => 'a',
    z => 'p',
    z => 't',
);
my $without_params = 'http://example.net/path/to';
my $req = $consumer->gen_oauth_request(
    method => 'GET',
    url    => $without_params,
    params => \@pairs
);
is($req->method, 'GET');
is($req->url, "$without_params?a=1&c=hi%20there&f=25&f=50&f=a&z=p&z=t");
