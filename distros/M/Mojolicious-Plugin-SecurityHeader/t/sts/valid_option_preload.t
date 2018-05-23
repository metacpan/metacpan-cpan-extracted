use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'SecurityHeader' => [
    'Strict-Transport-Security' => { maxage => 1, opt => 'preload' },
];

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->header_is('Strict-Transport-Security', 'max-age=1; preload' );

done_testing();
