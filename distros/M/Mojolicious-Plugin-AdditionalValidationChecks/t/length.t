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
    'abcde'  => [ 3, '', 1 ],
    'abce'  => [ 5, '', 0 ],
    'abed'  => [ 5, 10, 0 ],
    'aecd'  => [ '', '', 1 ],
    'ebcd'  => [ '', 5, 1 ],
    'becd'  => [ 2, 3, 0 ],
    'a'     => [ 2, 3, 0 ],
);

my $t = Test::Mojo->new;
for my $word ( keys %words ) {
    (my $esc = $word) =~ s/\+/\%2B/g;
    my ($min, $max, $res)  = @{ $words{$word} };
    $t->get_ok('/?word=' . $esc . '&min=' . $min . '&max=' . $max)
      ->status_is(200)->content_is( $res, "Check: $word // $min // $max" );
}

done_testing();
