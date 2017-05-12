# This was cribbed from t/Plack-Middleware/log_dispatch.t from core Plack.
use strict;
use warnings;
use Plack::Test;
use Test::More;
use Test::Deep;
use Plack::Middleware::LogDispatchouli;
use HTTP::Request::Common;
use Log::Dispatchouli;

package Stringify;
use overload q{""} => sub { 'stringified object' };
sub new { bless {}, shift }

package main;

my @loggers = (
    Log::Dispatchouli->new_tester({ ident => "test" }),
    {
        ident   => "test",
        to_self => 1,
        log_pid => 0,
    },
);

my $app = sub {
    my $env = shift;
    $env->{'psgix.logger'}->({ level => "debug", message => "This is debug" });
    $env->{'psgix.logger'}->({ level => "info", message => sub { 'code ref' } });
    $env->{'psgix.logger'}->({ level => "notice", message => Stringify->new() });
    $env->{'psgix.logger'}->({ level => "fatal", message => "This is fatal" });
    $env->{'psgix.logger'}->({ level => "info", message => "This never shows up" });

    return [ 200, [], [] ];
};

for my $logger (@loggers) {
    my $mw = Plack::Middleware::LogDispatchouli->new( logger => $logger );

    test_psgi $mw->wrap($app), sub {
        my $cb = shift;
        my $res = $cb->(GET "/");

        my $logs = $mw->logger->events;

        cmp_deeply $logs, [
            { name => ignore(), level => 'debug',  message => 'This is debug' },
            { name => ignore(), level => 'info',   message => 'code ref' },
            { name => ignore(), level => 'notice', message => 'stringified object' },
            { name => ignore(), level => 'error',  message => 'This is fatal' },
        ];
    };
}

done_testing;
