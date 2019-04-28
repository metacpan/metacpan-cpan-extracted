use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

use Mojolicious::Lite;
get '/foo' => sub {
  my $c = shift;
  Mojo::IOLoop->timer(0.1 => sub { $c->render(text => 'foo') });
};
my @original_subscribers = message_subscribers();
is @original_subscribers, 1, 'original message subscriber';

plugin syslog => {only_syslog => 1};
is_deeply [message_subscribers()], \@original_subscribers,
  'syslog not activated';

app->mode('live');
plugin syslog => {};
my @both_subscribers = message_subscribers();
is @both_subscribers, 2, 'syslog and original subscribed';
isnt $both_subscribers[-1], $original_subscribers[-1], 'syslog is second';

plugin syslog => {only_syslog => 1};
my @only_syslog = message_subscribers();
is @only_syslog, 1, 'only syslog subscribed';
is $only_syslog[0], $both_subscribers[-1], 'syslog is first';

my @log;
app->log->level('debug');
app->log->on(message => sub { shift; push @log, [@_] });
app->log->$_("dummy test $_") for qw(debug info warn error fatal);
is_deeply(
  \@log,
  [
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

sub message_subscribers {
  return @{app->log->subscribers('message')};
}
