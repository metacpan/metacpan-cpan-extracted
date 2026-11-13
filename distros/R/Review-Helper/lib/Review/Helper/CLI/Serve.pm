package Review::Helper::CLI::Serve;
use v5.36;

our $VERSION = '0.001';

use Capture::Tiny qw/capture_stdout/;
use HTTP::Server::PSGI();
use IO::Handle();
use IO::Socket::IP();
use POSIX();
use Socket();
use Sys::Hostname();

use Review::Helper::Server;

use Getopt::Yath;

option_group {group => 'serve', category => 'Serve Options'} => sub {
    option port         => (type => 'Scalar', description   => 'Port to listen on. Default: any free port.');
    option port_command => (type => 'Scalar', description   => "A command that prints the port to listen on. Default: \$REVIEW_HELPER_PORT_COMMAND.");
    option open         => (type => 'Bool',   description   => 'Open the page in a browser (Linux and macOS).');
    option listen       => (type => 'Scalar', from_env_vars => ['REVIEW_HELPER_LISTEN'],      description => "The address to listen on: an IPv4 or IPv6 address or a host name; 0.0.0.0 or :: listens on every interface. Default: \$REVIEW_HELPER_LISTEN, else 127.0.0.1.");
    option allow_host   => (type => 'List',   from_env_vars => ['REVIEW_HELPER_ALLOW_HOSTS'], description => "Also accept requests addressed to this host name, such as a DNS alias. Repeatable; \$REVIEW_HELPER_ALLOW_HOSTS adds a comma-separated list.");
    option reviewer     => (type => 'Scalar', description   => "Who is reviewing, as recorded on feedback, requests and seen marks. Default: \$REVIEW_HELPER_REVIEWER, else git's user.name and user.email, else the login name, else 'unknown'.");
};

my $USAGE = "review-helper serve FILE [--port N | --port-command CMD] [--listen ADDR] [--allow-host NAME]... [--open] [--reviewer NAME]";

