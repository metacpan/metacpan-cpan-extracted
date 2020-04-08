use Mojo::Base -strict;

use Test::More;
use Test::Memory::Cycle;

require_ok( 'Mojo::WebService::LastFM');

my $lastfm = Mojo::WebService::LastFM->new('api_key' => 'api_key');


memory_cycle_ok($lastfm, "No Memory Cycles");
weakened_memory_cycle_ok($lastfm, "No Weakened Memory Cycles");

# Should do more here - connect the $discord object to a Mojolicious::Lite app, do stuff with it, and then check it again.

done_testing();
