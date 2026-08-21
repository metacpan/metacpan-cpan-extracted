#!/usr/bin/env perl

use v5.38;
use Test::More;
use Test::Fatal qw(exception);
use Future::AsyncAwait;

use PAGI::FastAPI;
use PAGI::FastAPI::Middleware::ExceptionHandler;

package My::Errors::NotFound {
    sub new     ($class, %args) { return bless { %args }, $class         }
    sub message ($self)         { return $self->{message} // 'Not Found' }
}

package My::Errors::BadInput {
    sub new     ($class, %args) { return bless { %args }, $class         }
    sub message ($self)         { return $self->{message} // 'Bad Input' }
}

my $exc_handler = PAGI::FastAPI::Middleware::ExceptionHandler->new(
    handlers => {
        'My::Errors::NotFound' => async sub ($err, $c) {
            $c->status(404);
            return { detail => $err->message };
        },
        '' => async sub ($err, $c) {   # plain-string die()
            $c->status(400);
            return { detail => "$err" };
        },
    },
    default_handler => async sub ($err, $c) {
        $c->status(500);
        return { detail => 'Internal Server Error' };
    },
);

my $app = PAGI::FastAPI->new(title => 'Exception Handler Test');

$app->add_middleware(async sub ($c, $next) {
    return await $exc_handler->handle($c, $next);
});

$app->get('/not-found', handler => async sub ($c) {
    die My::Errors::NotFound->new(message => 'No such widget');
});

$app->get('/bad-string', handler => async sub ($c) {
    die "plain string failure\n";
});

$app->get('/unregistered', handler => async sub ($c) {
    die My::Errors::BadInput->new(message => 'should hit default_handler');
});

$app->get('/ok', handler => async sub ($c) {
    return { ok => 1 };
});

my $pagi_fn = $app->to_app;

async sub call_app ($path) {
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
            $res_data{status}  = $msg->{status};
            $res_data{headers} = { map { $_->[0] => $_->[1] } @{$msg->{headers}} };
        } elsif ($msg->{type} eq 'http.response.body') {
            $res_data{body} = $msg->{body};
        }
    };

    my $receive = async sub { return { type => 'http.disconnect' } };

    await $pagi_fn->($scope, $receive, $send);
    return \%res_data;
}

subtest 'Registered exception class is dispatched to its handler' => sub {
    my $res = call_app('/not-found')->get;
    is($res->{status}, 404, 'status set by the matched handler');
    like($res->{body}, qr/No such widget/, 'body reflects the handler-produced detail');
};

subtest 'Plain string die() is caught by the empty-string handler' => sub {
    my $res = call_app('/bad-string')->get;
    is($res->{status}, 400, 'status set by the "" handler');
    like($res->{body}, qr/plain string failure/, 'body reflects the exception text');
};

subtest 'Unregistered exception class falls back to default_handler' => sub {
    my $res = call_app('/unregistered')->get;
    is($res->{status}, 500, 'default_handler status used');
    like($res->{body}, qr/Internal Server Error/, 'default_handler body used, not the specific exception message');
};

subtest 'No exception thrown -> request succeeds normally' => sub {
    my $res = call_app('/ok')->get;
    is($res->{status}, 200, 'unrelated success path is unaffected by the middleware');
};

subtest 'No handler and no default_handler re-throws' => sub {
    my $strict = PAGI::FastAPI::Middleware::ExceptionHandler->new(handlers => {});
    # A minimal stand-in context is enough here since handle() only needs
    # ->status, and the thrown exception is unmatched so no user handler
    # actually touches $c for anything else, perform ->handle directly
    # rather than through a full app for this one case.
    package MockContext {
        sub new    ($class) { return bless { status => 200 }, $class }
        sub status ($self, @args) { $self->{status} = $args[0] if @args; return $self->{status} }
    }
    my $c    = MockContext->new;
    my $next = async sub ($c) { die "nobody handles this\n" };

    my $err = exception { $strict->handle($c, $next)->get };
    like($err, qr/nobody handles this/, 'unmatched exception with no default_handler propagates rather than being swallowed');
};

done_testing;
