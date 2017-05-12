use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'AdditionalValidationChecks';

my %words = (
    '2'     => [ 0, 5, 1 ],
    'abcd'  => [ 3, undef, 1 ],
    '5'     => [ 5, undef, 0 ],
    'abcd'  => ['abcd', 0 ],
    '3.0'   => [1, 2, 3, 1],
    1       => [0, 1],
    1       => [1],
);

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  my $params     = $c->req->params->to_hash;
  my $word       = $params->{word};

  $validation->input( $params );
  $validation->required( 'word' )->not( @{$words{$word}} );

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my $t = Test::Mojo->new;
for my $word ( keys %words ) {
    my $res = pop @{ $words{$word} };
    my @values = map{ defined $_ ? $_ : '<undef>' }@{ $words{$word} };
    $t->get_ok('/?word=' . $word )
      ->status_is(200)->content_is( $res, "Check: $word // @values" );
}

done_testing();
