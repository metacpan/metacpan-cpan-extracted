use WWW::Telegram::BotAPI;
use Data::Dumper;

my $api = $api = WWW::Telegram::BotAPI->new (
    token => $ENV{CAMSHOTBOT_TELEGRAM_API_TOKEN}
);


warn Dumper $api->deleteWebhook();
