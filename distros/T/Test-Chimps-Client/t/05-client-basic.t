#!perl -T

use Test::More tests => 6;

use Test::TAP::Model::Visual;

BEGIN {
  use_ok( 'Test::Chimps::Client' );
}

my $m = Test::TAP::Model::Visual->new_with_tests('t-data/bogus-tests/00-basic.t');

my $c = Test::Chimps::Client->new(model => $m,
                                  server => 'bogus',
                                  compress => 1);

ok($c, "the client object is defined");
isa_ok($c, 'Test::Chimps::Client', "and it's of the correct type");

is($c->model, $m, "the reports accessor works");
is($c->server, "bogus", "the server accessor works");
is($c->compress, 1, "the compress accessor works");
