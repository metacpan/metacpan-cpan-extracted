use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  my $ok_if_twice = 0;
  get '/ok_if_twice' => sub {
    if ( $ok_if_twice++ > 0 ) { return shift->render( text => $ok_if_twice, status => 200 ) }
    shift->render( text => $ok_if_twice, status => 418 );
  };

  my $ok_if_thrice = 0;
  get '/ok_if_thrice' => sub {
    if ( $ok_if_thrice++ > 2 ) { return shift->render( text => $ok_if_thrice, status => 200 ) }
    shift->render( text => $ok_if_thrice, status => 418 );
  };
}

my $t = Test::Mojo->new;
$t->ua( Mojo::UserAgent->with_roles('+Retry')->new(
  retries => 1,
  retry_policy => sub {
    if (shift->res->code == 418) { return 0; }
    return 1;
  }
));

$t->get_ok('/ok_if_twice')->status_is(200)->content_is(2);
$t->get_ok('/ok_if_thrice')->status_is(418)->content_is(2);

done_testing;
