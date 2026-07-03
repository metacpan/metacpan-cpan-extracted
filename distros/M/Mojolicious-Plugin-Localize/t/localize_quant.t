#!usr/bin/env perl
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Data::Dumper;

my $t = Test::Mojo->new;
my $app = $t->app;

plugin 'Localize';

is($app->quant(1, 'is', 'are', 'are'), 'is', 'Simple sg');
is($app->quant(0, 'is', 'are', 'are'), 'are', 'Simple null');
is($app->quant(5, 'is', 'are', 'are'), 'are', 'Simple pl');

my $ex = {
  1 => 'eins',
  2 => 'zwei',
  '4..6' => 'vier bis sechs', '>9' => 'größer als neun', '<4' => 'kleiner als vier'};
is($app->quant(1, 'eins', $ex ), 'eins', 'Eins');
is($app->quant(2, 'eins', $ex ), 'zwei', 'Zwei');
is($app->quant(3, 'eins', $ex ), 'kleiner als vier', 'Kleiner als vier');
is($app->quant(4, 'eins', $ex ), 'vier bis sechs', 'Vier bis Sechs');
is($app->quant(5, 'eins', $ex ), 'vier bis sechs', 'Vier bis Sechs');
is($app->quant(6, 'eins', $ex ), 'vier bis sechs', 'Vier bis Sechs');
is($app->quant(9, 'eins', $ex ), 'eins', 'Eins');
is($app->quant(10, 'eins', $ex ), 'größer als neun', 'Groesser als neun');

$ex = { 1 => 'eins', 2 => 'zwei', ' 4 .. 6 ' => 'vier bis sechs', ' >  9' => 'größer als neun', ' <  4' => 'kleiner als vier'};
is($app->quant(1, 'eins', $ex ), 'eins', 'Eins');
is($app->quant(2, 'eins', $ex ), 'zwei', 'Zwei');
is($app->quant(3, 'eins', $ex ), 'kleiner als vier', 'Kleiner als vier');
is($app->quant(4, 'eins', $ex ), 'vier bis sechs', 'Vier bis Sechs');
is($app->quant(5, 'eins', $ex ), 'vier bis sechs', 'Vier bis Sechs');
is($app->quant(6, 'eins', $ex ), 'vier bis sechs', 'Vier bis Sechs');
is($app->quant(9, 'eins', $ex ), 'eins', 'Eins');
is($app->quant(10, 'eins', $ex ), 'größer als neun', 'Groesser als neun');

$ex = {
  even => 'gerade',
  odd => 'ungerade',
  3 => 'drei',
  '>50' => 'größer 50'
};
is($app->quant(1, 'eins', $ex ), 'ungerade', 'Ungerade');
is($app->quant(2, 'eins', $ex ), 'gerade', 'Gerade');
is($app->quant(3, 'eins', $ex ), 'drei', 'Drei');
is($app->quant(4, 'eins', $ex ), 'gerade', 'Gerade');
is($app->quant(49, 'eins', $ex ), 'ungerade', 'Ungerade');
is($app->quant(50, 'eins', $ex ), 'gerade', 'Gerade');
is($app->quant(51, 'eins', $ex ), 'größer 50', 'Greater 50');
is($app->quant(0, 'eins', $ex ), 'gerade', '0 is even');
is($app->quant(-33, 'eins', $ex ), 'ungerade', '0 is even');

plugin 'Localize' => {
  dict => {
    welcome => {
      en => q!There ! .
	    q!<%= quant(stash('matches'), 'is', 'are', 'are') %> ! .
            q!<%= stash('matches') %> ! .
	    q!<%= quant(stash('matches'), 'match', 'matches', 'matches') %>.!
    }
  }
};

$app->defaults(matches => 1);
is($app->loc('welcome_en'), 'There is 1 match.', 'Template sg');
$app->defaults(matches => 0);
is($app->loc('welcome_en'), 'There are 0 matches.', 'Template Null');
$app->defaults(matches => 5);
is($app->loc('welcome_en'), 'There are 5 matches.', 'Template Plural');

plugin 'Localize' => {
  dict => {
    welcome => {
      de => q!Es gibt ! .
	    q!<%= quant(stash('matches'), stash('matches'), { 1 => 'ein', 0 => 'keinen' }) %> ! .
	    q!<%= quant(stash('matches'), 'Treffer', { ' 1.. 3 ' => 'Trefferlein', '4 ..10 ' => 'Trefferchen', '>30' => 'Tröffer'}) %>.!
    }
  }
};

$app->defaults(matches => 1);
is($app->loc('welcome_de'), 'Es gibt ein Trefferlein.', 'Template Einen');
$app->defaults(matches => 0);
is($app->loc('welcome_de'), 'Es gibt keinen Treffer.', 'Template Keinen');
$app->defaults(matches => 10);
is($app->loc('welcome_de'), 'Es gibt 10 Trefferchen.', 'Template Trefferchen');
$app->defaults(matches => 20);
is($app->loc('welcome_de'), 'Es gibt 20 Treffer.', 'Template Treffer');
$app->defaults(matches => 31);
is($app->loc('welcome_de'), 'Es gibt 31 Tröffer.', 'Template Troeffer');

done_testing;
