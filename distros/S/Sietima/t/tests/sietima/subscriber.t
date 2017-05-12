#!perl
use lib 't/lib';
use Test::Sietima;
use Sietima::Subscriber;

subtest 'simple' => sub {
    my $s = Sietima::Subscriber->new(
        primary => 'Gino (pino) <gino@pino.example.com>',
    );

    is(
        $s,
        object {
            call address => 'gino@pino.example.com';
            call name => 'Gino';
            call original => 'Gino (pino) <gino@pino.example.com>';
            call prefs => {};
        },
        'construction and delegation should work',
    );
};

subtest 'aliases' => sub {
    my $s = Sietima::Subscriber->new(
        primary => 'Gino (pino) <gino@pino.example.com>',
        aliases => [qw(also-gino@pino.example.com maybe-gino@rino.example.com)],
    );

    is(
        $s,
        object {
            for my $a (qw(gino@pino also-gino@pino maybe-gino@rino)) {
                call [match => "${a}.example.com"] => T();
            }
        },
        'all addresses should ->match()',
    );

};

done_testing;
