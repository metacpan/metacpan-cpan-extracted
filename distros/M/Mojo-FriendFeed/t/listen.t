BEGIN { $ENV{MOJO_REACTOR} = 'Poll' }

use Mojolicious::Lite;
use Mojo::IOLoop;

# a mock feed, whose entry says whether is came from a cursor, for ease of testing
any '/feed' => sub { 
  my $c = shift;
  $c->render_later;
  my $data = { 
    entries  => [ { got_cursor => !! $c->param('cursor') ? 1 : 0 } ],
    realtime => { cursor => 1 },
  };
  Mojo::IOLoop->timer( 0.5 => sub { 
    $c->render( json => $data ); 
  });
};

# a mock feed error, has a 401 status and a fake errorCode mimicing a friend feed errorCode
any '/error' => sub {
  my $c = shift;
  $c->render_later;
  Mojo::IOLoop->timer( 0.5 => sub {
    $c->render( json => { errorCode => 'test-feed-error' }, status => 401 );
  });
};

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

subtest 'Ensure sane mock service' => sub {
  $t->get_ok( '/feed' )
    ->status_is(200)
    ->json_is( '/entries/0/got_cursor' => 0 );

  $t->get_ok( '/feed' => form => { cursor => 1 } )
    ->status_is(200)
    ->json_is( '/entries/0/got_cursor' => 1 );

  $t->get_ok( '/error' )
    ->status_is(401);
};
  
use Mojo::FriendFeed;
use Mojo::URL;

my $feed = $t->app->url_for('feed');
my $err  = $t->app->url_for('error');

subtest 'Simple' => sub {
  my $ff = Mojo::FriendFeed->new( url => $feed->clone );
  my $ok = 0;
  $ff->on( entry => sub { $ok++; Mojo::IOLoop->stop });
  $ff->listen;
  Mojo::IOLoop->start;
  is $ok, 1;
};

subtest 'Cursor' => sub {
  my $ff = Mojo::FriendFeed->new( url => $feed->clone );
  my $ok = 0;
  $ff->on( entry => sub { 
    $ok++;
    Mojo::IOLoop->stop if pop->{got_cursor};
  });
  $ff->listen;
  Mojo::IOLoop->start;
  is $ok, 2;
};

subtest 'Error' => sub {
  my $ok;
  local $SIG{__DIE__} = sub { $ok++; Mojo::IOLoop->stop };
  my $ff = Mojo::FriendFeed->new( url => $err->clone );
  $ff->listen;
  Mojo::IOLoop->start;
  ok $ok, 'unhandled error throws';
};

subtest 'Reconnect after error' => sub {
  my $ff = Mojo::FriendFeed->new( url => $err->clone );
  my ($ok, $tx, $ff_err);
  $ff->on( error => sub { (undef, $tx, $ff_err) = @_; shift->url( $feed->clone )->listen });
  $ff->on( entry => sub { $ok++; Mojo::IOLoop->stop });
  $ff->listen;
  Mojo::IOLoop->start;
  ok $tx, 'caught error event';
  is $tx->res->code, 401;
  is $ff_err, 'test-feed-error', 'got errorCode';
  ok $ok, 'restarted and got next message';
};

done_testing;

