use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Data::Dumper;

plugin 'SecurityHeader' => [
    'Access-Control-Expose-Headers'
];

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->header_is( 'Access-Control-Expose-Headers', undef );

done_testing();
