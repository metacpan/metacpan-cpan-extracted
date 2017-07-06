# simple web server working on polling method that sends photo from location in reply on /abc message

# Run it with
# prove -l -v xt
# or
# perl -Ilib xt/telegram.t

# export CAMSHOTBOT_TELEGRAM_API_TOKEN=

# If you see
# ERROR: code 409: Conflict: can't use getUpdates method while webhook is active
# please run
# perl -Ilib xt/remove_webhook.t

use Telegram::Bot::Message;
use WWW::Telegram::BotAPI;

my $cmd = '/abc';
my $screenshot_file = 'xt/Screenshot.png';
my $api = $api = WWW::Telegram::BotAPI->new (
    token => $ENV{CAMSHOTBOT_TELEGRAM_API_TOKEN}
);

while (1) {
  my @updates = @{$api->getUpdates->{result}};
  if (@updates) {
    print "Got update!\n";
    for my $update (@updates) {
      my $mo = Telegram::Bot::Message->create_from_hash($update->{message});
      if ($mo->text eq $cmd) {
        $api->sendPhoto ({
    		    chat_id => $mo->chat->id,
    		    photo   => {
    		        file => $screenshot_file
    		    },
    		    caption => "screenshot_file",
    		    reply_to_message_id => $mo->message_id
    		})
      }
      $api->getUpdates({ offset => $update->{update_id} + 1.0 })->{result};   # clear buffer
    }
    print "Replied to all updates!\n";
  }
}
