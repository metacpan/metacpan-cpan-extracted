#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;
use Types::Standard qw(Int);

use PAGI::FastAPI::TypedPath qw(TypedPath);

# PAGI::FastAPI and PAGI::FastAPI::Depends are deliberately NOT use'd at file
# scope, they're require'd inside the one integration subtest that
# actually needs a full app. This means the direct unit tests above run and
# are meaningful even in an environment where the base PAGI framework isn't
# available; only the integration subtest needs it. In the real project
# environment both are present and everything runs as one normal file.

package MockContext {
    sub new ($class, %path_params) {
        return bless { status => 200, path_params => { %path_params } }, $class;
    }
    sub status     ($self, @args) { $self->{status} = $args[0] if @args; return $self->{status} }
    sub path_param ($self, $name) { return $self->{path_params}{$name} }
}

subtest 'Direct unit test: valid input passes through unchanged (no coercion by default)' => sub {
    my $dep = TypedPath('item_id', Int);
    my $c   = MockContext->new(item_id => '42');
    my $res = $dep->($c)->get;

    is($res, '42', 'validated but still a plain string, Int without coercion does not numify');
    is($c->status, 200, 'status untouched on success');
};

subtest 'Direct unit test: invalid input -> 422 with a clear detail message' => sub {
    my $dep = TypedPath('item_id', Int);
    my $c   = MockContext->new(item_id => 'not-a-number');
    my $res = $dep->($c)->get;

    is($c->status, 422, 'matches core\'s own validation-failure status for query/body');
    like($res->{detail}, qr/Path parameter 'item_id' invalid/, 'detail names the specific parameter');
};

subtest 'Direct unit test: a coercing type actually transforms the value' => sub {
    my $CoercingInt = Int->plus_coercions(Types::Standard::Str, sub { $_ + 0 });
    my $dep = TypedPath('item_id', $CoercingInt);
    my $c   = MockContext->new(item_id => '99');
    my $res = $dep->($c)->get;

    is($res, 99, 'coerced to a real number');
    ok(!ref($res), 'still a plain scalar, not a reference');
    cmp_ok($res, '==', 99, 'numeric comparison works, confirming it is actually a number not just a numeric-looking string');
};

# The integration test below needs a full PAGI::FastAPI app. require() (not
# use) so this executes at runtime, in order, same as any other statement,
# unlike a nested 'async sub' inside a subtest's anonymous sub, declaring
# call_app here at file scope (guarded by an ordinary if) means Perl's
# closure-availability analysis has nothing ambiguous to warn about, and it
# matches the same file-scope call_app pattern t/12-rate_limit.t and
# t/25-middleware_exception_handler.t already use.

my $PAGI_FASTAPI_AVAILABLE = eval {
    require PAGI::FastAPI;
    require PAGI::FastAPI::Depends;
    PAGI::FastAPI::Depends->import(qw(Depends));
    1;
};

my $pagi_unavailable_reason = $@;

my ($pagi_fn, $call_app);

if ($PAGI_FASTAPI_AVAILABLE) {
    my $app = PAGI::FastAPI->new(title => 'TypedPath Integration Test');

    $app->get('/items/{item_id}',
        dependencies => [
            Depends(TypedPath('item_id', Int), key => 'item_id'),
        ],
        handler => async sub ($c) {
            return {
                item_id => $c->stash->{item_id},
                doubled => $c->stash->{item_id} * 2
            };
        },
    );

    $pagi_fn = $app->to_app;

    $call_app = async sub ($path) {
        my %res_data;
        my $scope = {
            type    => 'http',
            method  => 'GET',
            path    => $path,
            headers => [],
            client  => ['127.0.0.1', 12345],
        };
        my $send = async sub ($msg) {
            if ($msg->{type} eq 'http.response.start') {
                $res_data{status} = $msg->{status};
            } elsif ($msg->{type} eq 'http.response.body') {
                $res_data{body} = $msg->{body};
            }
        };
        my $receive = async sub { return { type => 'http.disconnect' } };
        await $pagi_fn->($scope, $receive, $send);
        return \%res_data;
    };
}

subtest 'Integration: threaded through the real Depends() + app dispatch, short-circuits on invalid input' => sub {
    plan skip_all => "PAGI::FastAPI not available: $pagi_unavailable_reason"
        unless $PAGI_FASTAPI_AVAILABLE;

    my $ok = $call_app->('/items/21')->get;
    is($ok->{status}, 200, 'valid numeric path param succeeds');
    like($ok->{body}, qr/"doubled":42/, 'the handler received the validated value via $c->stash and could use it');

    my $blocked = $call_app->('/items/not-a-number')->get;
    is($blocked->{status}, 422, 'invalid path param short-circuits via core\'s real dependency-execution loop, never reaching the handler');
    like($blocked->{body}, qr/Path parameter 'item_id' invalid/, 'the 422 body is the one TypedPath produced, not a generic core fallback');
};

done_testing;
