use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  my $ok_if_twice = 0;
  get '/ok_if_twice' => sub {
    if ( $ok_if_twice++ > 0 ) { return shift->render( text => $ok_if_twice, status => 200 ) }
    shift->render( text => $ok_if_twice, status => 500 );
  };
}

my $t = Test::Mojo->new;
$t->ua( Mojo::UserAgent->with_roles('+Retry')->new(retries => 1) );

$t->get_ok('/ok_if_twice')->status_is(500)->content_is(1);

done_testing;
