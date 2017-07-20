use Test2::V0 -no_srand => 1;
BEGIN { $ENV{MOJO_MODE}='testing'; };
use Test::Clustericious::Blocking;
use Mojolicious::Lite;
use Test::Mojo;
use HTTP::Tiny;

BEGIN {
  my $code = q{
    use Mojolicious 7.31;
    1;
  };
  
  skip_all 'Test requires Mojolicious 7.31'
    unless eval $code;
}

app->log->level('fatal');

get '/foo' => sub { shift->render(text => 'a response') };

my $t = Test::Mojo->new;

$t->get_ok('/foo')
  ->content_is('a response');

my $url = $t->tx->req->url->to_abs;

note "url = $url";

is blocking { HTTP::Tiny->new->get($url)->{content} }, 'a response', 'with HTTP::Tiny';

done_testing;
