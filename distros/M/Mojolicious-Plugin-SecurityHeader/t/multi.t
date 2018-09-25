use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'SecurityHeader' => [
    'Strict-Transport-Security' => -1,
    'Referrer-Policy',
    'X-Xss-Protection',
    'X-Content-Type-Options' => 'nosniff',
];

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)
  ->header_is( 'Strict-Transport-Security', 'max-age=31536000', 'STS' )
  ->header_is( 'X-Xss-Protection', '1; mode=block', 'XXP' )
  ->header_is( 'Referrer-Policy', '', 'RP' );

done_testing();
