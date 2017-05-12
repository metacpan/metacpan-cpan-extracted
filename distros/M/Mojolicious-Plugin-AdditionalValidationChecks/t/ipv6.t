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

  $validation->required( 'ip' )->ip(6);

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %ips = (
 '::1'                                 => 1,
 '2001:db8:0000:1:1:1:1:1'             => 1,
 '3ffe:1900:4545:3:200:f8ff:fe21:67cf' => 1,
 'fe80:0:0:0:200:f8ff:fe21:67cf'       => 1,
 'fe80::200:f8ff:fe21:67cf'            => 1,
 'fe80::0200:f8ff:fe21:67cf'           => 1,
 '2002:4559:1fe2::4559:1fe2'           => 1,

 '127.0.0.1'       => 0,
 '0.0.0.0'         => 0,
 '255.255.255.255' => 0,
 '1.2.3.4'         => 0,
 '256.1.1.1'       => 0,
 '1.256.1.1'       => 0,
 '1.1.256.1'       => 0,
 '1.1.1.256'       => 0,
 'a'               => 0,
 '1.a.b.c'         => 0,
 '1.1.1.1.1'       => 0,
 '1a.1.1.1'        => 0,
);

my $t = Test::Mojo->new;
for my $ip ( sort keys %ips ) {
    my $esc = url_escape $ip;
    $t->get_ok('/?ip=' . $esc)->status_is(200)->content_is( $ips{$ip}, "Test: $ip" );
}

done_testing();
