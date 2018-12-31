use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'AdditionalValidationChecks';

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  my $params     = $c->req->params->to_hash;

  $params->{max} = ''    if $params->{max} eq '';
  $params->{max} = undef if $params->{max} eq '<undef>';

  $validation->input( $params );
  $validation->required( 'nr' )->max( $params->{max} );

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %nrs = (
    '-3'  => [ '-10',     0 ],
    '-3'  => [ '-1',      1 ],
    '3'   => [ '-1',      0 ],
    '3'   => [ '4',       1 ],
    '3'   => [ '3',       1 ],
    'a'   => [ '4',       0 ],
    '4.3' => [ '4',       0 ],
    '4.0' => [ '4',       1 ],
    '2.9' => [ '3',       1 ],
    '2.9' => [ '',        1 ],
    '2.9' => [ '<undef>', 1 ],
);

my $t = Test::Mojo->new;
for my $nr ( keys %nrs ) {
    (my $esc = $nr) =~ s/\+/\%2B/g;
    my ($max,$res)  = @{ $nrs{$nr} };
    $t->get_ok('/?nr=' . $esc . '&max=' . $max)->status_is(200)->content_is( $res, "Check: $nr // $max" );
}

done_testing();
