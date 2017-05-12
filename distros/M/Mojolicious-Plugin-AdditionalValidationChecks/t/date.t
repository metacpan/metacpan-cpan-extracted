use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'AdditionalValidationChecks';

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->req->params->to_hash );

  $validation->required( 'date' )->date();

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %dates = (
  "123"    => 0,
  "123.1"  => 0,
  "a"      => 0,
  "-9"     => 0,
  "+3"     => 0,
  0        => 0,
  "a"      => 0,

  "2013-02-28" => 1,
  "2013-02-29" => 0,
  "2013-02-30" => 0,
  "2013-02-31" => 0,
  "2013-02-32" => 0,
  "2013-12-31" => 1,
  "2013-12-32" => 0,
  "2013-2-28" => 0,
  "201-02-28" => 0,
  "2013-02-2" => 0,
  "2000-02-28" => 1,
  "2000-02-29" => 1,
  "2000-02-30" => 0,
  "2000-01-01" => 1,
  "2000-06-30" => 1,
  "2000-06-31" => 0,
);

my $t = Test::Mojo->new;
for my $date ( sort keys %dates ) {
    (my $esc = $date) =~ s/\+/\%2B/g;
    $t->get_ok('/?date=' . $esc)->status_is(200)->content_is( $dates{$date}, "Test: $date" );
}

done_testing();
