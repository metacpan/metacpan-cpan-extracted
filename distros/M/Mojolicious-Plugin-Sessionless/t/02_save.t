use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;
use Test::Mojo;

use experimental qw(signatures);

plugin 'Sessionless';

get '/' => sub($c) {
  is($c->session('key'), undef, 'test that value was not persistently saved');
  $c->session(key => 'value');    # attempt to store a session value
  return $c->render(text => 'Hello, world');
};

my $t1 = Test::Mojo->new;
$t1->get_ok('/')->header_exists_not('Set-Cookie');

# Run it again to ensure that the value wasn't saved between requests
my $t2 = Test::Mojo->new;
$t2->get_ok('/')->header_exists_not('Set-Cookie');

done_testing;
