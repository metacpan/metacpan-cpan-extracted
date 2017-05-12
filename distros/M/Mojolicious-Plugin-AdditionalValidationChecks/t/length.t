use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'AdditionalValidationChecks';

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  my $params     = $c->req->params->to_hash;

  $validation->input( $params );
  $validation->required( 'word' )->length( $params->{min}, $params->{max} );

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %words = (
    'abcd'  => [ 0, 5, 1 ],
    'abcd'  => [ 3, undef, 1 ],
    'abcd'  => [ 5, undef, 0 ],
    'abcd'  => [ 5, 10, 0 ],
);

my $t = Test::Mojo->new;
for my $word ( keys %words ) {
    (my $esc = $word) =~ s/\+/\%2B/g;
    my ($min, $max, $res)  = @{ $words{$word} };
    $t->get_ok('/?word=' . $esc . '&min=' . $min . '&max=' . $max)
      ->status_is(200)->content_is( $res, "Check: $word // $min // $max" );
}

done_testing();
