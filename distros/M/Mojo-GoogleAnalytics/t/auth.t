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
test_authorization('blocking');

is $ga->authorize(sub { Mojo::IOLoop->stop }), $ga, 'authorize non-blocking again';
Mojo::IOLoop->start;

$ga->authorization({});
is $ga->authorize(sub { Mojo::IOLoop->stop }), $ga, 'authorize non-blocking';
Mojo::IOLoop->start;
test_authorization('non-blocking');

$ga->authorization({});
my $p = $ga->authorize_p;
isa_ok($p, 'Mojo::Promise');
$p->wait;
test_authorization('promise');

done_testing;

sub test_authorization {
  like $ga->authorization->{header}, qr{Bearer}, "$_[0] got bearer token";
  like $ga->authorization->{exp},    qr{\w+},    "$_[0] got exp date";
}
