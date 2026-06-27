use strict;
use warnings;
use Test2::V0;
use Future;
use Scalar::Util qw(refaddr);
use PAGI::Context;

# Each case needs its own context: respond() is guarded (one response/request).
sub ctx_with_recorder {
    my @events;
    my $send = sub { push @events, $_[0]; Future->done };
    my $scope = { type => 'http', method => 'GET', headers => [], path => '/' };
    my $ctx = PAGI::Context->new($scope, sub { Future->done }, $send);
    return ($ctx, \@events);
}

sub headers_of { my $e = shift; map { lc($_->[0]) => $_->[1] } @{ $e->{headers} } }

subtest 'text() returns a Response value sent as text/plain' => sub {
    my ($ctx, $events) = ctx_with_recorder();
    my $res = $ctx->text('Hello, world!');
    isa_ok($res, ['PAGI::Response'], 'text returns a PAGI::Response');
    $ctx->respond($res)->get;
    is($events->[0]{status}, 200, 'default status 200');
    my %h = headers_of($events->[0]);
    like($h{'content-type'}, qr{text/plain}, 'text/plain content-type');
    is($events->[1]{body}, 'Hello, world!', 'text body');
};

subtest 'html() returns text/html' => sub {
    my ($ctx, $events) = ctx_with_recorder();
    $ctx->respond($ctx->html('<h1>Hi</h1>'))->get;
    my %h = headers_of($events->[0]);
    like($h{'content-type'}, qr{text/html}, 'text/html content-type');
    like($events->[1]{body}, qr{<h1>Hi</h1>}, 'html body');
};

subtest 'json() with opts sets body, content-type, and status' => sub {
    my ($ctx, $events) = ctx_with_recorder();
    my $res = $ctx->json({ ok => 1 }, status => 201);
    isa_ok($res, ['PAGI::Response'], 'json returns a PAGI::Response');
    $ctx->respond($res)->get;
    is($events->[0]{status}, 201, 'status from opts');
    my %h = headers_of($events->[0]);
    like($h{'content-type'}, qr{application/json}, 'json content-type');
    like($events->[1]{body}, qr/"ok"\s*:\s*1/, 'json body');
};

subtest 'redirect() sets status and location' => sub {
    my ($ctx, $events) = ctx_with_recorder();
    $ctx->respond($ctx->redirect('/login'))->get;
    is($events->[0]{status}, 302, 'default redirect status 302');
    my %h = headers_of($events->[0]);
    is($h{location}, '/login', 'location header');
};

subtest 'sugar operates on the one cached response accumulator' => sub {
    my ($ctx) = ctx_with_recorder();
    is(refaddr($ctx->text('a')), refaddr($ctx->response),
        'sugar returns the context\'s cached response');
};

done_testing;
