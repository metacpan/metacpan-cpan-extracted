use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojolicious::Lite;

throws_ok
    { plugin ModeHelpers => { unknown_key => undef } }
    qr/Unknown config options provided: unknown_key/,
    'unkown config key throws';

throws_ok
    { plugin ModeHelpers => { unknown_key => undef, other_unknown_key => undef} }
    qr/Unknown config options provided: other_unknown_key, unknown_key/,
    'multiple unkown config keys throws';

lives_ok
    { plugin ModeHelpers => { prod_helper_name => 'prod', dev_helper_name => 'dev', modes => [] } }
    'known keys live';

done_testing;
