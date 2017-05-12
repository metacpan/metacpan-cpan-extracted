package Perinci::Access::Simple::Server::Socket;

our $DATE = '2016-03-16'; # DATE
our $VERSION = '0.24'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use Data::Clean::FromJSON;
use Data::Clean::JSON;
use File::HomeDir;
use IO::Handle::Record; # to get peercred() in IO::Socket::UNIX
use IO::Select;
use IO::Socket qw(:crlf);
use IO::Socket::INET;
use IO::Socket::UNIX;
use JSON::MaybeXS;
use Perinci::Access;
use Perinci::AccessUtil qw(insert_riap_stuffs_to_res decode_args_in_riap_req);
use Proc::Daemon::Prefork;
use Time::HiRes qw(time);
use URI::Escape;

use Moo;

my $cleanser   = Data::Clean::JSON->get_cleanser;
my $cleanserfj = Data::Clean::FromJSON->get_cleanser;

has name                   => (
    is => 'rw',
    default => sub {
        my $name = $0;
        $name =~ s!.*/!!;
        $name;
    });
has daemonize              => (is => 'rw', default=>sub{0});
has pid_path               => (is => 'rw');
has scoreboard_path        => (is => 'rw');
has error_log_path         => (is => 'rw');
has access_log_path        => (is => 'rw');
has ports                  => (is => 'rw', default => sub{[]});
has unix_sockets           => (is => 'rw', default => sub{[]});
has timeout                => (is => 'rw', default => sub{120});
has require_root           => (is => 'rw', default => sub{0});
has max_clients            => (is => 'rw', default => sub{150});
has start_servers          => (is => 'rw', default => sub{3});
has max_requests_per_child => (is => 'rw', default=>sub{1000});
has _daemon                => (is => 'rw'); # Proc::Daemon::Prefork
has _server_socks          => (is => 'rw'); # store server sockets
has riap_client            => (             # Perinci::Access object
    is => 'rw',
    default => sub {
        require Perinci::Access::Perl;
        require Perinci::Access::Schemeless;
        Perinci::Access->new(
            handlers => {
                pl => Perinci::Access::Perl->new(
                    load => 0,
                    set_function_properties => {
                        #timeout => 300,
                    },
                    #use_tx            => $self->{use_tx},
                    #custom_tx_manager => $self->{custom_tx_manager},
                ),
                '' => Perinci::Access::Schemeless->new(
                    load => 0,
                    set_function_properties => {
                        #timeout => 300,
                    },
                    #use_tx            => $self->{use_tx},
                    #custom_tx_manager => $self->{custom_tx_manager},
                ),
            }
        );
    });

my $json = JSON::MaybeXS->new->allow_nonref;

sub BUILD {
    my ($self) = @_;

    my $is_root = $> ? 0 : 1;
    my $log_dir = $is_root ? "/var/log" : File::HomeDir->my_home;
    my $run_dir = $is_root ? "/var/run" : File::HomeDir->my_home;

    unless ($self->error_log_path) {
        $self->error_log_path($log_dir."/".$self->name."-error.log");
    }
    unless (defined $self->access_log_path) {
        $self->scoreboard_path($log_dir."/".$self->name.".scoreboard");
    }
    unless ($self->access_log_path) {
        $self->access_log_path($log_dir."/".$self->name."-access.log");
    }
    unless ($self->pid_path) {
        $self->pid_path($run_dir."/".$self->name.".pid");
    }
    unless ($self->_daemon) {
        my $daemon = Proc::Daemon::Prefork->new(
            name                    => $self->name,
            error_log_path          => $self->error_log_path,
            access_log_path         => $self->access_log_path,
            pid_path                => $self->pid_path,
            scoreboard_path         => $self->scoreboard_path || undef,
            daemonize               => $self->daemonize,
            prefork                 => $self->start_servers,
            max_children            => $self->max_clients,
            after_init              => sub { $self->_after_init },
            main_loop               => sub { $self->_main_loop },
            require_root            => $self->require_root,
            # currently auto reloading is turned off
        );
        $self->_daemon($daemon);
    }
}

