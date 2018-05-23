use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'SecurityHeader' => [
    'Strict-Transport-Security' => 3.2,
];

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->header_isnt( 'Strict-Transport-Security', 3.2 );
$t->get_ok('/')->status_is(200)->header_isnt( 'Strict-Transport-Security', 3 );

done_testing();
