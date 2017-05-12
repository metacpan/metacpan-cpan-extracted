use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'AdditionalValidationChecks';

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->req->params->to_hash );

  $validation->required( 'nr' )->int();

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %nrs = (
  "123"    => 1,
  "123.1"  => 0,
  "a"      => 0,
  "-9"     => 1,
  "+3"     => 1,
  0        => 1,
);

my $t = Test::Mojo->new;
for my $nr ( sort keys %nrs ) {
    (my $esc = $nr) =~ s/\+/\%2B/g;
    $t->get_ok('/?nr=' . $esc)->status_is(200)->content_is( $nrs{$nr}, "Test: $nr" );
}

done_testing();
