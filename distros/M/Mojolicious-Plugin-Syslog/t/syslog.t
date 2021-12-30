use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

use Mojolicious::Lite;
get '/foo' => sub {
  my $c = shift;
  Mojo::IOLoop->timer(0.1 => sub { $c->render(text => 'foo') });
};

my $n_original_subscribers = n_message_subscribers();
plugin syslog => {only_syslog => 1};
is n_message_subscribers(), $n_original_subscribers, 'syslog not activated';

app->mode('live');
plugin syslog => {};
is n_message_subscribers(), 2, 'syslog and original subscribed';

plugin syslog => {only_syslog => 1};
my $n_only_syslog = n_message_subscribers();
is $n_only_syslog, 1, 'only syslog subscribed';

my @log;
app->log->level('trace');
app->log->on(message => sub { shift; push @log, [@_] });
app->log->$_("dummy test $_") for qw(trace debug info warn error fatal);
is_deeply(
  \@log,
  [
    [trace => 'dummy test trace'],
    [debug => 'dummy test debug'],
    [info  => 'dummy test info'],
    [warn  => 'dummy test warn'],
    [error => 'dummy test error'],
    [fatal => 'dummy test fatal'],
  ],
  'messages logged',
);

plugin syslog => {access_log => 1};
my $t = Test::Mojo->new;
$t->app->log->level('info');
$t->get_ok('/foo')->status_is(200)->content_is('foo');
like $log[-1][1], qr|^GET "/foo" \(\w+\) 200 OK \(\d+\.?\d*s\)$|, 'access log'
  or diag explain \@log;

done_testing;

sub n_message_subscribers {
  return int @{app->log->subscribers('message')};
}
