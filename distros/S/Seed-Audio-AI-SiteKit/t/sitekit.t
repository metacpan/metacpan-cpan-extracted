use strict;
use warnings;
use Test::More;
use lib 'lib';
use Seed::Audio::AI::SiteKit qw(site seed_audio_url);

is(site()->{name}, 'Seed Audio AI', 'name is available');
is(site()->{homepage}, 'https://seedaud.io/', 'homepage is available');
is(seed_audio_url(), 'https://seedaud.io/', 'home URL is normalized');
is(seed_audio_url('/pricing/'), 'https://seedaud.io/pricing/', 'path URL is normalized');

done_testing();
