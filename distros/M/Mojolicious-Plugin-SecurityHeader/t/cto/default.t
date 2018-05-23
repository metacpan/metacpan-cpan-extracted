use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Data::Dumper;

plugin 'SecurityHeader' => [
    'X-Content-Type-Options'
];

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->header_is( 'X-Content-Type-Options', 'nosniff' );

done_testing();
