use Mojo::Base -strict;
use Data::Dumper;
use Test::More;
use Test::Mojo;

use Mojo::File qw(curfile);
use lib curfile->sibling('lib')->to_string;

plan skip_all => 'set TEST_TELEBOT_TOKEN to enable this test' if !$ENV{TEST_TELEBOT_TOKEN};

subtest 'Telegram application' => sub {
    my $app = Test::Mojo->new('TestBot')->app;
    isa_ok $app, 'Telebot', 'right class';
    my ($bot_id) = ($app->tg->config->{token} =~ /^(\d+):/);
    my $response = $app->tg->request(getMe => {});
    is($response->{ok}, 1, 'error during request to Telegram: ' . ($response->{description}//''));
    is(ref $response->{result}, 'HASH', 'response have not result');
    is($response->{result}{id}, $bot_id, 'id from token not equal to getMe result');
};

done_testing();
