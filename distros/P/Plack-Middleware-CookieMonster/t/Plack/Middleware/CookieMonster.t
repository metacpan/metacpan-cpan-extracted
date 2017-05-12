use Test::Most;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

BEGIN {
    use_ok 'Plack::Middleware::CookieMonster';
}

test__get_cookie_names();
test_no_stacktrace();
test_stacktrace_no_param();
test_stacktrace_with_names();
test_stacktrace_with_names_and_path();
test_stacktrace_with_path();

done_testing;

sub test__get_cookie_names {
    # No cookie names configured:
    my $monster = Plack::Middleware::CookieMonster->new;
    my @cookies = $monster->_get_cookie_names( {} );
    is scalar @cookies, 0, 'no cookie returned as none were sent';

    @cookies = $monster->_get_cookie_names( { HTTP_COOKIE => 'foo=bar' } );
    is scalar @cookies, 1, 'one sent, one to be expired';

    @cookies = $monster->_get_cookie_names( { HTTP_COOKIE => 'foo=123; bar=456' } );
    is scalar @cookies, 2, 'two sent, two to be expired';

    # a cookie name is configured:
    $monster = Plack::Middleware::CookieMonster->new( cookie_names => [ qw/ testcookie / ] );
    @cookies = $monster->_get_cookie_names( {} );
    is scalar @cookies, 0, 'no cookie returned as none were sent';

    @cookies = $monster->_get_cookie_names( { HTTP_COOKIE => 'foo=bar' } );
    is scalar @cookies, 0, 'no cookies to be expired because the one sent was not configured';

    @cookies = $monster->_get_cookie_names( { HTTP_COOKIE => 'foo=123; testcookie=456' } );
    is scalar @cookies, 1, 'two sent, one to be expired';

    # tow cookie names are configured:
    $monster = Plack::Middleware::CookieMonster->new( cookie_names => [ qw/ testcookie test2cookie / ] );
    @cookies = $monster->_get_cookie_names( {} );
    is scalar @cookies, 0, 'no cookie returned as none were sent';

    @cookies = $monster->_get_cookie_names( { HTTP_COOKIE => 'foo=bar' } );
    is scalar @cookies, 0, 'no cookies to be expired because the one sent was not configured';

    @cookies = $monster->_get_cookie_names( { HTTP_COOKIE => 'foo=123; testcookie=456' } );
    is scalar @cookies, 1, 'two sent, one to be expired';

    @cookies = $monster->_get_cookie_names( { HTTP_COOKIE => 'test2cookie=123; testcookie=456' } );
    is scalar @cookies, 2, 'two sent, two to be expired';
}

sub _get_app {
    return sub {
        my $env = shift;
        if ( $env->{ PATH_INFO } ne '/nocrash' ) {
            die 'oopsie';
        }

        return [
            200, [ 'Content-Type' => 'text/html', 'Set-Cookie', 'sessionid=2345678' ],
            ['<body>Hello World</body>']
        ];
    };
}

sub _get_streaming_app {
    return sub {
        my $env = shift;

        return sub {
            my $respond = shift;
            if ( $env->{ PATH_INFO } ne '/nocrash' ) {
                eval { require DooBar };
            }
            $respond->(
                [
                    200,
                    [ 'Content-Type' => 'text/html', 'Set-Cookie', 'sessionid=2345678' ],
                    [ '<body>Hello World</body>' ]
                ]
            );
        };
    };
}

sub test_no_stacktrace {
    foreach my $inner_app ( _get_app, _get_streaming_app ) {
        my $app = builder {
            enable 'StackTrace';
            $inner_app;
        };

        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->( GET '/nocrash', 'Cookie' => 'sessionid=1234567' );
            is $res->code, 200, 'response status 200';
            is $res->header( 'Set-Cookie' ), 'sessionid=2345678', 'app sets a cookie';
        };
    }
}

sub test_stacktrace_no_param {
    my $app = builder {
        enable 'CookieMonster';
        enable 'StackTrace', force => 1, no_print_errors => 1;
        _get_app;
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET '/', 'Cookie' => 'sessionid=1234567' );
        is $res->code, 500, 'response status 500';
        is
            $res->header( 'Set-Cookie' ),
            'sessionid=deleted; Expires=Sat, 01-May-1971 04:30:01 GMT',
            'cookie deleted';
    };
}

sub test_stacktrace_with_names {
    my $app = builder {
        enable 'CookieMonster', cookie_names => [ 'sid' ];
        enable 'StackTrace', force => 1, no_print_errors => 1;
        _get_app;
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET '/', 'Cookie' => 'sessionid=1234567' );
        is $res->code, 500, 'response status 500';
        is $res->header( 'Set-Cookie' ), undef, 'no cookie';
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET '/', 'Cookie' => 'sessionid=1234567; sid=112233' );
        is $res->code, 500, 'response status 500';
        is $res->header( 'Set-Cookie' ), 'sid=deleted; Expires=Sat, 01-May-1971 04:30:01 GMT', 'configured cookie gets expired';
    };
}

sub test_stacktrace_with_names_and_path {
    my $app = builder {
        enable 'CookieMonster', path => '/some/path', cookie_names => [ 'sid' ];
        enable 'StackTrace', force => 1, no_print_errors => 1;
        _get_app;
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET '/', 'Cookie' => 'sessionid=1234567; sid=112233' );
        is $res->code, 500, 'response status 500';
        is $res->header( 'Set-Cookie' ), 'sid=deleted; path=/some/path; Expires=Sat, 01-May-1971 04:30:01 GMT', 'configured cookie gets expired';
    };
}

sub test_stacktrace_with_path {
    my $app = builder {
        enable 'CookieMonster', path => '/some/path';
        enable 'StackTrace', force => 1, no_print_errors => 1;
        _get_app;
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET '/', 'Cookie' => 'sessionid=1234567; sid=112233' );
        is $res->code, 500, 'response status 500';
        like $res->header( 'Set-Cookie' ), qr'sid=deleted; path=/some/path; Expires=Sat, 01-May-1971 04:30:01 GMT', 'sent cookie gets expired';
        like $res->header( 'Set-Cookie' ), qr'sessionid=deleted; path=/some/path; Expires=Sat, 01-May-1971 04:30:01 GMT', 'sent cookie gets expired';
    };
}

