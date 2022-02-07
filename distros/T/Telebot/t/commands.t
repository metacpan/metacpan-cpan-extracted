use Mojo::Base -strict;

use Test::More;

subtest 'bot' => sub {
  require Telebot::Command::bot;
  my $bot = Telebot::Command::bot->new;
  ok $bot->description, 'has a description';
  like $bot->message,   qr/bot/, 'has a message';
  like $bot->hint,      qr/help/,   'has a hint';
};

subtest 'generate' => sub {
  require Telebot::Command::bot::generate;
  my $generate = Telebot::Command::bot::generate->new;
  ok $generate->description, 'has a description';
  like $generate->usage, qr/generate/, 'has usage information';
};

done_testing();
