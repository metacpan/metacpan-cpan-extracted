use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::LogErrors;

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

# a boring app that prints to psgi.errors and psgix.logger
sub app
{
    sub {
        my $env = shift;

        $env->{'psgix.logger'}->({
            level => 'info',
            message => 'PATH=' . $env->{PATH_INFO} . "\n",
        });
        $env->{'psgi.errors'}->print("oh noes!\n");

        [ 200, [], [ 'hello' ] ];
    };
}


subtest 'logger not something we know how to use (not a coderef)' => sub
{
    like(
        exception {
            Plack::Middleware::LogErrors->wrap(app,
                logger => bless({}, 'MyLogger'),
            );
        },
        qr/^'logger' is not a coderef!/,
        'bad logger parameter',
    );
};


# this is easy to occur if the middleware is applied in the wrong order -
# instead of silently falling back to psgi.errors (which means the application
# was a no-op), we'd rather know that we screwed up - ergo die.
subtest 'no psgix.logger configured' => sub
{
    my $app = Plack::Middleware::LogErrors->wrap(app);

    my $psgi_errors;
    $app = apply_mw(
        $app,
        'psgi.errors' => do { open my $io, '>>', \$psgi_errors; $io },
        # no psgix.logger
    );

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');

        is($psgi_errors, undef, 'we died before the app is called');

        is($res->code, 500, 'response code');
        like($res->content, qr/^no psgix\.logger in \$env; cannot map psgi\.errors to it!/, 'content');
    };
};


subtest 'default case: psgix.logger configured; no logger override' => sub
{
    my $app = Plack::Middleware::LogErrors->wrap(app);

    my $psgi_errors;
    my $psgix_log;
    $app = apply_mw(
        $app,
        'psgi.errors' => do { open my $io, '>>', \$psgi_errors; $io },
        'psgix.logger' => sub {
            my $args = shift;
            $psgix_log .= $args->{level} . ' -- ' . $args->{message};
        }
    );

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');

        is($psgi_errors, undef, 'original psgi.errors got no content');
        is($psgix_log, "info -- PATH=/hello\nerror -- oh noes!\n", 'logger got log message and error');

        is($res->code, 200, 'response code');
        is($res->content, 'hello', 'content');
    };
};


subtest 'psgix.logger configured, but we override error logger to something else' => sub
{
    my $error_logger;
    my $app = Plack::Middleware::LogErrors->wrap(app,
        logger => sub {
            my $args = shift;
            $error_logger .= $args->{level} . ' -- ' . $args->{message};
        }
    );

    my $psgi_errors;
    my $psgix_log;
    $app = apply_mw(
        $app,
        'psgi.errors' => do { open my $io, '>>', \$psgi_errors; $io },
        'psgix.logger' => sub {
            my $args = shift;
            $psgix_log .= $args->{level} . ' -- ' . $args->{message};
        }
    );

    test_psgi $app, sub {
        my $res = shift->(GET '/hello');

        is($psgi_errors, undef, 'original psgi.errors got no content');
        is($psgix_log, "info -- PATH=/hello\n", 'psgix.logger got normal log message');
        is($error_logger, "error -- oh noes!\n", 'custom error logger got error');

        is($res->code, 200, 'response code');
        is($res->content, 'hello', 'content');
    };
};

done_testing;
