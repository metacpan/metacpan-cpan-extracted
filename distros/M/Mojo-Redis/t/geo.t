use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm Test::Deep' unless eval 'require Test::Deep;1';

Test::Deep->import;

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db    = $redis->db;
my $key   = "places:$0";
my $res;

$db->geoadd($key => 13.361389, 38.115556, 'Palermo', 15.087269, 37.502669, 'Catania');

is $db->geodist($key => qw(Palermo Catania)), 166274.1516, 'geodist';

is_deeply $db->georadius($key => qw(15 37 100 km)), ['Catania'], 'georadius 100km';
is_deeply $db->georadius($key => qw(15 37 200 km)), ['Palermo', 'Catania'], 'georadius 200km';

my $tol = 0.00001;
cmp_deeply(
  $db->geopos($key => qw(Catania NonExisting Palermo)),
  [
    {lat => num(37.502669, $tol), lng => num(15.087269, $tol)},
    undef,
    {lat => num(38.115556, $tol), lng => num(13.361389, $tol)},
  ],
  'geopos'
);

$db->del($key);

done_testing;
