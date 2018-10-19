use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mojolicious;
use Mojolicious::Controller;
use Mojo::Util 'monkey_patch';

monkey_patch 'Mojolicious'             => AUTOLOAD => sub { die 'Should never come to this' };
monkey_patch 'Mojolicious::Controller' => AUTOLOAD => sub { die 'Should never come to this' };

my $app = Mojolicious->new;
ok !$app->isa('Mojolicious::_FastHelpers'), 'not isa Mojolicious::_FastHelpers';

$app->helper('answer'    => sub {42});
$app->helper('what.ever' => sub {shift});
$app->plugin('FastHelpers');
ok $app->isa('Mojolicious::_FastHelpers'), 'isa Mojolicious::_FastHelpers';
ok $app->can('config'),                    'can config';
ok !$app->can('not_present'), 'cannot not_present';
ok !$app->can('answer'),      'cannot answer';
is $app->answer, 42, 'answer';
is $app->build_controller->answer, 42, 'answer';

$app = Mojolicious->new;
ok +Mojolicious::_FastHelpers->can('answer'), 'answer is still present in helper class';
eval { $app->answer };
like $@, qr{Can't locate object method "answer" via package "Mojolicious"}, 'answer() is not present in new app';
eval { $app->build_controller->answer };
like $@, qr{Can't locate object method "answer" via package "Mojolicious::Controller"},
  'answer() is not present in new controller';

done_testing;
