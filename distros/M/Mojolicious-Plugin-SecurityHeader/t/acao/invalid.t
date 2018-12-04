use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'SecurityHeader' => [
    'Access-Control-Allow-Origin' => 'hallo',
];

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)
  ->header_isnt( 'Access-Control-Allow-Origin', 'hallo' )
;

done_testing();
