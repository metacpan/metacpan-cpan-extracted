use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::LogStderr;
use Capture::Tiny 'capture_stderr';

# given an $app, apply middleware to mutate $env->{$key} to $value.
sub apply_mw
{
    my ($app, %mutations) = @_;

    sub {
        my $env = shift;
        @{$env}{keys %mutations} = values %mutations;
        $app->($env);
    };
}

# a boring app that prints to STDERR
sub app
{
    sub {
        my $env = shift;
        
        print STDERR "foo|";
        system('perl -e " print STDERR \'bar|\'"');
        printf STDERR "%s|", "baz";
        $env->{'psgi.errors'}->print('qux|');
        capture_stderr { print STDERR "ignore"; };
        
        [ 200, [], [ 'hello' ] ];
    };
}

sub c1 {
    my $msg = shift;
    return "stderr:$msg";
}

sub c2 {
    my $msg = shift;
    return "capture{$msg}";
}
sub c3 {
    my $msg = shift;
    return "log:$msg";
}

sub get_logger {
    my $logref = shift;
    return sub {
            my $args = shift;
            $$logref .= $args->{level} . ' -- ' . $args->{message} ;
        }
}

subtest 'param not something we know how to use (not a coderef)' => sub
{
    foreach my $param (qw/logger callback tie_callback capture_callback/) {
        like(
            exception {
                Plack::Middleware::LogStderr->wrap(app,
                    $param => bless({}, 'MyParam'),
                );
            },
            qr/^'$param' is not a coderef!/,
            "bad $param parameter",
        );
        like(
            exception {
                Plack::Middleware::LogStderr->wrap(app,
                    $param => 'MyParam',
                );
            },
            qr/^'$param' is not a coderef!/,
            "bad $param parameter",
        );
        like(
            exception {
                Plack::Middleware::LogStderr->wrap(app,
                    $param => 47,
                );
            },
            qr/^'$param' is not a coderef!/,
            "bad $param parameter",
        );
    }
};

# this is easy to occur if the middleware is applied in the wrong order -
# instead of silently falling back to psgi.errors (which means the application
# was a no-op), we'd rather know that we screwed up - ergo die.
subtest 'no psgix.logger configured' => sub
{
    my $app = Plack::Middleware::LogStderr->wrap(app);

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');

        is($res->code, 500, 'response code');
        like($res->content, qr/^no psgix\.logger in \$env; cannot send STDERR to it!/, 'content');
    };
};


subtest 'default case: psgix.logger configured; no logger override' => sub
{
    my $app = Plack::Middleware::LogStderr->wrap(app);

    my $psgix_log;
    $app = apply_mw(
        $app,
        'psgix.logger' => get_logger(\$psgix_log)
    );

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');

        is($psgix_log, "error -- foo|error -- baz|error -- qux|error -- bar|", 'logger got log message and error');

        is($res->code, 200, 'response code');
        is($res->content, 'hello', 'content');
    };
};


subtest 'psgix.logger configured; no logger override; no_tie ' => sub
{
    my $app = Plack::Middleware::LogStderr->wrap(app, no_tie => 1);

    my $psgix_log;
    $app = apply_mw(
        $app,
        'psgix.logger' => get_logger(\$psgix_log)
    );

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');

        is($psgix_log, "error -- foo|bar|baz|qux|", 'logger got log message and error');

        is($res->code, 200, 'response code');
        is($res->content, 'hello', 'content');
    };
};

subtest 'psgix.logger configured, but we override error logger to something else' => sub
{
    my $error_logger;
    my $app = Plack::Middleware::LogStderr->wrap(app,
        logger => get_logger(\$error_logger)
    );

    my $psgix_log;
    $app = apply_mw(
        $app,
        'psgix.logger' => get_logger(\$psgix_log)
    );

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');
        is($psgix_log, undef, 'original logger got no content');
        is($error_logger, "error -- foo|error -- baz|error -- qux|error -- bar|", 'logger got log message and error');

        is($res->code, 200, 'response code');
        is($res->content, 'hello', 'content');
    };
};

subtest 'psgix.logger configured, callbacks, log_level' => sub
{
    my $app = Plack::Middleware::LogStderr->wrap(app,
        callback => \&c3,
        tie_callback => \&c1,
        capture_callback => \&c2,
        log_level => 'info'
    );

    my $psgix_log;
    $app = apply_mw(
        $app,
        'psgix.logger' => get_logger(\$psgix_log)
    );

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');

        is($psgix_log, "info -- stderr:log:foo|info -- stderr:log:baz|info -- stderr:log:qux|info -- capture{log:bar|}", 'logger got log message - info');

        is($res->code, 200, 'response code');
        is($res->content, 'hello', 'content');
    };
};

subtest 'psgix.logger configured, callbacks, log_level, log_level_capture' => sub
{
    my $app = Plack::Middleware::LogStderr->wrap(app,
        callback => \&c3,
        tie_callback => \&c1,
        capture_callback => \&c2,
        log_level => 'info',
        log_level_capture => 'warn'
    );

    my $psgix_log;
    $app = apply_mw(
        $app,
        'psgix.logger' => get_logger(\$psgix_log)
    );

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');

        is($psgix_log, "info -- stderr:log:foo|info -- stderr:log:baz|info -- stderr:log:qux|warn -- capture{log:bar|}", 'logger got log message info and warn');

        is($res->code, 200, 'response code');
        is($res->content, 'hello', 'content');
    };
};

subtest 'psgix.logger configured, callbacks; notie' => sub
{
    my $app = Plack::Middleware::LogStderr->wrap(app,
        callback => \&c3,
        tie_callback => \&c1,
        capture_callback => \&c2,
        no_tie => 1
    );

    my $psgix_log;
    $app = apply_mw(
        $app,
        'psgix.logger' => get_logger(\$psgix_log) 
    );

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');

        is($psgix_log, "error -- capture{log:foo|bar|baz|qux|}", 'logger got log message and error');

        is($res->code, 200, 'response code');
        is($res->content, 'hello', 'content');
    };
};

done_testing;
