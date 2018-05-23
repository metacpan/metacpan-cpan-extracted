use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'SecurityHeader' => [
    'X-Xss-Protection' => 3.2
];

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)
  ->header_isnt( 'X-Xss-Protection', 3.2 )
  ->header_isnt( 'X-Xss-Protection', 3 )
;

done_testing();
