use 5.014;

use lib 't/lib';

BEGIN {
  use File::Temp 'tempdir';

  $ENV{STENCIL_HOME} = tempdir('cleanup', 1);
}

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;
use Test::Trap;

=name

Stencil::Log

=cut

=abstract

Represents a Stencil log file

=cut

=includes

method: debug
method: fatal
method: info
method: output
method: warn

=cut

=synopsis

  use Stencil::Log;
  use Stencil::Repo;

  my $repo = Stencil::Repo->new;

  $repo->store('logs')->mkpath;

  my $log = Stencil::Log->new(repo => $repo);

=cut

=libraries

Types::Standard

=cut

=attributes

repo: ro, req, Object
file: ro, opt, Object
handler: ro, opt, InstanceOf["FlightRecorder"]

=cut

=description

This package provides a class which represents a Stencil log file.

=cut

=method debug

The debug method proxies to L<FlightRecorder/debug> via the C<handler>
attribute.

=signature debug

debug(Str @args) : Any

=example-1 debug

  # given: synopsis

  $log->debug('debug message');

=cut

=method fatal

The fatal method proxies to L<FlightRecorder/fatal> via the C<handler>
attribute.

=signature fatal

fatal(Str @args) : Any

=example-1 fatal

  # given: synopsis

  $log->fatal('fatal message');

=cut

=method info

The info method proxies to L<FlightRecorder/info> via the C<handler> attribute.

=signature info

info(Str @args) : Any

=example-1 info

  # given: synopsis

  $log->info('info message');

=cut

=method output

The output method proxies to L<FlightRecorder/output> via the C<handler>
attribute.

=signature output

output() : Str

=example-1 output

  # given: synopsis

  $log->info('info message')->output;

=cut

=method warn

The warn method proxies to L<FlightRecorder/warn> the C<handler> attribute.

=signature warn

warn(Str @args) : Any

=example-1 warn

  # given: synopsis

  $log->warn('warn message');

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'debug', 'method', fun($tryable) {
  ok my $result = trap { $tryable->result };
  ok !$trap->stdout;

  $result
});

$subs->example(-1, 'fatal', 'method', fun($tryable) {
  ok my $result = trap { $tryable->result };
  like $trap->stdout, qr/[fatal] \w+/;

  $result
});

$subs->example(-1, 'info', 'method', fun($tryable) {
  ok my $result = trap { $tryable->result };
  like $trap->stdout, qr/[info] \w+/;

  $result
});

$subs->example(-1, 'output', 'method', fun($tryable) {
  ok my $result = trap { $tryable->result };
  like $trap->stdout, qr/[info] \w+/;

  $result
});

$subs->example(-1, 'warn', 'method', fun($tryable) {
  ok my $result = trap { $tryable->result };
  like $trap->stdout, qr/[warn] \w+/;

  $result
});

ok 1 and done_testing;
