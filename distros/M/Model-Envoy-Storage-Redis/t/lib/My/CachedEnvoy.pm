package My::CachedEnvoy;

use Moose;
use Redis::Fast;
use Test::SpawnRedisServer;

my ( $c, $srv ) = redis();
END{ $c->() if $c }

with 'Model::Envoy' => { storage => {
    Redis => {
        redis => sub {

            Redis::Fast->new(
                server    => $srv,
                reconnect => 60,
                every     => 500_000,
            );
        },
    },
} };

1;