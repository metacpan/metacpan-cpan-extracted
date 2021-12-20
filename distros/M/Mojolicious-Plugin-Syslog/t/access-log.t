use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

$ENV{MOJO_SYSLOG_ENABLE} = 0;    # only access log

use Mojolicious::Lite;
my @log;
app->log->level('info');
app->log->unsubscribe('message');
app->log->on(message => sub { shift; push @log, "@_" });

get '/foo' => sub {
  my $c = shift;
  $c->req->request_id('superwoman');
  Mojo::IOLoop->timer(0.1 => sub { $c->render(text => 'foo') });
};

plugin syslog => {access_log => 1};
plugin syslog => {access_log => 'v2'};
plugin syslog =>
  {access_log => 'A=%A C=%C F=%F H=%H I=%I M=%M P=%P R=%R T=%Ts U=%U'};

my $t = Test::Mojo->new;
$t->get_ok('/foo',
  {'Referer' => 'https://example.com', 'User-Agent' => 'SuperAgent'})
  ->status_is(200)->content_is('foo');

note "logged: $_" for @log;

my ($v1) = grep {m!GET "/!} @log;
like $v1, qr{GET "/foo" \(superwoman\) 200 OK \(0\.\d+s\)$}, 'v1';

my ($v2) = grep {m!GET http!} @log;
like $v2,
  qr{[\d\.]+ GET http://\S+ 200 "https://example\.com" "SuperAgent" \(0\.\d+s\)$},
  'v2';

my ($all) = grep {/\sA=/} @log;
like $all,
  qr{A=SuperAgent C=200 F=https://example\.com H=GET I=superwoman M=OK P=/foo R=[\d\.]+ T=0\.\d+s U=http://\S+$},
  'variables';

done_testing;
