#!perl -T

use Test::More tests => 12;
use Test::Exception;

use Plack::App::PubSubHubbub::Subscriber::Config;

my $class = 'Plack::App::PubSubHubbub::Subscriber::Config';

note 'bad config';

throws_ok { $class->new() } qr/required/;

throws_ok { $class->new(
    callback => 'https://localhost',
) } qr/support only http/;

throws_ok { $class->new(
    callback => 'http://localhost/callback#fragment',
) } qr/fragment/;

throws_ok { $class->new(
    callback => 'http://localhost/callback',
    verify => 'not_supported',
) } qr/verify/;

throws_ok { $class->new(
    callback => 'http://localhost/callback',
    verify => 'sync',
    lease_seconds => -1,
) } qr/number/;

note 'good config';

my $conf;

lives_ok { $conf = $class->new(
    callback => 'http://localhost/callback',
) };

isa_ok $conf, 'Plack::App::PubSubHubbub::Subscriber::Config';
is $conf->callback, 'http://localhost/callback', 'same callaback';
is $conf->verify, 'sync', 'default is sync';
ok ! defined $conf->lease_seconds, 'lease_seconds is undef';
ok $conf->token_in_path, 'default is true';

lives_ok { $class->new(
    callback => 'http://localhost/callback',
    verify => 'async',
    lease_seconds => 86400,
) };

