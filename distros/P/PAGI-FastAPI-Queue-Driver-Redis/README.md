## PAGI::FastAPI::Queue::Driver::Redis

[![CPAN version](https://badge.fury.io/pl/PAGI-FastAPI-Queue-Driver-Redis.svg)](https://metacpan.org/pod/PAGI::FastAPI::Queue::Driver::Redis)

Redis Storage Driver for `PAGI::FastAPI::Queue`.

`PAGI::FastAPI::Queue::Driver::Redis` is a storage driver plugin for
[`PAGI::FastAPI::Queue`](https://metacpan.org/pod/PAGI::FastAPI::Queue).
It stores each topic as a Redis list, so queued items are shared across
every worker process and host pointed at the same Redis instance and key
prefix - unlike the built-in, in-process
`PAGI::FastAPI::Queue::Driver::Memory`.

It's built on [`Async::Redis`](https://metacpan.org/pod/Async::Redis)
(`Future::IO`-based) rather than `Net::Async::Redis`, matching
`PAGI::FastAPI`'s own documented event-loop philosophy: `Future::IO` is
the goal, `IO::Async` is an implementation detail.

## SYNOPSIS

    use PAGI::FastAPI::Queue;
    use PAGI::FastAPI::Depends qw(Depends);

    my $queue = PAGI::FastAPI::Queue->new(
        driver  => 'PAGI::FastAPI::Queue::Driver::Redis',
        options => {
            host   => '127.0.0.1',
            port   => 6379,
            prefix => 'myapp:queue:',
        },
    );

    $app->post('/jobs',
        dependencies => [ Depends($queue->dep, key => 'queue') ],
        handler      => async sub ($c) {
            await $c->stash->{queue}->push('emails', { to => 'a@b.com' });
            return { queued => 1 };
        },
    );

## INSTALLATION

Install the distribution from CPAN using your preferred client:

    cpanm PAGI::FastAPI::Queue::Driver::Redis

This driver can also be used with a caller-supplied client (see the
`redis` constructor option in the POD), so `Async::Redis` is not a hard
dependency of this distribution. Install it yourself if you rely on the
driver's default auto-connect behaviour:

    cpanm Async::Redis

## LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).
