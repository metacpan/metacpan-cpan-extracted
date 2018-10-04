use Mojo::Base -strict;
use Test::More;
use Mojo::UserAgent;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $url = 'https://mojolicious.org';
my $tx;

my $ua = Mojo::UserAgent->with_roles('+Cache')->new(cache_strategy => sub { $tx = shift; 'passthrough' });
my $driver = $ua->cache_driver;

my $error = $ua->get($url)->error;
is $tx->req->url, 'https://mojolicious.org', 'tx passed to cache_strategy';
ok !$error, 'get' or diag $error->{message};
ok !$driver->get($url), 'nothing was cached';

$error = 'Not waited for';
$ua->get_p($url)->then(sub { $error = '' }, sub { $error = shift })->wait;
ok !$error, 'get_p' or diag $error;

done_testing;
