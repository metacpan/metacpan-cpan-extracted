use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(url_escape);

plugin 'AdditionalValidationChecks';

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->req->params->to_hash );

  $validation->required( 'number' )->number();

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %numbers = (
  "123"       => 1,
  "123.1"     => 1,
  "a"         => 0,
  "abc"       => 0,
  "12a"       => 0,
  "-9"        => 1,
  "+3"        => 1,
  0           => 1,
  "-9.33"     => 1,
  "+3.912"    => 1,
  "0.0"       => 1,
  "-9.33E1"   => 1,
  "-9.33e1"   => 1,
  "-9.33e+12" => 1,
  "-9.33e-12" => 1,
  "-9.33E+12" => 1,
  "-9.33E-12" => 1,
);

my $t = Test::Mojo->new;
for my $number ( sort keys %numbers ) {
    my $esc = url_escape( $number );
    $t->get_ok('/?number=' . $esc)->status_is(200)->content_is( $numbers{$number}, "Test: $number" );
}

done_testing();
