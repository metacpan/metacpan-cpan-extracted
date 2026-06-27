use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

# A class-based router whose METHOD middleware are value-flow.
{ package T::MW; use parent 'PAGI::Endpoint::Router'; use Future::AsyncAwait;
  sub routes {
      my ($self, $r) = @_;
      $r->get('/decorate' => ['stamp'] => 'show');
      $r->get('/deny'     => ['gate']  => 'show');
      $r->get('/observe'  => ['watch'] => 'show');
      $r->get('/forgot'   => ['bad']   => 'show');
  }
  async sub show  { my ($self, $ctx) = @_; return $ctx->response->status(201)->text('ok') }

  # decorate the handler's response on the way up
  async sub stamp { my ($self, $ctx, $next) = @_; my $res = await $next->(); $res->header('X-Stamp' => 'yes'); return $res }
  # short-circuit: never call $next, return our own response
  async sub gate  { my ($self, $ctx, $next) = @_; return $ctx->response->status(403)->text('no') }
  # observe: read the response, record it into a header, pass through
  async sub watch { my ($self, $ctx, $next) = @_; my $res = await $next->(); $res->header('X-Seen' => $res->status); return $res }
  # bug: forgets to return the response
  async sub bad   { my ($self, $ctx, $next) = @_; await $next->(); return }
}

# A router that puts a STANDARD (coderef) middleware in a route array — rejected.
{ package T::BadMW; use parent 'PAGI::Endpoint::Router'; use Future::AsyncAwait;
  sub routes { my ($self, $r) = @_; $r->get('/x' => [ sub { } ] => 'show'); }
  async sub show { my ($self, $ctx) = @_; return $ctx->response->text('ok') }
}

sub recorder { my @e; my $s = sub { push @e, $_[0]; Future->done }; return ($s, \@e) }
sub headers_of { my $e = shift; return map { lc($_->[0]) => $_->[1] } @{$e->{headers}} }

subtest 'middleware decorates the response on the way up' => sub {
    my $app = T::MW->to_app;
    my ($send, $events) = recorder();
    $app->({ type => 'http', method => 'GET', path => '/decorate' }, sub { Future->done }, $send)->get;
    is $events->[0]{status}, 201, 'handler status preserved';
    my %h = headers_of($events->[0]);
    is $h{'x-stamp'}, 'yes', 'middleware added a header to the handler response';
};

subtest 'middleware short-circuits by returning its own response' => sub {
    my $app = T::MW->to_app;
    my ($send, $events) = recorder();
    $app->({ type => 'http', method => 'GET', path => '/deny' }, sub { Future->done }, $send)->get;
    is $events->[0]{status}, 403, 'short-circuit response was sent';
    like $events->[1]{body}, qr/no/, 'short-circuit body';
};

subtest 'middleware observes the handler response' => sub {
    my $app = T::MW->to_app;
    my ($send, $events) = recorder();
    $app->({ type => 'http', method => 'GET', path => '/observe' }, sub { Future->done }, $send)->get;
    my %h = headers_of($events->[0]);
    is $h{'x-seen'}, 201, 'middleware saw the handler status on the way up';
};

subtest 'middleware that forgets to return is a loud error' => sub {
    my $app = T::MW->to_app;
    my ($send, $events) = recorder();
    like dies { $app->({ type => 'http', method => 'GET', path => '/forgot' }, sub { Future->done }, $send)->get },
        qr/did not return a response/, 'forgot-to-return croaks';
};

subtest 'standard middleware in a route array is rejected' => sub {
    like dies { T::BadMW->to_app },
        qr/mount or group/, 'coderef route middleware is rejected with guidance';
};

done_testing;
