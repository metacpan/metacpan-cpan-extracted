use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(url_escape);

plugin 'AdditionalValidationChecks';

my %colors = (
    '2'                     => 0,
    'abcd'                  => 0,
    'rgba[1,2,3]'           => 0,
    'rgba(a1,2,3)'          => 0,
    'rgba(311,12,33)'       => 0,
    'rgba(311,12,33,)'      => 0,
    'rgba(255,255,255,)'    => 0,
    'rgba(11,12,33)'        => 0,
    'rgba(255,255,255)'     => 0,
    'rgba(0,0,0)'           => 0,
    'rgba(0, 0, 0)'         => 0,
    'rgba(00,0,0)'          => 0,
    'rgba(11,12,33,0)'      => 1,
    'rgba(255,255,255,0.0)' => 1,
    'rgba(0,0,0,0.3)'       => 1,
    'rgba(0, 0, 0, 0.6)'    => 1,
    'rgba(11,12,33,1)'      => 1,
    'rgba(255,255,255,1.0)' => 1,
    'rgba(0,0,0,1.1)'       => 0,
    'rgba(0, 0, 0, 1.6)'    => 0,
);

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  my $params     = $c->req->params->to_hash;

  $validation->input( $params );
  $validation->required( 'color' )->color( 'rgba' );

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