sub run($class, $settings, @args) {
    die "Usage: $USAGE\n" unless @args == 1;
    my ($file) = @args;
    my $serve = $settings->serve;

    my $port = $class->pick_port($serve->port, $serve->port_command);
    die "Invalid port '$port'\n" unless $port =~ m/\A[0-9]+\z/ && $port < 65536;

    my $listen = $serve->listen;
    $listen = '127.0.0.1' unless defined($listen) && $listen =~ m/\S/;
    my $socket = $class->listen_socket($port, $listen);
    my $bound  = $socket->sockhost;
    my $local  = Review::Helper::Server->is_loopback($bound);
    my $token  = $local ? undef : $class->new_token;

    my @hosts = grep { m/\S/ } map { split m/\s*,\s*/ } @{$serve->allow_host // []};
    push @hosts => $class->network_names($listen, $bound) unless $local;

    my $app  = Review::Helper::Server->new(db_path => $file, reviewer => $serve->reviewer, allow_hosts => \@hosts, token => $token)->to_app;
    my @urls = $class->urls($listen, $bound, $socket->sockport);
    $urls[0] .= "?token=$token" if $token;    # beyond loopback, the first URL is for other machines

    STDOUT->autoflush(1);
    print "$_\n" for @urls;
    print STDERR "review-helper: listening on $listen, beyond this machine: anyone with the token URL above can read this review and post feedback, and anyone on this machine can without it; keep the URL private.\n"
        unless $local;
    $class->open_browser($urls[-1]) if $serve->open;

    HTTP::Server::PSGI->new(listen_sock => $socket)->run($app);
    return;
}

sub pick_port($class, $port, $command) {
    die "Give --port or --port-command, not both\n" if defined($port) && defined($command);
    return $port                                    if defined $port;
    $command //= $ENV{REVIEW_HELPER_PORT_COMMAND};
    return 0 unless defined($command) && $command =~ m/\S/;
    return $class->run_port_command($command);
}

sub run_port_command($class, $command) {
    my @argv = split ' ' => $command;

    # The block form of system never hands a word holding shell
    # metacharacters to /bin/sh. The command's errors go to ours. It writes
    # to descriptor 1, so a plain handle on it is what gets captured, even
    # when Perl's STDOUT is elsewhere. With descriptor 1 closed the alias
    # fails and STDOUT stays closed, which Capture::Tiny also captures, on a
    # descriptor 1 of its own.
    STDOUT->flush;
    local *STDOUT;
    open(STDOUT, '>&=', 1);    # unchecked: see above
    my ($status, $errno);
    my $out = capture_stdout {
        no warnings 'exec';    # reported below, with the command
        $status = system {$argv[0]} @argv;
        $errno  = $! + 0;
    };
    if ($status == -1) {
        $! = $errno;
        die "Cannot run port command '$command': $!\n";
    }
    die "Port command '$command' failed with exit code " . ($status >> 8) . "\n" if $status;

    $out =~ s/\A\s+|\s+\z//g;
    die "Port command '$command' printed '$out', not a port number\n" unless $out =~ m/\A[0-9]+\z/ && $out > 0 && $out < 65536;
    return $out + 0;
}

sub listen_socket($class, $port, $listen = '127.0.0.1') {
    return IO::Socket::IP->new(
        LocalHost => $listen,
        LocalPort => $port,
        Listen    => 128,
        ReuseAddr => 1,
        Proto     => 'tcp',
    ) // die "Cannot listen on $listen port $port: $@\n";
}

sub is_wildcard($class, $addr) {
    return $addr eq '0.0.0.0' || $addr eq '::' ? 1 : 0;
}

# The URLs to print: the one to open from another machine, then the loopback
# one when the socket answers on loopback too. --open opens the last.
sub urls($class, $listen, $bound, $port) {
    my $url = sub ($host) { $host =~ m/:/ ? "http://[$host]:$port/" : "http://$host:$port/" };
    return $url->($bound) if Review::Helper::Server->is_loopback($bound);
    return $url->($listen) unless $class->is_wildcard($bound);
    return ($url->($class->fqdn), $url->($bound eq '::' ? '::1' : '127.0.0.1'));
}

sub new_token($class) {
    open(my $fh, '<:raw', '/dev/urandom') or die "Cannot open /dev/urandom: $!\n";
    my $got = read($fh, my $bytes, 32) // die "Cannot read /dev/urandom: $!\n";
    die "Short read from /dev/urandom\n" unless $got == 32;
    return unpack('H*', $bytes);
}

sub fqdn($class) {
    my $name = Sys::Hostname::hostname();
    my ($err, @found) = Socket::getaddrinfo($name, undef, {flags => Socket::AI_CANONNAME(), socktype => Socket::SOCK_STREAM()});
    return $err || !@found || !$found[0]{canonname} ? $name : $found[0]{canonname};
}

# The names a browser elsewhere may put in the Host header: the address given
# and the one bound (unless a wildcard), this machine's hostname and FQDN and
# the addresses they resolve to, and the addresses outgoing traffic leaves
# from. Other interfaces' addresses need --allow-host.
sub network_names($class, $listen, $bound) {
    my @names = (Sys::Hostname::hostname(), $class->fqdn);
    my @hosts = (@names, grep { !$class->is_wildcard($_) } $listen, $bound);

    for my $name (@names) {
        my ($err, @found) = Socket::getaddrinfo($name, undef, {socktype => Socket::SOCK_STREAM()});
        next if $err;
        for my $found (@found) {
            my ($bad, $addr) = Socket::getnameinfo($found->{addr}, Socket::NI_NUMERICHOST());
            push @hosts => $addr =~ s/%.*\z//r unless $bad;
        }
    }

    # Connecting a UDP socket picks a route without sending anything.
    for my $peer (qw/192.0.2.1 2001:db8::1/) {
        my $probe = IO::Socket::IP->new(PeerHost => $peer, PeerPort => 9, Proto => 'udp') or next;
        push @hosts => $probe->sockhost;
    }

    my %seen;
    return grep { !$seen{$_}++ } @hosts;
}

sub open_browser($class, $url) {
    my $command = $^O eq 'linux' ? 'xdg-open' : $^O eq 'darwin' ? 'open' : undef;
    return 0 unless $command;

    # Some openers wait until the browser exits, and the browser waits for
    # the server, so the opener runs detached and nothing waits for it. The
    # middle child exits at once and is reaped here; the opener's child is
    # inherited by init, so the server never collects zombies.
    my $pid = fork // die "Could not fork: $!";
    if ($pid) {
        waitpid($pid, 0);
        return 1;
    }

    my $ok = eval { $class->exec_detached($command, $url); 1 };
    print STDERR $@ unless $ok;
    close(STDERR);    # _exit does not flush
    POSIX::_exit(1);
}

sub exec_detached($class, $command, @args) {
    POSIX::_exit(0) if fork // die "Could not fork: $!";
    POSIX::setsid();

    # Perl marks this copy close-on-exec, so only a failed exec writes to it.
    my $report;
    open($report, q{>&}, \*STDERR) or undef $report;
    my $null = POSIX::open('/dev/null', POSIX::O_RDWR()) // die "Cannot open /dev/null: $!";
    POSIX::dup2($null, $_) // die "Cannot redirect to /dev/null: $!" for 0, 1, 2;

    { exec($command, @args) }
    if ($report) {
        print $report "Could not run '$command'; open the URL by hand.\n";
        close($report);    # _exit does not flush
    }
    POSIX::_exit(127);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::CLI::Serve - The review-helper serve subcommand.

=head1 DESCRIPTION

    review-helper serve FILE [--port N | --port-command CMD] [--listen ADDR] [--allow-host NAME]... [--open] [--reviewer NAME]
    review-helper FILE [--port N | --port-command CMD] [--listen ADDR] [--allow-host NAME]... [--open] [--reviewer NAME]

Serves the review in C<FILE> as a web app (L<Review::Helper::Server>) until
interrupted, and prints the URL to open. By default it listens on
C<127.0.0.1> only.

C<--listen ADDR>, or else the C<REVIEW_HELPER_LISTEN> environment variable,
listens on C<ADDR> instead: an IPv4 or IPv6 address, or a host name that
resolves to one of this machine's addresses. C<0.0.0.0> listens on every
IPv4 interface and C<::> on every IPv6 one (and usually IPv4 too). This is
for reviewing from a browser on another machine, such as a laptop reaching a
shared dev server. Beyond loopback the server accepts requests addressed to
the address listened on (unless a wildcard), this machine's hostname and
FQDN, the addresses they resolve to, and the address outgoing traffic leaves
from, as well as C<127.0.0.1>, C<localhost> and C<[::1]>. Clients other
than loopback must also present a random token made at start (see
L<Review::Helper::Server>); loopback clients need none. It prints a URL for
other machines first, with the token: the FQDN for a wildcard, else C<ADDR>
as given. When the socket also answers on loopback (a wildcard), the
loopback URL, without a token, follows. It warns on standard error that
anyone with the token URL, and anyone on this machine, can read the review
and post feedback.

C<--allow-host NAME> (repeatable), plus the comma-separated names in the
C<REVIEW_HELPER_ALLOW_HOSTS> environment variable, are further host names to
accept, such as a DNS alias or an address of another interface. A reverse
proxy on this machine connects from loopback, so everyone who can reach the
proxy gets in without the token.

The port is C<--port> when given. Otherwise C<--port-command>, or else the
C<REVIEW_HELPER_PORT_COMMAND> environment variable, names a command whose
standard output is the port number, such as a script that hands out a port
per worktree. The command is split on whitespace and run directly, not
through a shell; put anything needing a shell in a script. With none of
these, any free port is used.

With C<--open>, also opens the URL with C<xdg-open> on Linux or C<open> on
macOS: the loopback URL when there is one, else the only URL printed.
Elsewhere the URL is only printed.

C<--reviewer> names who is reviewing; the page records it on the feedback,
requests and seen marks it writes. It defaults to the
C<REVIEW_HELPER_REVIEWER> environment variable, else C<< Name <email> >> from
git's C<user.name> and C<user.email> for the repository, else the login name,
else C<unknown>.

=head1 SYNOPSIS

    Review::Helper::CLI->run(serve => $file, '--open');

=head1 PUBLIC METHODS

=over 4

=item Review::Helper::CLI::Serve->run($settings, $file)

Serve C<$file> until the process is stopped. Dies unless exactly one file is
given, on an invalid port, or when the address and port cannot be bound.

=item $port = Review::Helper::CLI::Serve->pick_port($port, $command)

The port to listen on, from C<--port> and C<--port-command> (either may be
undef), as described above; 0 means any free port. Dies when both are given.

=item $port = Review::Helper::CLI::Serve->run_port_command($command)

Run C<$command> and return the port it printed. Dies when it cannot run,
exits non-zero, or prints anything but a port number from 1 to 65535.

=item $socket = Review::Helper::CLI::Serve->listen_socket($port)

=item $socket = Review::Helper::CLI::Serve->listen_socket($port, $listen)

A listening L<IO::Socket::IP> on C<$listen> (default C<127.0.0.1>), an
address or a host name, port C<$port>. Port 0 picks a free port;
C<< $socket->sockhost >> and C<< $socket->sockport >> say where it is bound.
Dies when it cannot be bound.

=item $bool = Review::Helper::CLI::Serve->is_wildcard($addr)

True for C<0.0.0.0> and C<::>, which listen on every interface.

=item @urls = Review::Helper::CLI::Serve->urls($listen, $bound, $port)

The URLs to print for a socket listening on C<$listen>, bound to the address
C<$bound>: for a loopback address, its URL; for another specific address, the
URL with C<$listen> as given; for a wildcard, the URL with this machine's
FQDN, then the loopback URL (C<[::1]> for C<::>). IPv6 addresses are put in
brackets.

=item $hex = Review::Helper::CLI::Serve->new_token()

64 hex digits from 32 bytes of F</dev/urandom>.

=item $name = Review::Helper::CLI::Serve->fqdn()

This machine's fully qualified name, as the resolver gives it for
L<Sys::Hostname>'s hostname, or the hostname when it gives none.

=item @names = Review::Helper::CLI::Serve->network_names($listen, $bound)

The host names and addresses to accept when listening beyond loopback, as
described above, without duplicates. Link-local addresses lose their zone.

=item $bool = Review::Helper::CLI::Serve->open_browser($url)

Open C<$url> in the desktop's browser. The opener runs detached, with no
terminal output, and is not waited for, since some openers return only when
the browser exits. Returns true once it is started, and false, without
trying, on platforms other than Linux and macOS. When the opener cannot be
run, a message goes to standard error.

=item Review::Helper::CLI::Serve->exec_detached($command, @args)

Run in a child process by C<open_browser>: fork, start a new session, point
standard input, output and error at F</dev/null>, and exec C<$command>. The
calling process exits at once; it never returns.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
