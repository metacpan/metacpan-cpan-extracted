use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;

  get '/redirect' => sub {
    my $c = shift;
    $c->redirect_to('/target');
  };

  get '/target' => sub {
    my $c = shift;
    $c->render( text => "here\n" );
  };
}

my $t = Test::Mojo->new;
$t->ua( Mojo::UserAgent->with_roles('+Retry')->new( retries => 5, max_redirects => 5 ) );

$t->get_ok('/redirect')
  ->status_is(200)
  ->content_is("here\n");

my $res;

$t->ua->get('/redirect', sub {
    my($ua, $tx) = @_;
    $res = $tx->res;
    Mojo::IOLoop->stop;
});

Mojo::IOLoop->start;

is($res->code, 200);
is($res->body, "here\n");

done_testing;