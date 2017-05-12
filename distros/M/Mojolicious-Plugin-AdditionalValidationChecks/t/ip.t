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

  $validation->required( 'ip' )->ip();

  my $result = $validation->has_error() ? 0 : 1;
  $c->render(text => $result );
};

my %ips = (
 '127.0.0.1'        => 1,
 '0.0.0.0'          => 1,
 '255.255.255.255'  => 1,
 '1.2.3.4'          => 1,

 '::1'                     => 0,
 '2001:db8:0000:1:1:1:1:1' => 0,
 '256.1.1.1'               => 0,
 '1.256.1.1'               => 0,
 '1.1.256.1'               => 0,
 '1.1.1.256'               => 0,
 'a'                       => 0,
 '1.a.b.c'                 => 0,
 '1.1.1.1.1'               => 0,
 '1a.1.1.1'                => 0,
);

my $t = Test::Mojo->new;
for my $ip ( sort keys %ips ) {
    my $esc = url_escape $ip;
    $t->get_ok('/?ip=' . $esc)->status_is(200)->content_is( $ips{$ip}, "Test: $ip" );
}

done_testing();
