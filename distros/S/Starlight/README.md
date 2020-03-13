[![Build Status](https://travis-ci.org/dex4er/Starlight.svg?branch=master)](https://travis-ci.org/dex4er/Starlight)[![CPAN version](https://badge.fury.io/pl/Starlight.svg)](https://metacpan.org/release/Starlight)

# NAME

starlight - a light and pure-Perl PSGI/Plack HTTP server with pre-forks

# SYNOPSIS

    $ starlight --workers=20 --max-reqs-per-child=100 app.psgi

    $ starlight --port=80 --ipv6=1 app.psgi

    $ starlight --port=443 --ssl=1 --ssl-key-file=file.key
                --ssl-cert-file=file.crt app.psgi

    $ starlight --socket=/tmp/starlight.sock app.psgi

# DESCRIPTION

Starlight is a standalone HTTP/1.1 server with keep-alive support. It uses
pre-forking. It is pure-Perl implementation which doesn't require any XS
package.

Starlight was started as a fork of [Thrall](https://metacpan.org/pod/Thrall) server which is a fork of
[Starlet](https://metacpan.org/pod/Starlet) server. It has almost the same code as [Thrall](https://metacpan.org/pod/Thrall) and [Starlet](https://metacpan.org/pod/Starlet) and
it was adapted to not use any other modules than [Plack](https://metacpan.org/pod/Plack).

Starlight is created for Unix-like systems but it should also work on Windows
with some limitations.

# OPTIONS

In addition to the options supported by [plackup](https://metacpan.org/pod/plackup), starlight accepts
following options(s).

## --max-workers

Number of worker processes. (default: 10)

## --timeout

Seconds until timeout. (default: 300)

## --keepalive-timeout

Timeout for persistent connections. (default: 2)

## --max-keepalive-reqs

Max. number of requests allowed per single persistent connection. If set to
one, persistent connections are disabled. (default: 1)

## --max-reqs-per-child

Max. number of requests to be handled before a worker process exits. (default:
1000)

## --min-reqs-per-child

If set, randomizes the number of requests handled by a single worker process
between the value and that supplied by `--max-reqs-per-chlid`.
(default: none)

## --spawn-interval

If set, worker processes will not be spawned more than once than every given
seconds.  Also, when SIGHUP is being received, no more than one worker
processes will be collected every given seconds. This feature is useful for
doing a "slow-restart". (default: none)

## --main-process-delay

The Starlight does not synchronize its processes and it requires a small delay
in main process so it doesn't consume all CPU. (default: 0.1)

## --ssl

Enables SSL support. The [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL) module is required. (default: 0)

## --ssl-key-file

Specifies the path to SSL key file. (default: none)

## --ssl-cert-file

Specifies the path to SSL certificate file. (default: none)

## --ssl-ca-file

Specifies the path to SSL CA certificate file used when verification mode is
enabled. (default: none)

## --ssl-verify-mode

Sets the verification mode for the peer certificate. See
["SSL\_verify\_mode" in IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL#SSL_verify_mode). (default: 0)

## --ipv6

Enables IPv6 support. The [IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP) module is required. (default: 0)

## --socket

Enables UNIX socket support. The [IO::Socket::UNIX](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AUNIX) module is required. The
socket file have to be not yet created. The first character `@` or `\0` in
the socket file name means that abstract socket address will be created.
(default: none)

## --user

Changes the user id or user name that the server process should switch to
after binding to the port. The pid file, error log or unix socket also are
created before changing privileges. This options is usually used if main
process is started with root privileges beacause binding to the low-numbered
(<1024) port. (default: none)

## --group

Changes the group ids or group names that the server should switch to after
binding to the port. The ids or names can be separated with comma or space
character. (default: none)

## --umask

Changes file mode creation mask. The ["umask" in perlfunc](https://metacpan.org/pod/perlfunc#umask) is an octal number
representing disabled permissions bits for newly created files. It is usually
`022` when group shouldn't have permission to write or `002` when group
should have permission to write. (default: none)

## --daemonize

Makes the process run in the background. It doesn't work (yet) in native
Windows (MSWin32). (default: 0)

## --pid

Specify the pid file path. Use it with `-D|--daemonize` option.
(default: none)

## --error-log

Specify the pathname of a file where the error log should be written. This
enables you to still have access to the errors when using `--daemonize`.
(default: none)

## -q, --quiet

Suppress the message about starting a server.

# SEE ALSO

[Starlight](https://metacpan.org/pod/Starlight),
[Thrall](https://metacpan.org/pod/Thrall),
[Starlet](https://metacpan.org/pod/Starlet),
[Starman](https://metacpan.org/pod/Starman)

# LIMITATIONS

Perl on Windows systems (MSWin32 and cygwin) emulates ["fork" in perlfunc](https://metacpan.org/pod/perlfunc#fork) and
["waitpid" in perlfunc](https://metacpan.org/pod/perlfunc#waitpid) functions and uses threads internally. See [perlfork](https://metacpan.org/pod/perlfork)
(MSWin32) and [perlcygwin](https://metacpan.org/pod/perlcygwin) (cygwin) for details and limitations.

It might be better option to use on this system the server with explicit
[threads](https://metacpan.org/pod/threads) implementation, i.e. [Thrall](https://metacpan.org/pod/Thrall).

For Cygwin the `perl-libwin32` package is highly recommended, because of
[Win32::Process](https://metacpan.org/pod/Win32%3A%3AProcess) module which helps to terminate stalled worker processes.

# BUGS

## Windows

There is a problem with Perl threads implementation which occurs on Windows
systems (MSWin32). Cygwin version seems to be correct.

Some requests can fail with message:

    failed to set socket to nonblocking mode:An operation was attempted on
    something that is not a socket.

or

    Bad file descriptor at (eval 24) line 4.

This problem was introduced in Perl 5.16 and fixed in Perl 5.19.5.

See [https://rt.perl.org/rt3/Public/Bug/Display.html?id=119003](https://rt.perl.org/rt3/Public/Bug/Display.html?id=119003) and
[https://github.com/dex4er/Thrall/issues/5](https://github.com/dex4er/Thrall/issues/5) for more information about this
issue.

The server fails when worker process calls ["exit" in perlfunc](https://metacpan.org/pod/perlfunc#exit) function:

    Attempt to free unreferenced scalar: SV 0x293a76c, Perl interpreter:
    0x22dcc0c at lib/Plack/Handler/Starlight.pm line 140.

It means that Harakiri mode can't work and the server have to be started with
`--max-reqs-per-child=inf` option.

See [https://rt.perl.org/Public/Bug/Display.html?id=40565](https://rt.perl.org/Public/Bug/Display.html?id=40565) and
[https://github.com/dex4er/Starlight/issues/1](https://github.com/dex4er/Starlight/issues/1) for more information about
this issue.

## Reporting

If you find the bug or want to implement new features, please report it at
[https://github.com/dex4er/Starlight/issues](https://github.com/dex4er/Starlight/issues)

The code repository is available at
[http://github.com/dex4er/Starlight](http://github.com/dex4er/Starlight)

# AUTHORS

Piotr Roszatycki <dexter@cpan.org>

Based on Thrall by:

Piotr Roszatycki <dexter@cpan.org>

Based on Starlet by:

Kazuho Oku

miyagawa

kazeburo

Some code based on Plack:

Tatsuhiko Miyagawa

Some code based on Net::Server::Daemonize:

Jeremy Howard &lt;j+daemonize@howard.fm>

Paul Seamons <paul@seamons.com>

# LICENSE

Copyright (c) 2013-2016, 2020 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
