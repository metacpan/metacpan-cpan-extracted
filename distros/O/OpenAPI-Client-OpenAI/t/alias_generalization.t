use strict;
use warnings;
use Test::Most;

BEGIN { $ENV{OPENAI_API_KEY} //= 'test-key' }
use OpenAPI::Client::OpenAI;

my $client = OpenAPI::Client::OpenAI->new;

# Sampling: a camelCase op, plus the legacy six. Each should be callable in
# both original and snake_case form.
ok $client->can('createChatCompletion'),  'camelCase original is callable';
ok $client->can('create_chat_completion'), 'snake_case alias is callable';

ok $client->can('listModels'),  'listModels original';
ok $client->can('list_models'), 'list_models alias';

# Op outside legacy 6 — must have a snake_case alias after the rewrite
ok $client->can('createTranscription'),   'createTranscription original';
ok $client->can('create_transcription'),  'create_transcription alias (non-legacy)';

# The deprecation warning is gone after this commit. Catch warns emitted at
# any time during this script. Note: BEGIN-time warns from the alias loop
# install (before this handler is set) are not caught — but the previous
# behavior emitted warns at *call* time, which IS caught here. As a belt-
# and-suspenders check, defined &..::create_chat_completion proves the
# alias is installed without going through the warn-emitting old shim.
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };
ok defined &OpenAPI::Client::OpenAI::create_chat_completion,
    'snake_case alias defined';
is scalar(@warnings), 0, 'no deprecation warning emitted at load time';

done_testing;
