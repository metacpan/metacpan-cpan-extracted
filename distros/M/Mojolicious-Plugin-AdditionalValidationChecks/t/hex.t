use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(url_escape);

plugin 'AdditionalValidationChecks';

my %hexs = (
    '3'           => 1,
    'abcd'        => 1,
    'rgb[1,2,3]'  => 0,
    'rgb(a1,2,3)' => 0,
    'affe'        => 1,
    'aff'         => 1,
    'zabel'       => 0,
    '090909'      => 1,
    'affe12'      => 1,
);

get '/' => sub {
  my $c = shift;

  my $validation = $c->validation;
  my $params     = $c->req->params->to_hash;

  $validation->input( $params );
  $validation->required( 'hex' )->hex();

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my $t = Test::Mojo->new;
for my $hex ( sort keys %hexs ) {
    my $res = $hexs{$hex};
    my $escaped = url_escape $hex;
    $t->get_ok('/?hex=' . $escaped )
      ->status_is(200)->content_is( $res, "Check: $hex" );
}

done_testing();
