use Mojo::Base -strict;
use Mojo::GoogleAnalytics;
use Test::More;

plan skip_all => 'TEST_GA_FILE is not set' unless $ENV{TEST_GA_FILE};

my $ga = Mojo::GoogleAnalytics->new($ENV{TEST_GA_FILE});
my $res;

for my $attr (qw(client_email client_id private_key)) {
  ok $ga->$attr, "$attr is set";
}

is $ga->authorize, $ga, 'authorize blocking';
is $ga->authorize, $ga, 'authorize blocking again';

is $ga->authorize(sub { Mojo::IOLoop->stop }), $ga, 'authorize non-blocking again';
Mojo::IOLoop->start;

$ga->authorization({});
is $ga->authorize(sub { Mojo::IOLoop->stop }), $ga, 'authorize non-blocking';
Mojo::IOLoop->start;

done_testing;
