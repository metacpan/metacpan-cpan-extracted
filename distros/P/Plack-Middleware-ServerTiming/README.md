[![Build Status](https://travis-ci.org/akiym/Plack-Middleware-ServerTiming.svg?branch=master)](https://travis-ci.org/akiym/Plack-Middleware-ServerTiming)
# NAME

Plack::Middleware::ServerTiming - Performance metrics in Server-Timing header

# SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'ServerTiming';
        sub {
            my $env = shift;
            sleep 1;
            push @{$env->{'psgix.server-timing'}}, ['miss'];
            push @{$env->{'psgix.server-timing'}}, ['sleep', {dur => 1000, desc => 'Sleep one second...'}];
            [200, ['Content-Type','text/html'], ["OK"]];
        };
    };

# DESCRIPTION

Plack::Middleware::ServerTiming is middleware to add `Server-Timing` header on your response.
You may set `psgix.server-timing` environment value to specify name, duration and description as metrics.

# ENVIRONMENT VALUE

- psgix.server-timing

        $env->{'psgix.server-timing'} = [
            [$name],
            [$name, {dur => $duration}],
            [$name, {desc => $description}],
            [$name, {dur => $duration, desc => $description}],
        ];

# SEE ALSO

[https://www.w3.org/TR/server-timing/](https://www.w3.org/TR/server-timing/)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>
