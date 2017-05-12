use Mojolicious::Lite;

plugin 'Memorize';

any '/manual/:value'   => 'manual';
any '/duration/:value' => 'duration';
any '/expires/:value'  => 'expires';

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

subtest 'first render' => sub {
  $t->get_ok('/manual/first')
    ->text_is('#cached' => 'first')
    ->text_is('#normal' => 'first');

  $t->get_ok('/duration/first')
    ->text_is('#cached' => 'first')
    ->text_is('#normal' => 'first');

  $t->get_ok('/expires/first')
    ->text_is('#cached' => 'first')
    ->text_is('#normal' => 'first');
};

subtest 'second render' => sub {
  $t->get_ok('/manual/second')
    ->text_is('#cached' => 'first')
    ->text_is('#normal' => 'second');

  $t->get_ok('/duration/second')
    ->text_is('#cached' => 'first')
    ->text_is('#normal' => 'second');

  $t->get_ok('/expires/second')
    ->text_is('#cached' => 'first')
    ->text_is('#normal' => 'second');
};

sleep 2;

subtest 'third render (delayed)' => sub {
  $t->get_ok('/manual/third')
    ->text_is('#cached' => 'first')
    ->text_is('#normal' => 'third');

  $t->get_ok('/duration/third')
    ->text_is('#cached' => 'third')
    ->text_is('#normal' => 'third');

  $t->get_ok('/expires/third')
    ->text_is('#cached' => 'third')
    ->text_is('#normal' => 'third');
};

subtest 'fourth render (manual)' => sub {
  $t->app->memorize->expire('manual');

  $t->get_ok('/manual/fourth')
    ->text_is('#cached' => 'fourth')
    ->text_is('#normal' => 'fourth');

  $t->get_ok('/duration/fourth')
    ->text_is('#cached' => 'third')
    ->text_is('#normal' => 'fourth');

  $t->get_ok('/expires/fourth')
    ->text_is('#cached' => 'third')
    ->text_is('#normal' => 'fourth');
};


done_testing;

__DATA__

@@ manual.html.ep

%= memorize manual => begin
  %= tag div => id => cached => $value
% end

%= tag div => id => normal => $value

@@ duration.html.ep

%= memorize { duration => 1 } => begin
  %= tag div => id => cached => $value
% end

%= tag div => id => normal => $value

@@ expires.html.ep

%= memorize { expires => time + 1 } => begin
  %= tag div => id => cached => $value
% end

%= tag div => id => normal => $value

