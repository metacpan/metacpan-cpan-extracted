use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(url_escape);

plugin 'AdditionalValidationChecks';

my %colors = (
    '2'                      => 0,
    'abcd'                   => 0,
    'hsl[1,2,3]'             => 0,
    'hsla[1,2,3]'            => 0,
    'hsl(a1,2,3)'            => 0,
    'hsla(a1,2,3)'           => 0,
    'hsl(311,12,33)'         => 0,
    'hsla(311,12,33)'        => 0,
    'hsl(311,12,33,)'        => 0,
    'hsla(311,12,33,)'       => 0,
    'hsl(120,0%,0%)'         => 1,
    'hsl(120deg,0%,0%)'      => 1,
    'hsl(120, 0%, 0%)'       => 1,
    'hsl(-120,0%,0%)'        => 1,
    'hsl(-120deg,0%,0%)'     => 1,
    'hsl(-1turn,0%,0%)'      => 1,
    'hsl(-1rad,0%,0%)'       => 1,
    'hsl(10rad,100%,0%)'     => 1,
    'hsl(10rad,100%,100%)'   => 1,
    'hsl(120, 200%, 0%)'     => 0,
    'hsl(120, 20%, 130%)'    => 0,
    'hsla(120,0%,0%)'        => 1,
    'hsla(120deg,0%,0%)'     => 1,
    'hsla(120, 0%, 0%)'      => 1,
    'hsla(-120,0%,0%)'       => 1,
    'hsla(-120deg,0%,0%)'    => 1,
    'hsla(-1turn,0%,0%)'     => 1,
    'hsla(-1rad,0%,0%)'      => 1,
    'hsla(10rad,100%,0%)'    => 1,
    'hsla(10rad,100%,100%)'  => 1,
    'hsla(120, 200%, 0%)'    => 0,
    'hsla(120, 20%, 130%)'   => 0,
    'hsl(120 0% 0%)'         => 1,
    'hsl(120deg 0% 0%)'      => 1,
    'hsl(120  0%  0%)'       => 1,
    'hsl(-120 0% 0%)'        => 1,
    'hsl(-120deg 0% 0%)'     => 1,
    'hsl(-1turn 0% 0%)'      => 1,
    'hsl(-1rad 0% 0%)'       => 1,
    'hsl(10rad 100% 0%)'     => 1,
    'hsl(10rad 100% 100%)'   => 1,
    'hsl(120  200%  0%)'     => 0,
    'hsl(120  20%  130%)'    => 0,
    'hsla(120 0% 0%)'        => 1,
    'hsla(120deg 0% 0%)'     => 1,
    'hsla(120  0%  0%)'      => 1,
    'hsla(-120 0% 0%)'       => 1,
    'hsla(-120deg 0% 0%)'    => 1,
    'hsla(-1turn 0% 0%)'     => 1,
    'hsla(-1rad 0% 0%)'      => 1,
    'hsla(10rad 100% 0%)'    => 1,
    'hsla(10rad 100% 100%)'  => 1,
    'hsla(120  200%  0%)'    => 0,
    'hsla(120  20%  130%)'   => 0,
    'hsl(120,0%,0%,0)'       => 1,
    'hsl(120deg,0%,0%,.5)'   => 1,
    'hsl(120, 0%, 0%, .75)'  => 1,
    'hsl(-120,0%,0%, 0.2)'   => 1,
    'hsl(-120deg,0%,0%, 1)'  => 1,
    'hsl(-1turn,0%,0%,2)'    => 0,
    'hsl(-1turn,0%,0%,-1)'   => 0,
    'hsl(-120deg,0%,0%,1.0)' => 1,
    'hsl(120deg 0% 0% / .5)' => 1,
    'hsl(120  0%  0% / .75)' => 1,
    'hsl(-120 0% 0% / 0.2)'  => 1,
    'hsl(-120deg 0% 0% / 1)' => 1,
    
);

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  my $params     = $c->req->params->to_hash;

  $validation->input( $params );
  $validation->required( 'color' )->color( 'hsl' );

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
