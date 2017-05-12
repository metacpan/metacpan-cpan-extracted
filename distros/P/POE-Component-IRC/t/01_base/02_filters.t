use strict;
use warnings FATAL => 'all';
use Test::More;
use POE::Filter::Stackable;
use POE::Filter::IRCD;
use POE::Filter::IRC::Compat;
use POE::Filter::IRC;

my @tests = (
    {
        line => ':joe!joe@example.com PART #foo :Goodbye',
        events => {
            part => [
                'joe!joe@example.com',
                '#foo',
                'Goodbye',
            ],
        },
    },
    {
        line => ':joe!joe@example.com JOIN #foo',
        events => {
            join => [
                'joe!joe@example.com',
                '#foo',
            ],
        },
    },
    {
        line => ':magnet.shadowcat.co.uk 366 Flibble28185 #IRC.pm :End of /NAMES list.',
        events => {
            366 => [
                'magnet.shadowcat.co.uk',
                '#IRC.pm :End of /NAMES list.',
                [
                    '#IRC.pm',
                    'End of /NAMES list.'
                ],
            ],
        },
    },
    {
        line => ':joe!joe@example.com PRIVMSG #foo :Fish go moo',
        events => {
            public => [
                'joe!joe@example.com',
                [
                    '#foo',
                ],
                'Fish go moo',
            ],
        },
    },
    {
        line => ':joe!joe@example.com NOTICE #foo :Fish go moo',
        events => {
            notice => [
                'joe!joe@example.com',
                [
                    '#foo',
                ],
                'Fish go moo',
            ],
        },
    },
    {
        line => ':joe!joe@example.com PRIVMSG foobar :Fish go moo',
        events => {
            msg => [
                'joe!joe@example.com',
                [
                    'foobar',
                ],
                'Fish go moo',
            ],
        },
    },
    {
        line => ':joe!joe@example.com NICK :moe',
        events => {
            nick => [
                'joe!joe@example.com',
                'moe',
            ],
        },
    },
    {
        line => ':joe!joe@example.com QUIT :moe',
        events => {
            quit => [
                'joe!joe@example.com',
                'moe',
            ],
        },
    },
    {
        line => 'PING :moe',
        events => {
            ping => [
                'moe'
            ],
        },
    },
    {
        line => ':joe!joe@example.com TOPIC #foo :Fish go moo',
        events => {
            topic => [
                'joe!joe@example.com',
                '#foo',
                'Fish go moo',
            ],
        },
    },
    {
        line => ':joe!joe@example.com KICK #foo foobar :Goodbye',
        events => {
            kick => [
                'joe!joe@example.com',
                '#foo',
                'foobar',
                'Goodbye',
            ],
        },
    },
    {
        line => ':joe!joe@example.com INVITE foobar :#foo',
        events => {
            invite => [
                'joe!joe@example.com',
                '#foo',
            ],
        },
    },
    {
        line => ':joe!joe@example.com MODE #foo +m',
        events => {
            mode => [
                'joe!joe@example.com',
                '#foo',
                '+m',
            ],
        },
    },
    {
        line => ":joe!joe\@example.com PRIVMSG #foo :\001ACTION barfs on the floor.\001",
        events => {
            ctcp_action => [
                'joe!joe@example.com',
                [
                    '#foo',
                ],
                'barfs on the floor.',
            ],
        },
    },
    {
        line => 'NOTICE * :Fish go moo',
        events => {
            snotice => [
                'Fish go moo',
                '*',
            ],
        },
    },

    {
        line => ':foo.bar.baz NOTICE * :Fish go moo',
        events => {
            snotice => [
                'Fish go moo',
                '*',
                'foo.bar.baz',
            ],
        },
    },
);

sub count {
    my (@items) = @_;

    my $count = 0;
    for my $item (@items) {
        $count++;
        next if ref $item ne 'ARRAY';
        $count += count(@$item);
    }

    return $count;
}

my $sum;
$sum += $_ for map {
    map {
        4 + count( @$_ )
    } values %{ $_->{events} }
} @tests;

plan tests => (2 + 2 * $sum);

my $irc_filter = POE::Filter::IRC->new();
my $stack = POE::Filter::Stackable->new(
    Filters => [
        POE::Filter::IRCD->new(),
        POE::Filter::IRC::Compat->new(),
]);

for my $filter ( $stack, $irc_filter ) {
    isa_ok( $filter, 'POE::Filter::Stackable');

    for my $test (@tests) {
        my @events = @{ $filter->get( [$test->{line}]) };

        is(scalar @events, scalar keys %{ $test->{events} }, 'Event count');
        for my $event (@events) {
            ok($test->{events}{$event->{name}}, "Got irc_$event->{name}");
            is($event->{raw_line}, $test->{line}, "Raw Line $event->{name}");

            my $test_args = $test->{events}{$event->{name}};
            is(scalar @{ $event->{args} }, scalar @$test_args,
               "Args count $event->{name}");

            for my $idx (0 .. $#$test_args) {
                if (ref $test_args->[$idx] eq 'ARRAY') {
                    is(
                        scalar @{ $event->{args}[$idx] },
                        scalar @{ $test_args->[$idx] },
                        "Sub args count $event->{name}",
                    );

                    for my $iidx (0 .. $#{ $test_args->[$idx] }) {
                        is(
                            $event->{args}->[$idx][$iidx],
                            $test_args->[$idx][$iidx],
                            "Sub args Index $event->{name} $idx $iidx",
                        );
                    }
                }
                else {
                    is(
                        $event->{args}[$idx],
                        $test_args->[$idx],
                        "Args Index $event->{name} $idx",
                    );
                }
            }
        }
    }
}