sub DESTROY {
    my $self = shift;

    my $socks = $self->unix_sockets;
    if (defined($socks)) {
        for my $sock (@$socks) {
            unlink $sock;
        }
    }
}

sub run {
    my ($self) = @_;
    $self->_daemon->run;
}

# alias for run()
sub start {
    my $self = shift;
    $self->run(@_);
}

sub stop {
    my ($self) = @_;
    $self->_daemon->kill_running;
}

sub restart {
    my ($self) = @_;
    $self->_daemon->kill_running;
    $self->_daemon->run;
}

sub is_running {
    my ($self) = @_;
    my $pid = $self->_daemon->check_pidfile;
    $pid ? 1:0;
}

sub _after_init {
    my ($self) = @_;

    my @server_socks;
    my @server_sock_infos;
    my $ary;

    $ary = $self->unix_sockets;
    if (defined($ary) && ref($ary) ne 'ARRAY') { $ary = [split /\s*,\s*/,$ary] }
    $self->unix_sockets($ary);
    for my $path (@$ary) {
        my %args;
        $args{Listen}  = 1;
        $args{Timeout} = $self->timeout;
        $args{Local}   = $path;
        $log->infof("Binding to Unix socket %s ...", $path);
        my $sock = IO::Socket::UNIX->new(%args);
        die "Unable to bind to Unix socket $path: $@" unless $sock;
        push @server_socks, $sock;
        push @server_sock_infos, "$path (unix)";
    }

    $ary = $self->ports;
    if (defined($ary) && ref($ary) ne 'ARRAY') { $ary = [split /\s*,\s*/,$ary] }
    $self->ports($ary);
    for my $port (@$ary) {
        my %args;
        $args{Listen}  = 1;
        $args{Reuse}   = 1;
        $args{Timeout} = $self->timeout;
        if ($port =~ /^(?:0\.0\.0\.0|\*)?:?(\d+)$/) {
            $args{LocalPort} = $1;
        } elsif ($port =~ /^([^:]+):(\d+)$/) {
            $args{LocalHost} = $1;
            $args{LocalPort} = $2;
        } else {
            die "Invalid port syntax `$port`, please specify ".
                ":N or 1.2.3.4:N";
        }
        $log->infof("Binding to TCP socket %s ...", $port);
        my $sock = IO::Socket::INET->new(%args);
        die "Unable to bind to TCP socket $port" unless $sock;
        push @server_socks, $sock;
        push @server_sock_infos, "$port (tcp)";
    }

    die "Please specify at least one port or Unix socket"
        unless @server_socks;

    $self->_server_socks(\@server_socks);
    warn "Will be binding to ".join(", ", @server_sock_infos)."\n";
    $self->before_prefork();
}

sub before_prefork {}

