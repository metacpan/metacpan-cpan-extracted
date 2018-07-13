use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db    = $redis->db;
my $key   = "$0:pipelining";
my @res;

Mojo::Promise->all(
  $db->set_p($key, 10), $db->incrby_p($key, 9), $db->incr_p($key), $db->get_p($key),
  $db->incr_p($key), $db->get_p($key),
)->then(sub {
  @res = map {@$_} @_;
})->wait;

is_deeply \@res, ['OK', 19, 20, 20, 21, 21], 'Not waiting for response before sending a command';

done_testing;
