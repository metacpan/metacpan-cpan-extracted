use Mojo::Base -strict;
use Test::More;

use Mojo::UserAgent;

{
  package Mojo::UserAgent::Signature::AB1;
  use Mojo::Base 'Mojo::UserAgent::Signature::Base';
  sub sign_tx {
    my ($self, $tx, $ab1) = @_;
    $ab1 ||= AB1->new;
    $tx->req->headers->header('X-AB1' => $ab1->token);
    return $tx;
  }
  package AB1;
  use Mojo::Base -base;
  has token => 'AB1';
}

my $ab1 = AB1->new;
my $tx;
my $ua = Mojo::UserAgent->new->with_roles('+Signature')->new;
$ua->initialize_signature(AB1 => $ab1);

$tx = $ua->build_tx(GET => '/abc');
is $tx->req->headers->header('X-Mojo-Signature'), 'AB1', 'signed request';
is $tx->req->headers->header('X-AB1'), 'AB1', 'right token';

$tx = $ua->build_tx(GET => '/abc' => 'sign');
is $tx->req->headers->header('X-Mojo-Signature'), 'AB1', 'signed request';
is $tx->req->headers->header('X-AB1'), 'AB1', 'right token';

$tx = $ua->build_tx(GET => '/abc' => sign => $ab1->token('1AB1'));
is $tx->req->headers->header('X-Mojo-Signature'), 'AB1', 'signed request';
is $tx->req->headers->header('X-AB1'), '1AB1', 'right token';

$tx = $ua->build_tx(GET => '/abc' => sign => json => {a => 1});
is $tx->req->headers->header('X-Mojo-Signature'), 'AB1', 'signed request';
is $tx->req->headers->header('X-AB1'), 'AB1', 'right token';
is $tx->req->json('/a'), 1;

$tx = $ua->build_tx(GET => '/abc' => sign => $ab1->token('2AB1') => json => {b => 2});
is $tx->req->headers->header('X-Mojo-Signature'), 'AB1', 'signed request';
is $tx->req->headers->header('X-AB1'), '2AB1', 'right token';
is $tx->req->json('/b'), 2;

done_testing;