use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  my $root_counter = 0;
  get '/' => sub {
    $root_counter++;
    shift->render( text => $root_counter );
  };

  my $ok_if_twice = 0;
  get '/ok_if_twice' => sub {
    if ( $ok_if_twice++ > 0 ) { return shift->render( text => $ok_if_twice ) }
    shift->render( text => $ok_if_twice, status => 429 );
  };

  my $ok_if_six = 0;
  get '/ok_if_six' => sub {
    if ( $ok_if_six++ > 4 ) { return shift->render( text => $ok_if_six ) }
    shift->render( text => $ok_if_six, status => 429 );
  };

  my $ok_if_you_wait_5s        = 0;
  my $render_ok_if_you_wait_5s = 0;
  get 'ok_if_you_wait_5s' => sub {
    $ok_if_you_wait_5s++;
    if ( $render_ok_if_you_wait_5s > 0 && time - $render_ok_if_you_wait_5s >= 5 ) {
      return shift->render( text => $ok_if_you_wait_5s );
    }
    else {
      my $c = shift;
      $c->res->headers->header( 'retry-after' => 5 );
      $c->render( text => $ok_if_you_wait_5s, status => 429 );
      $render_ok_if_you_wait_5s = time;
    }
  };

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

  my $no_more_than_retry_max_counter = 0;
  get 'no_more_than_retry_max_counter' => sub {
    shift->render( text => ++$no_more_than_retry_max_counter, status => 429 );
  };
}

my $t = Test::Mojo->new;
$t->ua( Mojo::UserAgent->with_roles('+Retry')->new( retries => 5 ) );

$t->get_ok('/')->status_is(200)->content_is(1);
$t->get_ok('/ok_if_twice')->status_is(200)->content_is(2);
$t->get_ok('/ok_if_six')->status_is(200)->content_is(6);
$t->get_ok('/ok_if_you_wait_5s')->status_is(200)->content_is(2);
$t->get_ok('/ok_if_you_wait_3yrs')->status_is(200)->content_is(2);
$t->get_ok('/no_more_than_retry_max_counter')->status_is(429)
  ->content_is( $t->ua->retries + 1 );

done_testing;
