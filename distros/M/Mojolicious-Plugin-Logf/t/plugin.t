use Mojo::Base -base;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  plugin "Logf";

  get "/" => sub {
    my $c = shift;

    $c->stash(s => { p => 123 });
    $c->logf(info => 'request: %s', $c->req->params->to_hash);
    $c->logf(warn => 'data: %s %s', undef, $c);
    $c->render(text => 'whatever');
  };

  get "/code" => sub {
    my $c = shift;
    $c->logf(info => 'code: %s', sub { $c->req->params->to_hash })->render(text => 'code');
  };

  get "/flatten" => sub {
    my $c = shift;
    $c->render(text => $c->logf->flatten($c->req->params->to_hash));
  };
}

my $t = Test::Mojo->new;
my @messages;
delete $ENV{MOJO_LOG_LEVEL};

$t->app->log->level('debug');
$t->app->log->unsubscribe('message');
$t->app->log->on(message => sub { shift; push @messages, [@_] if $_[0] =~ /info|warn/; });

@messages = ();
$t->get_ok("/?foo=123&bar=42")->status_is(200)->content_is("whatever");
is $messages[0][0], 'info', 'log info';
like $messages[0][1], qr{bar.*42}, 'logf to_hash';
is $messages[1][0], 'warn', 'log warn';
like $messages[1][1], qr{__UNDEF__}, 'logf undef';
like $messages[1][1], qr{Mojolicious::Controller}, 'logf Mojolicious::Controller';
like $messages[1][1], qr{Mojolicious::Controller}, 'logf Mojolicious::Controller';
like $messages[1][1], qr{'s'.*'HASH}, 'logf stash';

@messages = ();
$t->app->log->level('warn');
$t->get_ok("/code?foo=warn")->status_is(200)->content_is('code');
is_deeply \@messages, [], 'no messages on info level';

$t->app->log->level('info');
$t->get_ok("/code?foo=info")->status_is(200)->content_is('code');
like $messages[0][1], qr{code:.*foo.*info}, 'logf code ref';

$t->get_ok("/flatten?foo=123")->status_is(200)->content_like(qr{'foo'.*123});

done_testing;
