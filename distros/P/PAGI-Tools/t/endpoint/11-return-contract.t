use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

{ package T::Ep; use parent 'PAGI::Endpoint::HTTP'; use Future::AsyncAwait;
  async sub get { my ($self, $ctx) = @_; return $ctx->response->status(200)->json({ hi => 1 }) } }
{ package T::Void; use parent 'PAGI::Endpoint::HTTP'; use Future::AsyncAwait;
  async sub get { my ($self, $ctx) = @_; return } }
{ package T::Count; use parent 'PAGI::Endpoint::HTTP'; use Future::AsyncAwait;
  async sub get { my ($self, $ctx) = @_; $self->{n}++; return $ctx->response->text("n=$self->{n}") } }

sub recorder { my @e; my $s = sub { push @e, $_[0]; Future->done }; return ($s, \@e) }

subtest 'HTTP endpoint sends the returned response value' => sub {
    my $app = T::Ep->to_app;
    my ($send, $events) = recorder();
    $app->({ type => 'http', method => 'GET' }, sub { Future->done }, $send)->get;
    is $events->[0]{status}, 200, 'returned value was sent';
    like $events->[1]{body}, qr/hi/, 'body';
};

subtest 'handler returning nothing croaks' => sub {
    my $app = T::Void->to_app;
    my ($send, $events) = recorder();
    like dies { $app->({ type => 'http', method => 'GET' }, sub { Future->done }, $send)->get },
        qr/did not return a response/, 'no-return is a loud error';
};

subtest '405 for unhandled method, with Allow' => sub {
    my $app = T::Ep->to_app;
    my ($send, $events) = recorder();
    $app->({ type => 'http', method => 'POST' }, sub { Future->done }, $send)->get;
    is $events->[0]{status}, 405, '405 method not allowed';
    my %h = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    like $h{allow}, qr/GET/, 'Allow lists GET';
};

subtest 'OPTIONS auto Allow' => sub {
    my $app = T::Ep->to_app;
    my ($send, $events) = recorder();
    $app->({ type => 'http', method => 'OPTIONS' }, sub { Future->done }, $send)->get;
    my %h = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    like $h{allow}, qr/GET/, 'OPTIONS lists Allow';
};

subtest 'singleton instance persists across requests' => sub {
    my $app = T::Count->to_app;
    my ($s1, $e1) = recorder();
    $app->({ type => 'http', method => 'GET' }, sub { Future->done }, $s1)->get;
    my ($s2, $e2) = recorder();
    $app->({ type => 'http', method => 'GET' }, sub { Future->done }, $s2)->get;
    is $e1->[1]{body}, 'n=1', 'first request';
    is $e2->[1]{body}, 'n=2', 'second request reuses the same instance (singleton)';
};

done_testing;
