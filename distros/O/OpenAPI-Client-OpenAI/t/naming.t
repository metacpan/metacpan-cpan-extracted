use strict;
use warnings;
use Test::Most;
use OpenAPI::Client::OpenAI::Naming qw(to_snake_case);

my @cases = (
    [ 'createChatCompletion'  => 'create_chat_completion' ],
    [ 'ListSkills'            => 'list_skills' ],
    [ 'refer-realtime-call'   => 'refer_realtime_call' ],
    [ 'usage_audio_speeches'  => 'usage_audio_speeches' ],
    [ 'admin-api-keys-list'   => 'admin_api_keys_list' ],
    [ 'APIKey'                => 'api_key' ],
    [ 'OAuth2Token'           => 'o_auth2_token' ],   # documents the chosen behavior for digit boundaries
    [ 'listModels'            => 'list_models' ],
);

for my $case (@cases) {
    my ( $in, $want ) = @$case;
    is to_snake_case($in), $want, "to_snake_case('$in')";
}

use OpenAPI::Client::OpenAI::Naming qw(detect_collisions);

is_deeply
    detect_collisions( [qw(createChatCompletion create_chat_completion)] ),
    { create_chat_completion => [qw(createChatCompletion create_chat_completion)] },
    'detects camel/snake colliding to same snake form';

is_deeply
    detect_collisions( [qw(listModels listSkills)] ),
    {},
    'no collision when snake forms differ';

done_testing;
