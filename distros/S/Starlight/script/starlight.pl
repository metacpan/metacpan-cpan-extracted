#!/usr/bin/perl

=head1 NAME

starlight - Light and pure-Perl PSGI/Plack HTTP server with pre-forks

=head1 SYNOPSIS

=for markdown ```console

    $ starlight --max-workers=20 --max-reqs-per-child=100 app.psgi

    $ starlight --port=80 --ipv6=1 app.psgi

    $ starlight --port=443 --ssl=1 --ssl-key-file=file.key
                --ssl-cert-file=file.crt app.psgi

    $ starlight --socket=/tmp/starlight.sock app.psgi

=for markdown ```

=head1 DESCRIPTION

Starlight is a standalone HTTP/1.1 server with keep-alive support. It uses
pre-forking. It is a pure-Perl implementation that doesn't require any XS
package.

Starlight was started as a fork of L<Thrall> server which is a fork of
L<Starlet> server. It has almost the same code as L<Thrall> and L<Starlet> and
it was adapted to not use any other modules than L<Plack>.

Starlight is created for Unix-like systems but it should also work on Windows
with some limitations.

=for readme stop

=cut

use 5.008_001;

use strict;
use warnings;

our $VERSION = '0.0503';

use Plack::Runner;

sub version {
    print "Starlight $VERSION\n";
}

my $runner = Plack::Runner->new(
    server     => 'Starlight',
    env        => 'deployment',
    loader     => 'Delayed',
    version_cb => \&version,
);
$runner->parse_options(@ARGV);
$runner->run;

__END__

=head1 OPTIONS

In addition to the options supported by L<plackup>, starlight accepts the
following options(s).

=head2 --access-log

Specifies the pathname of a file where the access log should be
written. By default, in the development environment access logs will
go to STDERR. See L<plackup>. (default: none)

=head2 --daemonize

Makes the process run in the background. It doesn't work (yet) in native
Windows (MSWin32). (default: 0)

=head2 -E, --env

Specifies the environment option. See L<plackup>. (default: "deployment")

=head2 --error-log

Specify the pathname of a file where the error log should be written. This
enables you to still have access to the errors when using C<--daemonize>.
(default: none)

=head2 --group

Changes the group ids or group names that the server should switch to after
binding to the port. The ids or names can be separated with commas or space
characters. (default: none)

=head2 -o, --host

Binds to a TCP interface. Defaults to undef, which lets most server
backends bind to the any (*) interface. This option is only valid
for servers which support TCP sockets.

=head2 -I

Specifies Perl library include paths, like perl's C<-I> option. You
may add multiple paths by using this option multiple times. See L<plackup>.

=head2 --ipv6

Enables IPv6 support. The L<IO::Socket::IP> module is required. (default: 1
if L<IO::Socket::IP> is available or 0 otherwise)

=head2 --keepalive-timeout

Timeout for persistent connections. (default: 2)

=head2 -L, --loader

Starlet changes the default loader to I<Delayed> to make lower consumption
of the children and prevent problems with shared IO handlers. It might be set to
C<Plack::Loader> to restore the default loader.

=head2 -M

Loads the named modules before loading the app's code. You may load
multiple modules by using this option multiple times. See L<plackup>.
(default: none)

=head2 --main-process-delay

The Starlight does not synchronize its processes and it requires a small delay
in main process so it doesn't consume all CPU. (default: 0.1)

=head2 --max-keepalive-reqs

Max. number of requests allowed per single persistent connection. If set to
one, persistent connections are disabled. (default: 1)

=head2 --max-reqs-per-child

Max. number of requests to be handled before a worker process exits. (default:
1000)

=head2 --max-workers

A number of worker processes. (default: 10)

=head2 --min-reqs-per-child

If set, randomizes the number of requests handled by a single worker process
between the value and that supplied by C<--max-reqs-per-chlid>.
(default: none)

=head2 -p, --port

Binds to a TCP port. Defaults to 5000. This option is only valid for
servers which support TCP sockets.

Note: default port 5000 may conflict with AirPlay server on MacOS 12
(Monterey) or later.

=head2 --pid

Specify the pid file path. Use it with C<-D|--daemonize> option.
(default: none)

=head2 -q, --quiet

Suppress the message about starting a server.

=head2 -r, --reload

