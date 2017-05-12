package Net::IMAP::Server::Test;
use base qw/Test::More/;

use strict;
use warnings;

use Socket;
use AnyEvent;
AnyEvent::detect();
use IO::Socket::SSL;
use Time::HiRes qw();

my $PPID = $$;
sub PORT()     { 2000 + $PPID*2 }
sub SSL_PORT() { 2001 + $PPID*2 }

sub import_extra {
    my $class = shift;
    Test::More->export_to_level(2);
    binmode $class->builder->output, ":utf8";
}

my $pid;
sub start_server {
    my $class = shift;
    $class->stop_server;
    unless ( $pid = fork ) {
        require Net::IMAP::Server::Test::Server;
        Net::IMAP::Server::Test::Server->new(
            auth_class => "Net::IMAP::Server::Test::Auth",
            port       => "127.0.0.1:".PORT,
            ssl_port   => "127.0.0.1:".SSL_PORT,
            group      => $(,
            user       => $<,
            @_
        )->run;
        exit;
    }
    return $pid;
}

sub start_server_ok {
    my $class = shift;
    my $msg = @_ % 2 ? shift @_ : "Server started";
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok($class->start_server(@_), $msg);
}

sub as {
    my $class = shift;
    my ($as) = @_;
    $as =~ s/\W//g;
    $as = "SOCKET_$as";
    my $newclass = $class."::".$as;
    return $newclass if exists $class->builder->{$as};
    eval "{ package $newclass; our \@ISA = 'Net::IMAP::Server::Test'; sub socket_key { '$as' }; }";
    $class->builder->{$as} = undef;
    return $newclass;
}

sub socket_key { "SOCKET" };

sub connect {
    my $class = shift;
    my %args = (
        PeerAddr        => '127.0.0.1',
        PeerPort        => SSL_PORT,
        Class           => "IO::Socket::SSL",
        SSL_ca_file     => "certs/server-cert.pem",
        @_
    );
    my $socketclass = delete $args{Class};
    my $start = Time::HiRes::time();
    while (Time::HiRes::time() - $start < 10) {
        my $socket = $socketclass->new( %args );
        return $class->builder->{$class->socket_key} = $socket if $socket;
        Time::HiRes::sleep(0.1);
    }
    return;
}

sub connected {
    my $class = shift;
    my $socket = $class->get_socket;
    return 0 unless $socket->connected;

    my $buf;
    # We intentionally use the non-OO recv function here,
    # IO::Socket::SSL doesn't define a recv, and we want the low-level,
    # not under a layer version, anyways.
    my $waiting = recv($socket, $buf, 1, MSG_PEEK | MSG_DONTWAIT);

    # Undef if there's nothing currently waiting
    return 1 if not defined $waiting;

    # True if there is, false if the connection is closed
    return $waiting;
}

sub get_socket {
    my $class = shift;
    return $class->builder->{$class->socket_key};
}

sub disconnect {
    my $class = shift;
    $class->get_socket->close;
    $class->builder->{$class->socket_key} = undef;
}

sub connect_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    my $msg = @_ % 2 ? shift @_ : "Connected successfully";
    my $socket = $class->connect(@_);
    Test::More::ok($socket, $msg);
    Test::More::like($socket->getline, qr/^\* OK\b/, "Got connection message");
}

sub start_tls {
    my $class = shift;
    IO::Socket::SSL->start_SSL(
        $class->get_socket,
        SSL_ca_file => "certs/server-cert.pem",
    );
}

sub start_tls_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    my ($msg) = @_;
    my $socket = $class->get_socket || return Test::More::fail("Not connected!");
    $class->start_tls($socket);
    Test::More::diag(IO::Socket::SSL::errstr())
        unless $socket->isa("IO::Socket::SSL");
    Test::More::ok(
        $socket->isa("IO::Socket::SSL"),
        $msg || "Negotiated TLS",
    );
}

sub send_cmd {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    my $cmd = shift;
    $class->send_line("tag $cmd", @_);
}

sub send_line {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    my ($cmd, $socket) = (@_, $class->get_socket);
    my $response = "";
    local $SIG{ALRM} = sub { die "Timeout" };
    alarm(5);
    eval {
        $socket->print("$cmd\r\n");
        while (my $line = $socket->getline) {
            $response .= $line;
            last if $line =~ /^(?:\+\s*$|tag\b)/;
        }
    };
    Test::More::fail("$cmd: Timed out waiting for response")
          if ($@ || "") =~ /Timeout/;
    alarm(0);
    return $response;
}

sub cmd_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    my ($cmd, $msg) = @_;
    my $socket = $class->get_socket || return Test::More::fail("Not connected: $cmd");
    my $response = $class->send_cmd($cmd, $socket);
    Test::More::like($response, qr/^tag OK\b/m, $msg || "$cmd");
    return $response;
}

sub cmd_like {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    $class->_send_like("send_cmd", @_);
}

sub line_like {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    $class->_send_like("send_line", @_);
}

sub _send_like {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    my ($method, $cmd, @match) = @_;
    my $socket = $class->get_socket || return Test::More::fail("Not connected: $cmd");
    my $response = $class->$method($cmd, $socket);
    my @got = split /\r\n/, $response;
    Test::More::fail("Got wrong number of lines of response (expect @{[scalar @match]}, got @{[scalar @got]})")
        unless @match == @got;
    for my $i (0..$#match) {
        my $match = ref $match[$i] ? $match[$i] : qr/^\Q$match[$i]\E\s*(?:\b|$)/;
        Test::More::like($got[$i], $match, "Line @{[$i+1]} of $cmd response matched");
    }
    return wantarray ? @got : $response;
}

sub mailbox_list {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    my ($base, $pattern) = @_;
    $base ||= "";
    $pattern ||= "*";
    my $ret = $class->send_cmd(qq{LIST "$base" "$pattern"});
    my %mailboxes;
    $mailboxes{$2} = $1 while $ret =~ m{^\* LIST \((\\\S+(?:\s+\\\S+)*)\) "/" "(.*?)"}mg;
    return %mailboxes;
}

sub stop_server {
    return unless $pid;
    local $?;
    kill 2, $pid;
    1 while wait > 0;
}

$SIG{$_} = sub {exit} for qw/TERM INT QUIT/;
END { stop_server() }

1;
