use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

@main::openlog  = ();
@main::messages = ();
mock_syslog();

use Mojolicious::Lite;
get '/bar' => sub { die "Oops!\n" };

get '/foo' => sub {
  my $c = shift;
  Mojo::IOLoop->timer(0.1 => sub { $c->render(text => 'foo') });
};

$ENV{MOJO_SYSLOG_FACILITY}   = 'local0';
$ENV{MOJO_SYSLOG_IDENT}      = 'cool_app';
$ENV{MOJO_SYSLOG_LOGOPT}     = 'pid';
$ENV{MOJO_SYSLOG_ENABLE}     = '1';
$ENV{MOJO_SYSLOG_ACCESS_LOG} = '%H %P %C';

plugin syslog => {only_syslog => 1};
is_deeply \@main::openlog, [qw(cool_app pid local0)], 'openlog';

my $t = Test::Mojo->new;
$t->app->log->level('info');
$t->get_ok('/foo')->status_is(200);
$t->get_ok('/bar')->status_is(500);
$t->get_ok('/baz')->status_is(404);

is_deeply(
  \@main::messages,
  [
    [L_INFO    => 'GET /foo 200'],
    [L_ERR     => 'Oops!'],
    [L_WARNING => 'GET /bar 500'],
    [L_INFO    => 'GET /baz 404']
  ],
  'syslog messages',
) or diag explain \@main::messages;

done_testing;

sub mock_syslog {
  $INC{'Sys/Syslog.pm'} = __FILE__;
  eval <<'HERE' or die $@;
package Sys::Syslog;
use Mojo::Util 'monkey_patch';
sub import {
  my $caller = caller;
  monkey_patch $caller => LOG_CRIT    => sub { 'L_CRIT' };
  monkey_patch $caller => LOG_DEBUG   => sub { 'L_DEBUG' };
  monkey_patch $caller => LOG_ERR     => sub { 'L_ERR' };
  monkey_patch $caller => LOG_INFO    => sub { 'L_INFO' };
  monkey_patch $caller => LOG_WARNING => sub { 'L_WARNING' };
  monkey_patch $caller => LOG_USER    => sub { die };
  monkey_patch $caller => openlog => sub { push @main::openlog, @_ };
  monkey_patch $caller => syslog  => sub { push @main::messages, [shift, sprintf shift, @_] };
}
1;
HERE
}

