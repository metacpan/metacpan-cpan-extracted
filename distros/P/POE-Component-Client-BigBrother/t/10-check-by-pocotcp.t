#!perl -T
use strict;
use warnings;
use POE qw< Component::Server::TCP >;
use Test::More;


my $module = "POE::Component::Client::BigBrother";

my $now = time();
my $host = "localhost";
my @received;
my @results;
my @input = (
    {
        command_type    => "status",
        command_fields  => {
            host        => "front01.domain.net",
            service     => "cpu",
            color       => "red",
            message     => "load average is 105.45",
        },
    },
    {
        command_type    => "page",
        command_fields  => {
            host        => "front02.domain.net",
            service     => "sync",
            color       => "red",
            offset      => 10,
            message     => "files not synchronised",
        },
    },
    {
        command_type    => "disable",
        command_fields  => {
            host        => "front05.domain.net",
            service     => "cpu",
            duration    => 3600,
            message     => "temporary high load",
        },
    },
    {
        command_type    => "event",
        command_fields  => {
            host        => "front04.domain.net",
            service     => "logs",
            id          => "d41d8cd98",
            message     => "postfix/sendmail[32140]: fatal: no login name "
                         . "found for user ID 1064",
            color       => "red",
            activation  => $now,
            persistence => "eph",
        },
    },
);

my @expected = (
    "status front01,domain,net.cpu red load average is 105.45",
    "page+10 front02,domain,net.sync red files not synchronised",
    "disable front05,domain,net.cpu 3600 temporary high load",
    "event\nactivation: $now\ncolor: red\nhost: front04.domain.net\n"
        . "id: d41d8cd98\nmessage: postfix/sendmail[32140]: fatal: no"
        . " login name found for user ID 1064\npersistence: eph\n"
        . "service: logs\n",
);


plan tests => 1 + 4 * @input;

use_ok($module);



# POE session mocking a Big Brother server
POE::Component::Server::TCP->new(
    Hostname     => $host,
    Port         => 1984,
    ClientFilter => "POE::Filter::Stream",

    Started => sub {},

    ClientConnected => sub {
        # reset buffer on client connection
        $_[HEAP]->{buffer} = "";
    },

    ClientInput => sub {
        # accumulate data
        $_[HEAP]->{buffer} .= $_[ARG0];
    },

    ClientDisconnected => sub {
        my ($kernel, $heap) = @_[ KERNEL, HEAP ];
        push @received, $heap->{buffer};
    },
);

POE::Session->create(
    inline_states => {
        _start => sub {
            my $i = 0;
            for my $cmd (@input) {
                eval {
                    $module->send(
                        host    => $host,
                        event   => "_result",
                        context => $i++,
                        %$cmd,
                    );
                };
                is( $@, "", "$module->send()" );
            }

            $_[KERNEL]->delay(_stop => 1);
        },

        _stop => sub {
            POE::Kernel->stop
        },

        _result => sub {
            my $i = $_[ARG0]{context};
            $results[$i] = $_[ARG0];
        },
    },
);

POE::Kernel->run;

# clean up the received data from CRLF
s/\x0d\x0a$//g for @received;

for my $i (0..$#input) {
    is( $results[$i]{message}, $expected[$i],
        "results[$i]{message} == expected[$i]" );

    is( $received[$i], $results[$i]{message},
        "received[$i] == results[$i]{message}" );

    is( $received[$i], $expected[$i],
        "received[$i] == expected[$i]" );
}

