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

  $validation->required( 'http_url' )->http_url();

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %urls = (
  'root@localhost'              => 0,
  123                           => 0,
  'ftp://ftp.test.de'           => 0,
  'http://test.de'              => 1,
  'https://metacpan.org'        => 1,
  '/test'                       => 0,
  'http://google.de/?q=test'    => 1,
);

my $t = Test::Mojo->new;
for my $url ( keys %urls ) {
    my $esc = url_escape $url;
    $t->get_ok('/?http_url=' . $esc)->status_is(200)->content_is( $urls{$url}, "Address: $url" );
}

done_testing();
