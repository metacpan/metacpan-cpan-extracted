package My::Envoy;

use Moose;
use MockRedis;

with 'Model::Envoy' => { storage => {
    'Redis' => {
        redis => sub {
            return MockRedis->new();
        },
    },
} };

1;