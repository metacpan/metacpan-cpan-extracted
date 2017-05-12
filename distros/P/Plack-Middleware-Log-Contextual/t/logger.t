use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = sub {
    my $env = shift;
    use Log::Contextual qw(:log);

    if ($env->{PATH_INFO} eq '/streaming') {
        return sub {
            my $r = shift;
            log_fatal { "Streaming foo" };
            $r->([ 200, [ 'Content-Type', 'text/plain' ], [ "Hello" ]  ]);
        };
    }

    log_fatal { "Foo" };
    log_debug { "debugging" };

    return [ 200, [ 'Content-Type', 'text/plain' ], [ "Hello" ] ];
};

# standalone
use Log::Contextual::SimpleLogger;
my @logs;
my $logger = Log::Contextual::SimpleLogger->new({
    coderef => sub { push @logs, @_ },
    levels => [qw(info fatal)],
});

my $standalone = builder {
    enable "Log::Contextual", logger => $logger;
    $app;
};

test_psgi $standalone, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->code, 200;

    is @logs, 1;
    is $logs[0], "[fatal] Foo\n";

    @logs = ();
    $res = $cb->(GET "/streaming");
    is $res->code, 200;
    is $res->content, "Hello";

    is @logs, 1;
    is $logs[0], "[fatal] Streaming foo\n";
};

# PSGI logger
@logs = ();
my $psgi = builder {
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            $env->{'psgix.logger'} = sub { push @logs, @_ };
            $app->($env);
        };
    };
    enable "Log::Contextual";
    $app;
};

test_psgi $psgi, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->code, 200;

    is @logs, 2;
    is_deeply $logs[0], { level => "fatal", message=> "Foo" };
    is_deeply $logs[1], { level => "debug", message=> "debugging" };
};

done_testing;

