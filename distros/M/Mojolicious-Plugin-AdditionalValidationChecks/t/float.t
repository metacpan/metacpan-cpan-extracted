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

  $validation->required( 'float' )->float();

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %floats = (
  "123"       => 0,
  "123.1"     => 1,
  "a"         => 0,
  "-9"        => 0,
  "+3"        => 0,
  0           => 0,
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
for my $float ( sort keys %floats ) {
    my $esc = url_escape( $float );
    $t->get_ok('/?float=' . $esc)->status_is(200)->content_is( $floats{$float}, "Test: $float" );
}

done_testing();
