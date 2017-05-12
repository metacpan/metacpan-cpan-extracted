use Mojo::Base qw{ -strict };

use Mojolicious;
use Mojo::IOLoop;
use Mojo::URL;
use Mojo::IOLoop::Server;

local $SIG{KILL} = $SIG{INT} = $SIG{TERM} = sub {
    stop_server();
    exit;
};

my $_servers = {};

sub get_server { $_servers->{$_[0]} || +{} }

sub generate_port {
    ( $Mojolicious::VERSION >= 5.0 )
      ? Mojo::IOLoop::Server->generate_port
      : Mojo::IOLoop->generate_port;
}

sub start_server {
    my $app  = shift;
    my $args = { @_ };
    my $port = delete( $args->{port} ) || generate_port();

    my $pid = open my $fh, '|-'; # fork
    $fh->autoflush;

    # parent
    if ($pid) {
        my $url = Mojo::URL->new("http://127.0.0.1:$port");
        $_servers->{$pid} = { url => $url, fh => $fh };
        # check started
        sleep 1 while !IO::Socket::INET->new(
            Proto    => 'tcp',
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
        );
        return (wantarray) ? ( $url, $pid ) : $url;
    }
    # child
    else {
        local $SIG{KILL} = $SIG{INT} = $SIG{TERM} = 'DEFAULT';
        setpgrp or die "$!";
        my @args = ( @{ $args->{options} || [] }, '-l', "http://127.0.0.1:$port" );
        # start server daemon
        open my $server, '|-', $^X, $app, @args;
        $server->autoflush;
        while (<>) { chomp; print $server $_ }
    }
}

sub stop_server {
    my @list_pid = ( @_ ) ? @_ : keys %$_servers;
    for my $pid ( @list_pid ) {
        unless ( kill 0, $pid ) {
            warn "already stopped: $pid";
            next;
        }
        kill -15, getpgrp $pid; # send SIGTERM to process-group of server daemon
        waitpid $pid, 0;
        delete $_servers->{$pid};
    }
}

1;
