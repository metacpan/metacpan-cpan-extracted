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

  $validation->required( 'uuid' )->uuid( 3 );

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %uuids = (
  'A987FBC9-4BED-3078-CF07-9141BA07C9F3'    => 1,

  ''                                        => 0,
  'xxxA987FBC9-4BED-3078-CF07-9141BA07C9F3' => 0,
  '934859'                                  => 0,
  'AAAAAAAA-1111-1111-AAAG-111111111111'    => 0,
  'A987FBC9-4BED-4078-8F07-9141BA07C9F3'    => 0,
  'A987FBC9-4BED-5078-AF07-9141BA07C9F3'    => 0,
);

my $t = Test::Mojo->new;
for my $uuid ( sort keys %uuids ) {
    my $esc = url_escape $uuid;
    $t->get_ok('/?uuid=' . $esc)->status_is(200)->content_is( $uuids{$uuid}, "Test: $uuid" );
}

done_testing();