sub _main_loop {
    my ($self) = @_;
    if ($self->_daemon->{parent_pid} == $$) {
        $log->info("Entering main loop");
    } else {
        $log->info("Child process started (PID $$)");
    }
    $self->_daemon->update_scoreboard({child_start_time=>time()});

    my $sel = IO::Select->new(@{ $self->_server_socks });

  CONN:
    for (my $i=1; $i<=$self->max_requests_per_child; $i++) {
        $self->_daemon->set_label("listening");
        my @ready = $sel->can_read();
      SOCK:
        for my $s (@ready) {
            my $sock = $s->accept();
            # sock can be undef
            next unless $sock;
            $self->{_connect_time}   = time();
            $self->_set_label_serving($sock);

            my $timeout = ${*$sock}{'io_socket_timeout'};
            my $fdset = "";
            vec($fdset, $sock->fileno, 1) = 1;

            my $last_child = 0;
          REQ:
            while (1) {
                $self->_daemon->update_scoreboard({
                    req_start_time => time(),
                    num_reqs => $i,
                    state => "R",
                });
                $self->{_start_req_time} = time();
                my $buf = $self->_sysreadline($sock, $timeout, $fdset);
                say "D1";
                last CONN unless defined $buf;

                $self->{_finish_req_time} = time();
                $log->tracef("Received line from client: %s", $buf);

                if ($buf =~ /\Aj(.*)\015?\012/) {
                    $self->{_req_json} = $1;
                } else {
                    $self->{_res} = [400, "Invalid request line"];
                    $last_child++;
                    goto FINISH_REQ;
                }

                eval {
                    $self->{_req} = $json->decode($self->{_req_json});
                    $cleanserfj->clone_and_clean($self->{_req});
                    decode_args_in_riap_req($self->{_req});
                };
                my $e = $@;
                if ($e) {
                    $self->{_res} = [400, "Invalid JSON ($e)"];
                    goto FINISH_REQ;
                }
                if (ref($self->{_req}) ne 'HASH') {
                    $self->{_res} = [400, "Invalid request (not hash)"];
                    goto FINISH_REQ;
                }

              RES:
                $self->{_start_res_time}  = time();
                $self->{_res} = $self->riap_client->request(
                    $self->{_req}{action} => $self->{_req}{uri},
                    $self->{_req});
                $self->{_finish_res_time} = time();

              FINISH_REQ:
                $self->_daemon->update_scoreboard({state => "W"});
                insert_riap_stuffs_to_res($self->{_res}, $self->{_req}{v});
                $self->{_res} = $cleanser->clone_and_clean($self->{_res});
                eval { $self->{_res_json} = $json->encode($self->{_res}) };
                $e = $@;
                if ($e) {
                    $self->{_res} = [500, "Can't encode result in JSON: $e"];
                    $self->{_res_json} = $json->encode($self->{_res});
                }
                $self->_write_sock($sock, "j".$self->{_res_json}."\015\012");
                $self->access_log($sock);
                $self->_daemon->update_scoreboard({state => "_"});

                last CONN if $last_child;
            } # while REQ
            $sock->close;
        } # for SOCK
    } # for CONN
}

sub _sysreadline {
    my ($self, $sock, $timeout, $fdset) = @_;
    if ($timeout) {
	#print STDERR "select(,,,$timeout)\n" if $DEBUG;
	my $n = select($fdset, undef, undef, $timeout);
	unless ($n) {
	    #$self->reason(defined($n) ? "Timeout" : "select: $!");
	    return undef;
	}
    }
    #print STDERR "sysread()\n" if $DEBUG;
    my $buf = "";
    while (1) {
        my $n = sysread($sock, $buf, 2048, length($buf));
        return $buf if $buf =~ /\012/ || !$n;
    }
}

sub _write_sock {
    my ($self, $sock, $buffer) = @_;
    $log->tracef("Sending to client: %s", $buffer);
    # large $buffer might need to be written in several steps, especially in
    # SSL sockets which might have smaller buffer size (like 16k)
    my $tot_written = 0;
    while (1) {
        my $written = $sock->syswrite(
            $buffer, length($buffer)-$tot_written, $tot_written);
        # XXX what to do on error, i.e. $written is undef?
        $tot_written += $written;
        last unless $tot_written < length($buffer);
    }
}

sub _set_label_serving {
    my ($self, $sock) = @_;
    # sock can be undef when client timed out
    return unless $sock;

    my $is_unix = $sock->isa('IO::Socket::UNIX');

    if ($is_unix) {
        my $sock_path = $sock->hostpath;
        $self->{_sock_peer} = $sock_path;
        my ($pid, $uid, $gid) = $sock->peercred;
        $log->trace("Unix socket info: path=$sock_path, ".
                        "pid=$pid, uid=$uid, gid=$gid");
        $self->_daemon->set_label("serving unix (pid=$pid, uid=$uid, ".
                                      "path=$sock_path)");
    } else {
        my $server_port = $sock->sockport;
        my $remote_ip   = $sock->peerhost // "127.0.0.1";
        my $remote_port = $sock->peerport;
        $self->{_sock_peer} = "$remote_ip:$remote_port";
        if ($log->is_trace) {
            $log->trace(join("",
                             "TCP socket info: ",
                             "server_port=$server_port, ",
                             "remote_ip=$remote_ip, ",
                             "remote_port=$remote_port"));
        }
        $self->_daemon->set_label("serving TCP :$server_port (".
                                      "remote=$remote_ip:$remote_port)");
    }
}

