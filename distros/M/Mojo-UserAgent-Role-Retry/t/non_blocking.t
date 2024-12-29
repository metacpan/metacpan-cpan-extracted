use Mojo::Base -strict;
use Test::More;

{
  use Mojolicious::Lite;
  my $ok_if_you_wait_3yrs        = 0;
  my $render_ok_if_you_wait_3yrs = 0;
  get 'ok_if_you_wait_3yrs' => sub {
    $ok_if_you_wait_3yrs++;
    if ( $render_ok_if_you_wait_3yrs > 0
      && time - $render_ok_if_you_wait_3yrs >=
      Mojo::UserAgent->with_roles('+Retry')->new()->retry_wait_max )
    {
      return shift->render( text => $ok_if_you_wait_3yrs );
    }
    else {
      my $c = shift;
      $c->res->headers->header( 'retry-after' => 31556952 );
      $c->render( text => $ok_if_you_wait_3yrs, status => 429 );
      $render_ok_if_you_wait_3yrs = time;
    }
  };
}

my $ua = Mojo::UserAgent->with_roles('+Retry')->new( retries => 5 );
my ( $status, $content ) = ();
$ua->get(
  '/ok_if_you_wait_3yrs' => sub {
    my ( $ua, $tx ) = @_;
    $status  = $tx->res->code;
    $content = $tx->res->body;
    Mojo::IOLoop->stop;
  }
);
Mojo::IOLoop->start;
is $status,  200;
is $content, '2';

done_testing;
