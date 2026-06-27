use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::Context;
use PAGI::Response;

sub recorder { my @e; my $s = sub { push @e, $_[0]; Future->done }; return ($s, \@e) }

subtest 'ctx->response is a detached accumulator; ctx->respond sends it' => sub {
    my ($send, $events) = recorder();
    my $ctx = PAGI::Context->new({ type => 'http', method => 'GET' }, sub { Future->done }, $send);
    my $res = $ctx->response->status(201)->json({ ok => 1 });
    ref_is $ctx->response, $res, 'response cached (same object across calls)';
    $ctx->respond($res)->get;
    is $events->[0]{status}, 201, 'sent with status';
    like $events->[1]{body}, qr/ok/, 'sent body';
};

subtest 'ctx->respond guards double-send' => sub {
    my ($send, $events) = recorder();
    my $ctx = PAGI::Context->new({ type => 'http' }, sub { Future->done }, $send);
    $ctx->respond($ctx->response->text('one'))->get;
    like dies { $ctx->respond(PAGI::Response->text('two'))->get },
        qr/already sent/, 'second respond on same request dies';
};

done_testing;
