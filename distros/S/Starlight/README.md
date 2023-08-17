# Starlight

[![CI](https://github.com/dex4er/Starlight/actions/workflows/ci.yaml/badge.svg)](https://github.com/dex4er/Starlight/actions/workflows/ci.yaml)
[![Trunk Check](https://github.com/dex4er/Starlight/actions/workflows/trunk.yaml/badge.svg)](https://github.com/dex4er/Starlight/actions/workflows/trunk.yaml)
[![CPAN](https://img.shields.io/cpan/v/Starlight)](https://metacpan.org/dist/Starlight)

## NAME

starlight - Light and pure-Perl PSGI/Plack HTTP server with pre-forks

## SYNOPSIS

```console

    $ starlight --max-workers=20 --max-reqs-per-child=100 app.psgi

    $ starlight --port=80 --ipv6=1 app.psgi

    $ starlight --port=443 --ssl=1 --ssl-key-file=file.key
                --ssl-cert-file=file.crt app.psgi

    $ starlight --socket=/tmp/starlight.sock app.psgi

```

## DESCRIPTION

Starlight is a standalone HTTP/1.1 server with keep-alive support. It uses
pre-forking. It is a pure-Perl implementation that doesn't require any XS
package.

Starlight was started as a fork of [Thrall](https://metacpan.org/pod/Thrall) server which is a fork of
[Starlet](https://metacpan.org/pod/Starlet) server. It has almost the same code as [Thrall](https://metacpan.org/pod/Thrall) and [Starlet](https://metacpan.org/pod/Starlet) and
it was adapted to not use any other modules than [Plack](https://metacpan.org/pod/Plack).

Starlight is created for Unix-like systems but it should also work on Windows
with some limitations.

## OPTIONS

In addition to the options supported by [plackup](https://metacpan.org/pod/plackup), starlight accepts the
following options(s).

## --access-log

Specifies the pathname of a file where the access log should be
written. By default, in the development environment access logs will
go to STDERR. See [plackup](https://metacpan.org/pod/plackup). (default: none)

## --daemonize

Makes the process run in the background. It doesn't work (yet) in native
Windows (MSWin32). (default: 0)

## -E, --env

Specifies the environment option. See [plackup](https://metacpan.org/pod/plackup). (default: "deployment")

## --error-log

Specify the pathname of a file where the error log should be written. This
enables you to still have access to the errors when using `--daemonize`.
(default: none)

## --group

Changes the group ids or group names that the server should switch to after
binding to the port. The ids or names can be separated with commas or space
characters. (default: none)

## -o, --host

Binds to a TCP interface. Defaults to undef, which lets most server
backends bind to the any (\*) interface. This option is only valid
for servers which support TCP sockets.

## -I

Specifies Perl library include paths, like perl's `-I` option. You
may add multiple paths by using this option multiple times. See [plackup](https://metacpan.org/pod/plackup).

## --ipv6

Enables IPv6 support. The [IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP) module is required. (default: 1
if [IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP) is available or 0 otherwise)

## --keepalive-timeout

Timeout for persistent connections. (default: 2)

## -L, --loader

Starlet changes the default loader to _Delayed_ to make lower consumption
of the children and prevent problems with shared IO handlers. It might be set to
`Plack::Loader` to restore the default loader.

## -M

Loads the named modules before loading the app's code. You may load
multiple modules by using this option multiple times. See [plackup](https://metacpan.org/pod/plackup).
(default: none)

## --main-process-delay

The Starlight does not synchronize its processes and it requires a small delay
in main process so it doesn't consume all CPU. (default: 0.1)

## --max-keepalive-reqs

Max. number of requests allowed per single persistent connection. If set to
one, persistent connections are disabled. (default: 1)

## --max-reqs-per-child

Max. number of requests to be handled before a worker process exits. (default:
1000)

## --max-workers

A number of worker processes. (default: 10)

## --min-reqs-per-child

If set, randomizes the number of requests handled by a single worker process
between the value and that supplied by `--max-reqs-per-chlid`.
(default: none)

## -p, --port

Binds to a TCP port. Defaults to 5000. This option is only valid for
servers which support TCP sockets.

Note: default port 5000 may conflict with AirPlay server on MacOS 12
(Monterey) or later.

## --pid

Specify the pid file path. Use it with `-D|--daemonize` option.
(default: none)

## -q, --quiet

Suppress the message about starting a server.

## -r, --reload

Makes plackup restart the server whenever a file in your development
directory changes. See [plackup](https://metacpan.org/pod/plackup). (default: none)

## -R, --Reload

Makes plackup restart the server whenever a file in any of the given
directories changes. See [plackup](https://metacpan.org/pod/plackup). (default: none)

## --socket

Enables UNIX socket support. The [IO::Socket::UNIX](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AUNIX) module is required. The
socket file has to be not yet created. The first character `@` or `\0` in
the socket file name means that an abstract socket address will be created.
(default: none)

## --spawn-interval

If set, worker processes will not be spawned more than once every given
second. Also, when _SIGHUP_ is being received, no more than one worker
process will be collected every given second. This feature is useful for
doing a "slow restart". (default: none)

## --ssl

Enables the SSL support. The [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL) module is required. (default: 0)

## --ssl-ca-file

Specifies the path to the SSL CA certificate file used when verification mode
is enabled. (default: none)

## --ssl-cert-file

Specifies the path to the SSL certificate file. (default: none)

## --ssl-client-ca-file

Specifies the path to the SSL CA certificate file for client verification.
(default: none)

## --ssl-key-file

Specifies the path to the SSL key file. (default: none)

## --ssl-verify-mode

Sets the verification mode for the peer certificate. See
["SSL\_verify\_mode" in IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL#SSL_verify_mode). (default: 0)

## --timeout

Seconds until timeout. (default: 300)

## --umask

Changes file mode creation mask. The ["umask" in perlfunc](https://metacpan.org/pod/perlfunc#umask) is an octal number
representing disabled permissions bits for newly created files. It is usually
`022` when a group shouldn't have permission to write or `002` when a group
should have permission to write. (default: none)

## --user

Changes the user id or user name that the server process should switch to
after binding to the port. The pid file, error log or unix socket also are
created before changing privileges. This option is usually used if the main
process is started with root privileges because of binding to the
low-numbered (<1024) port. (default: none)

## SEE ALSO

[Starlight](https://metacpan.org/pod/Starlight),
[Thrall](https://metacpan.org/pod/Thrall),
[Starlet](https://metacpan.org/pod/Starlet),
[Starman](https://metacpan.org/pod/Starman)

## LIMITATIONS

Perl on Windows systems (MSWin32 and cygwin) emulates ["fork" in perlfunc](https://metacpan.org/pod/perlfunc#fork) and
["waitpid" in perlfunc](https://metacpan.org/pod/perlfunc#waitpid) functions and uses threads internally. See [perlfork](https://metacpan.org/pod/perlfork)
(MSWin32) and [perlcygwin](https://metacpan.org/pod/perlcygwin) (cygwin) for details and limitations.

It might be a better option to use on this system the server with explicit
[threads](https://metacpan.org/pod/threads) implementation, i.e. [Thrall](https://metacpan.org/pod/Thrall).

For Cygwin the `perl-libwin32` package is highly recommended, because of
[Win32::Process](https://metacpan.org/pod/Win32%3A%3AProcess) module which helps to terminate stalled worker processes.

## BUGS

## Windows

There is a problem with Perl threads implementation which occurs on Windows
systems (MSWin32). Cygwin version seems to be correct.

Some requests can fail with the message:

> failed to set socket to nonblocking mode:An operation was attempted on
> something that is not a socket.

or

> Bad file descriptor at (eval 24) line 4.

This problem was introduced in Perl 5.16 and fixed in Perl 5.19.5.

See [https://rt.perl.org/rt3/Public/Bug/Display.html?id=119003](https://rt.perl.org/rt3/Public/Bug/Display.html?id=119003) and
[https://github.com/dex4er/Thrall/issues/5](https://github.com/dex4er/Thrall/issues/5) for more information about this
issue.

The server fails when a worker process calls ["exit" in perlfunc](https://metacpan.org/pod/perlfunc#exit) function:

> Attempt to free unreferenced scalar: SV 0x293a76c, Perl interpreter:
> 0x22dcc0c at lib/Plack/Handler/Starlight.pm line 140.

It means that Harakiri mode can't work and the server has to be started with
`--max-reqs-per-child=inf` option.

See [https://rt.perl.org/Public/Bug/Display.html?id=40565](https://rt.perl.org/Public/Bug/Display.html?id=40565) and
[https://github.com/dex4er/Starlight/issues/1](https://github.com/dex4er/Starlight/issues/1) for more information about
this issue.

## MacOS

MacOS High Sierra and newer shows error:

> objc\[12345\]: +\[\_\_NSCFConstantString initialize\] may have been in progress in another thread when fork() was called.
> objc\[12345\]: +\[\_\_NSCFConstantString initialize\] may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc\_initializeAfterForkError to debug.

This error is caused by an added security to restrict multithreading.

To override the limitation, run
`export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` before using this server.

## Reporting

If you find the bug or want to implement new features, please report it at
[https://github.com/dex4er/Starlight/issues](https://github.com/dex4er/Starlight/issues)

The code repository is available at
[http://github.com/dex4er/Starlight](http://github.com/dex4er/Starlight)

## AUTHORS

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

## LICENSE

Copyright (c) 2013-2016, 2020, 2023 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