sub __safe {
    my $string = shift;
    $string =~ s/([^[:print:]])/"\\x" . unpack("H*", $1)/eg
        if defined $string;
    $string;
}

sub access_log {
    my ($self, $sock) = @_;
    return unless $self->access_log_path;

    my $max_args_len = 1000;
    my $max_resp_len = 1000;

    #my $reqh = $req->headers;
    #if ($log->is_trace) {
        #$log->tracef("\$self->{sock_peerhost}=%s, (gmtime(\$self->{_finish_req_time}))[0]=%s, \$req->method=%s, \$req->uri->as_string=%s, \$self->{_res_status}=%s, \$self->{res_content_length}=%s, ".
        #                 "\$reqh->header('referer')=%s, \$reqh->header('user-agent')=%s",
        #             $self->{_sock_peer},
        #             (gmtime($self->{_finish_req_time}))[0],
        #             $req->method,
        #             $req->uri->as_string,
        #             $self->{_res_status},
        #             $self->{_res_content_length},
        #             scalar($reqh->header("referer")),
        #             scalar($reqh->header("user-agent")),
        #         );
    #}

    my $time = POSIX::strftime("%d/%b/%Y:%H:%M:%S +0000",
                               gmtime($self->{_start_req_time}));

    $self->{_req} //= {};
    my ($args_s, $args_len, $args_partial); # args_partial = bool
    if ($self->{_req}{args}) {
        $args_s = $json->encode($self->{_req}{args});
        $args_len = length($args_s);
        $args_partial = $args_len > $max_args_len;
        $args_s = substr($args_s, 0, $self->max_args_len)
            if $args_partial;
    } else {
        $args_s = "";
        $args_len = 0;
        $args_partial = 0;
    }

    my $reqt = sprintf("%.3fms",
                       1000*($self->{_finish_req_time}-
                                 $self->{_start_req_time}));

    if (!$self->{_res}) {
        warn "BUG: No response generated";
        $self->{_res} = {};
    }
    my ($res_len, $res_partial); # res_partial = undef or partial res
    $res_len = length($self->{_res_json});
    if ($res_len > $max_resp_len) {
        $res_partial = substr($self->{_res_json}, 0, $max_resp_len);
    }

    my $rest;
    if ($self->{_finish_res_time}) {
        $rest = sprintf("%.3fms",
                        1000*($self->{_finish_res_time}-
                                  $self->{_start_res_time}));
    } else {
        $rest = "-";
    }

    my $fmt = join(
        "",
        "%s ", # client addr
        "- ", # XXX auth user
        "[%s] ", # time
        "\"%s %s\" ", # riap action + URI
        "[args %s %s] %s ", # args + reqt
        "[res %s %s] %s ", # res + rest
        "%s", # extra info
        "\n"
    );

    my $log_line = sprintf(
        $fmt,
        $self->{_sock_peer} // "?",
        $time,
        __safe($self->{_req}{action} // "-"),
        __safe($self->{_req}{uri} // "-"),
        $args_len.($args_partial ? "p" : ""), $args_s, $reqt,
        $res_len.(defined($res_partial) ? "p" : ""), $res_partial // $self->{_res_json}, $rest,
        $self->{_extra} // "",
    );
    #$log->tracef("Riap access log: %s", $log_line);

    if ($self->daemonize) {
        syswrite($self->_daemon->{_access_log}, $log_line);
    } else {
        warn $log_line;
    }
}

1;
# ABSTRACT: Implement Riap::Simple server over sockets

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Access::Simple::Server::Socket - Implement Riap::Simple server over sockets

=head1 VERSION

This document describes version 0.24 of Perinci::Access::Simple::Server::Socket (from Perl distribution Perinci-Access-Simple-Server), released on 2016-03-16.

=head1 SYNOPSIS

 #!/usr/bin/perl
 use Perinci::Access::Simple::Server::Socket;
 my $server = Perinci::Access::Simple::Server::Socket->new(
     ports                   => ['127.0.0.1:5678'],             # default none
     unix_sockets            => ['/var/run/riap-simple.sock'],  # default none
     #start_servers          => 0,                # default 3, 0=don't prefork
     #max_clients            => 0,                # default 3, 0=don't prefork
     #max_requests_per_child => 100,                            # default 1000
     #daemonize              => 1,                              # default 0
 );
 $server->run;

Or use using the included peri-sockserve script:

 % peri-sockserve -p 127.0.0.1:5678 -s /path/to/unix/sock Foo::Bar Baz::*

=head1 DESCRIPTION

This module implements L<Riap::Simple> server over sockets. It features
preforking, multiple interface and Unix sockets.

=head1 ATTRIBUTES

=head2 name => STR (default is basename of $0)

Name of server, for display in process table ('ps ax').

=head2 daemonize => BOOL (default 0)

Whether to daemonize (go into background).

=head2 riap_client => OBJ

L<Perinci::Access> (or compatible) instance.

=head2 ports => ARRAY OF STR (default [])

One or more TCP ports to listen to. Default is none. Each port can be in the
form of N, ":N", "0.0.0.0:N" (all means the same thing, to bind to all
interfaces) or "1.2.3.4:N" (to bind to a specific network interface).

A string is also accepted, it will be split (delimiter ,) beforehand.

Since server does not support any encryption, it is recommended to bind to
localhost (127.0.0.1).

=head2 unix_sockets => ARRAY OF STR (default [])

Location of Unix sockets. Default is none, which means not listening to Unix
socket. Each element should be an absolute path.

A string is also accepted, it will be split (delimiter ,) beforehand.

You must at least specify one port or one Unix socket, or server will refuse to
run.

=head2 timeout => BOOL (default 120)

Socket timeout. Will be passed to IO::Socket.

=head2 require_root => BOOL (default 0)

Whether to require running as root.

Passed to L<Proc::Daemon::Prefork>'s constructor.

=head2 pid_path => STR (default /var/run/<name>.pid or ~/<name>.pid)

Location of PID file.

=head2 scoreboard_path => STR (default /var/run/<name>.scoreboard or ~/<name>.scoreboard)

Location of scoreboard file (used for communication between parent and child
processes). If you disable this (by setting scoreboard_path => 0), autoadjusting
number of children won't work (number of children will be kept at
'start_servers').

=head2 error_log_path => STR (default /var/log/<name>-error.log or ~/<name>-error.log)

Location of error log. Default is /var/log/<name>-error.log. It will be opened
in append mode.

=head2 access_log_path => STR (default /var/log/<name>-access.log or ~/<name>-access.log)

Location of access log. It will be opened in append mode.

=head2 start_servers => INT (default 3)

Number of children to fork at the start of run. If you set this to 0, the server
becomes a nonforking one.

Tip: You can set start_servers to 0 and 'daemonize' to false for debugging.

=head2 max_clients => INT (default 150)

Maximum number of children processes to maintain. If server is busy, number of
children will be increased from the original 'start_servers' up until this
value.

=head2 max_requests_per_child => INT (default 1000)

Number of requests each child will serve until it exists.

=head1 METHODS

=for Pod::Coverage BUILD

=head2 $server = Perinci::Access::Simple::Server::Socket->new(%args)

Create a new instance of server. %args can be used to set attributes.

=head2 $server->run()

Run server.

=head2 $server->start()

Alias for run().

=head2 $server->stop()

Stop running server.

=head2 $server->restart()

Restart server.

=head2 $server->is_running() => BOOL

Check whether server is running.

=head2 $server->before_prefork()

This is a hook provided for subclasses to do something before the daemon is
preforking. For example, you can preload Perl modules here so that each child
doesn't have to load modules separately (= inefficient).

=head2 $server->access_log($sock)

Write access log entry.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-Simple-Server>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Access-Simple-Server>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-Simple-Server>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Riap::Simple>, L<Riap>, L<Rinci>

L<peri-sockserve>, simple command-line interface for this module.

L<Perinci::Access::Simple::Client>, L<Perinci::Access>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
