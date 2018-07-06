use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Data::Dumper;

plugin 'SecurityHeader' => [
    'Content-Security-Policy'
];

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->header_is( 'Content-Security-Policy', "default-src 'self'" );

done_testing();
