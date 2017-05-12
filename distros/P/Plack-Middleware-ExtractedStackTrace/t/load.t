use strict;
use warnings;

use Test::More;

use Carp qw( confess );
use Exception::Class ('Exploder');
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Middleware::ExtractedStackTrace;
use Plack::Test;
use Try::Tiny qw( catch try );

my $success_handler = builder {
    enable 'Plack::Middleware::ExtractedStackTrace';

    sub {
        [ 200, [ 'Content-Type' => 'text/plain' ], ['OK'] ];
    };
};

my $exception_handler = builder {
    enable 'Plack::Middleware::ExtractedStackTrace';

    sub {
        confess 'oof';
    };
};

my $exception_with_stack_trace_handler = builder {
    enable 'Plack::Middleware::ExtractedStackTrace';

    sub {
        my $exc;
        try { Exploder->throw( error => 'i am exploding' ) }
        catch { $exc = $_ };
        return $exc;
    };
};

test_psgi(
    app    => $success_handler,
    client => sub {
        my $cb  = shift;
        my $res = $cb->( GET 'http://localhost/' );
        is( $res->code, 200, 'success' );
    },
);

test_psgi(
    app    => $exception_handler,
    client => sub {
        my $cb  = shift;
        my $res = $cb->( GET 'http://localhost/' );
        is( $res->code, 500, '500 on exception' );
        like( $res->content, qr{oof}, 'original die message in body' );
        like(
            $res->content,
            qr{no stack trace was captured},
            'no stack trace found'
        );
    },
);

test_psgi(
    app    => $exception_with_stack_trace_handler,
    client => sub {
        my $cb  = shift;
        my $res = $cb->( GET 'http://localhost/' );
        is( $res->code, 500, '500 on exception with stack trace' );
        like(
            $res->content, qr{i am exploding},
            'original die message in body'
        );
        unlike(
            $res->content,
            qr{no stack trace was captured},
            'stack trace found'
        );
    },
);

done_testing();
