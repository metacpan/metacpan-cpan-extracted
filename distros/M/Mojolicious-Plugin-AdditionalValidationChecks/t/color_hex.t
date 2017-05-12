use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(url_escape);

plugin 'AdditionalValidationChecks';

my %colors = (
    '2'                 => 0,
    'abcd'              => 0,
    'rgb[1,2,3]'        => 0,
    'rgb(a1,2,3)'       => 0,
    '#affe'             => 0,
    '#aff'              => 1,
    '#zabel'            => 0,
    '#090909'           => 1,
    '#affe12'           => 1,
);

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  my $params     = $c->req->params->to_hash;

  $validation->input( $params );
  $validation->required( 'color' )->color( 'hex' );

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my $t = Test::Mojo->new;
for my $color ( sort keys %colors ) {
    my $res = $colors{$color};
    my $escaped = url_escape $color;
    $t->get_ok('/?color=' . $escaped )
      ->status_is(200)->content_is( $res, "Check: $color" );
}

done_testing();
