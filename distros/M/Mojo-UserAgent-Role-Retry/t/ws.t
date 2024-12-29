# Just to ensure we don't break WebSockets on UAs with Retry
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  websocket '/ws' => sub {
    shift->on( text => sub { shift->send( { text => "testing: " . shift } ); } );
  };
}

my $t = Test::Mojo->new;
$t->ua( Mojo::UserAgent->with_roles('+Retry')->new( retries => 5 ) );

$t->websocket_ok('/ws')->send_ok('test')
  ->message_ok->message_is('testing: test')->finish_ok;

done_testing;
