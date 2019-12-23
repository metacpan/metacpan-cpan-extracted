use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Exception;
use Mojo::Util ();
use Mojolicious::Lite;

lives_ok
    { plugin 'Host' }
    'no config lives';

lives_ok
    { plugin Host => {} }
    'empty hash config lives';

note 'Test helper';
throws_ok
    { plugin Host => { helper => [] } }
    qr/helper must be a string, but was 'ARRAY'/,
    'array helper throws';

throws_ok
    { plugin Host => { helper => {} } }
    qr/helper must be a string, but was 'HASH'/,
    'hash helper throws';

throws_ok
    { plugin Host => { helper => undef } }
    qr/helper must be non-empty/,
    'undef helper throws';

throws_ok
    { plugin Host => { helper => '' } }
    qr/helper must be non-empty/,
    'empty string helper throws';

lives_ok
    { plugin Host => { helper => 'my_host' } }
    'non-empty helper lives';


note 'Test www';
throws_ok
    { plugin Host => { www => [] } }
    qr/www must be a string, but was 'ARRAY'/,
    'array www throws';

throws_ok
    { plugin Host => { www => {} } }
    qr/www must be a string, but was 'HASH'/,
    'hash www throws';

throws_ok
    { plugin Host => { www => undef } }
    qr/www must be non-empty/,
    'undef www throws';

throws_ok
    { plugin Host => { www => '' } }
    qr/www must be non-empty/,
    'empty string www throws';

throws_ok
    { plugin Host => { www => 0 } }
    qr/www must be either 'always' or 'never', but was '0'/,
    '0 www throws';

throws_ok
    { plugin Host => { www => 1 } }
    qr/www must be either 'always' or 'never', but was '1'/,
    '1 www throws';

throws_ok
    { plugin Host => { www => 'always never' } }
    qr/www must be either 'always' or 'never', but was 'always never'/,
    'always never www throws';

lives_ok
    { plugin Host => { www => 'always' } }
    'always www lives';

lives_ok
    { plugin Host => { www => 'never' } }
    'never www lives';

note 'Test unknown options';
my $unknown_options = {
    unknown_key => 'unknown_value',
};
my $dump = Mojo::Util::dumper $unknown_options;
throws_ok
    { plugin Host => $unknown_options }
    qr#unknown keys/values: \Q$dump\E#,
    'unknown options with no helper and no www throws';

throws_ok
    { plugin Host => { helper => 'my_host', %$unknown_options } }
    qr#unknown keys/values: \Q$dump\E#,
    'unknown options with helper throws';

throws_ok
    { plugin Host => { www => 'always', %$unknown_options } }
    qr#unknown keys/values: \Q$dump\E#,
    'unknown options with www throws';

throws_ok
    { plugin Host => { helper => 'my_host', www => 'always', %$unknown_options } }
    qr#unknown keys/values: \Q$dump\E#,
    'unknown options with helper and www throws';

done_testing;