Makes plackup restart the server whenever a file in your development
directory changes. See L<plackup>. (default: none)

=head2 -R, --Reload

Makes plackup restart the server whenever a file in any of the given
directories changes. See L<plackup>. (default: none)

=head2 --socket

Enables UNIX socket support. The L<IO::Socket::UNIX> module is required. The
socket file has to be not yet created. The first character C<@> or C<\0> in
the socket file name means that an abstract socket address will be created.
(default: none)

=head2 --spawn-interval

If set, worker processes will not be spawned more than once every given
second. Also, when I<SIGHUP> is being received, no more than one worker
process will be collected every given second. This feature is useful for
doing a "slow restart". (default: none)

=head2 --ssl

Enables the SSL support. The L<IO::Socket::SSL> module is required. (default: 0)

=head2 --ssl-ca-file

Specifies the path to the SSL CA certificate file used when verification mode
is enabled. (default: none)

=head2 --ssl-cert-file

Specifies the path to the SSL certificate file. (default: none)

=head2 --ssl-client-ca-file

Specifies the path to the SSL CA certificate file for client verification.
(default: none)

=head2 --ssl-key-file

Specifies the path to the SSL key file. (default: none)

=head2 --ssl-verify-mode

Sets the verification mode for the peer certificate. See
L<IO::Socket::SSL/SSL_verify_mode>. (default: 0)

=head2 --timeout

Seconds until timeout. (default: 300)

=head2 --umask

Changes file mode creation mask. The L<perlfunc/umask> is an octal number
representing disabled permissions bits for newly created files. It is usually
C<022> when a group shouldn't have permission to write or C<002> when a group
should have permission to write. (default: none)

=head2 --user

Changes the user id or user name that the server process should switch to
after binding to the port. The pid file, error log or unix socket also are
created before changing privileges. This option is usually used if the main
process is started with root privileges because of binding to the
low-numbered (E<lt>1024) port. (default: none)

=for readme continue

=head1 SEE ALSO

L<Starlight>,
L<Thrall>,
L<Starlet>,
L<Starman>

=head1 LIMITATIONS

Perl on Windows systems (MSWin32 and cygwin) emulates L<perlfunc/fork> and
L<perlfunc/waitpid> functions and uses threads internally. See L<perlfork>
(MSWin32) and L<perlcygwin> (cygwin) for details and limitations.

It might be a better option to use on this system the server with explicit
L<threads> implementation, i.e. L<Thrall>.

For Cygwin the C<perl-libwin32> package is highly recommended, because of
L<Win32::Process> module which helps to terminate stalled worker processes.

=head1 BUGS

=head2 Windows

There is a problem with Perl threads implementation which occurs on Windows
systems (MSWin32). Cygwin version seems to be correct.

Some requests can fail with the message:

=over

failed to set socket to nonblocking mode:An operation was attempted on
something that is not a socket.

=back

or

=over

Bad file descriptor at (eval 24) line 4.

=back

This problem was introduced in Perl 5.16 and fixed in Perl 5.19.5.

See L<https://rt.perl.org/rt3/Public/Bug/Display.html?id=119003> and
L<https://github.com/dex4er/Thrall/issues/5> for more information about this
issue.

The server fails when a worker process calls L<perlfunc/exit> function:

=over

Attempt to free unreferenced scalar: SV 0x293a76c, Perl interpreter:
0x22dcc0c at lib/Plack/Handler/Starlight.pm line 140.

=back

It means that Harakiri mode can't work and the server has to be started with
C<--max-reqs-per-child=inf> option.

See L<https://rt.perl.org/Public/Bug/Display.html?id=40565> and
L<https://github.com/dex4er/Starlight/issues/1> for more information about
this issue.

=head2 MacOS

MacOS High Sierra and newer shows error:

=over

objc[12345]: +[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called.
objc[12345]: +[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc_initializeAfterForkError to debug.

=back

This error is caused by an added security to restrict multithreading.

To override the limitation, run
C<export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES> before using this server.

=head2 Reporting

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/Starlight/issues>

The code repository is available at
L<http://github.com/dex4er/Starlight>

=head1 AUTHORS

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

Jeremy Howard <j+daemonize@howard.fm>

Paul Seamons <paul@seamons.com>

=head1 LICENSE

Copyright (c) 2013-2016, 2020, 2023 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
