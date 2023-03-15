package NetServerTest;

use strict;
use IO::Socket;
use Exporter;
@NetServerTest::ISA = qw(Exporter);
@NetServerTest::EXPORT_OK = qw(prepare_test client_connect ok is like use_ok skip note diag);
my %env;
use constant debug => $ENV{'NS_DEBUG'} ? 1 : 0;

END {
    warn "# number of tests ran ".($env{'_ok_n'} || 0)." did not match number of specified tests ".($env{'_ok_N'} || 0)."\n"
        if ($env{'_ok_N'} || 0) ne ($env{'_ok_n'} || 0) && ($env{'_ok_pid'} || 0) == $$;
}

sub client_connect {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    if ($env{'ipv'} && $env{'ipv'} ne 4) {
        return IO::Socket::IP->new(@_)    if eval { require IO::Socket::IP };
        return IO::Socket::INET6->new(@_) if eval { require IO::Socket::INET6 };
        die "Could not load IO::Socket::IP or IO::Socket::INET6: $@";
    } else {
        return IO::Socket::INET->new(@_);
    }
}

# most of our tests need forking, a certain number of ports, and some pipes
sub prepare_test {
    my $args = shift || {};
    my $N = $args->{'n_tests'} || die "Missing n_tests";
    print "1..$N\n";
    %env = map {/NET_SERVER_TEST_(\w+)/; lc($1) => $ENV{$_}} grep {/^NET_SERVER_TEST_\w+$/} keys %ENV;
    $env{'_ok_N'} = $N;
    $env{'_ok_pid'} = $$;
    return if $args->{'plan_only'};

    $env{'_ok_n'} = 0;
    $env{'timeout'}  ||= 5;

    # allow for finding a hostname that we can use in our tests that appears to be valid
    if (!$env{'hostname'}) {
        eval { require Net::Server::Proto } || do { SKIP: { skip("Could not load Net::Server::Proto to lookup host: $@", $N - 1) }; exit; };
        foreach my $host (qw(localhost localhost.localdomain localhost6 * ::1)) { # try local bindings first to avoid opening external ports during testing
            my @info = eval { Net::Server::Proto->get_addr_info($host) };
            next if ! @info;
            @info = sort {$a->[2] <=> $b->[2]} @info; # try IPv4 first in the name of consistency, but let IPv6 work too
            $env{'hostname'} = $info[0]->[0];
            $env{'ipv'}      = $info[0]->[2];
            last;
        }
        die "Could not find a hostname to test connections with (tried localhost, *, ::1)" if ! $env{'hostname'};
    }

    if ($args->{'threads'}) {
        warn "# Checking can_thread\n" if debug;
        if (can_thread()) {
            ok(1, "Can thread on this platform".($@ ? " ($@)" : ''));
        } else {
            SKIP: { skip("Threads don't work on this platform", $N) };
            exit;
        }
        warn "# Checked can_thread\n"  if debug;
    } else {
        warn "# Checking can_fork\n" if debug;
        ok(can_fork(), "Can fork on this platform") || do { SKIP: { skip("Fork doesn't work on this platform", $N - 1) }; exit; };
        warn "# Checked can_fork\n"  if debug;
    }

    warn "# Getting ports\n"  if debug;
    my $ports = $env{'ports'} = get_ports($args);
    ok(scalar(@$ports), "Got needed ports (@$ports)") || do { SKIP: { skip("Couldn't get the needed ports for testing", $N - 2) }; exit };
    warn "# Got ports\n"  if debug;


    warn "# Checking pipe serialization\n" if debug;
    pipe(NST_READ, NST_WRITE);
    NST_READ->autoflush(1);
    NST_WRITE->autoflush(1);
    print NST_WRITE "22";
    is(read(NST_READ, my $buf, 2), 2, "Pipe works") || do { SKIP: { skip ("Couldn't use working pipe", $N - 3) }; exit };
    warn "# Checked pipe serialization\n" if debug;
    $env{'block_until_ready_to_test'} = sub { read(NST_READ, my $buf, 1) };
    $env{'signal_ready_to_test'}      = sub { print NST_WRITE "1"; NST_WRITE->flush; };

    return \%env;
}


sub can_fork {
    return eval {
        my $pid = fork;
        die "Trouble while forking" unless defined $pid; # can't fork
        exit unless $pid; # can fork, exit child
        1;
    } || 0;
}

sub can_thread {
    return eval {
        require threads;
        my $n = 2;
        my @thr = map { scalar threads->new(sub { return 3 }) } 1..$n;
        die "Did not create correct number of threads" if threads->list() != $n;
        my $sum = 0;
        $sum += $_->join() for @thr;
        die "Return did not match" if $sum ne $n * 3;
        1;
    } || 0;
}

sub get_ports {
    my $args = shift;
    my $start_port = $args->{'start_port'} || die "Missing start_port";
    my $n          = $args->{'n_ports'}    || die "Missing n_ports";
    my @ports;
    eval {
        local $SIG{'ALRM'} = sub { die };
        alarm $env{'timeout'};
        for my $port ($start_port .. $start_port + 99){
            my $serv = client_connect(
                LocalAddr => $env{'hostname'},
                LocalPort => $port,
                Timeout   => 2,
                Listen    => 1,
                ReuseAddr => 1, Reuse => 1,
            ) || do { warn "Couldn't open server socket on port $port: $!\n" if $env{'trace'}; next };
            my $client = client_connect(
                PeerAddr => $env{'hostname'},
                PeerPort => $port,
                Timeout  => 2,
            ) || do { warn "Couldn't open client socket on port $port: $!\n" if $env{'trace'}; next };
            my $sock = $serv->accept || do { warn "Didn't accept properly on server: $!" if $env{'trace'}; next };
            $sock->autoflush(1);
            print $sock "hi from server\n";
            $client->autoflush(1);
            print $client "hi from client\n";
            next if <$sock>   !~ /^hi from client/;
            next if <$client> !~ /^hi from server/;
            $client->close;
            $sock->close;
            push @ports, $port;
            last if @ports == $n;
        }
        alarm(0);
    };
    die "Number of ports didn't match (@ports) != $n ($@)" if @ports < $n;
    return \@ports;
}

###----------------------------------------------------------------###

sub ok {
    my ($ok, $msg, $level) = @_;
    my $n = ++$env{'_ok_n'};
    print "".($ok ? "" : "not ")."ok $n";
    print " - $msg" if defined $msg;
    print "\n" if $msg !~ /\n\Z/;
    if (! $ok) {
        my ($pkg, $file, $line) = caller($level || 0);
        print "#   failed at $file line $line\n";
    }
    return $ok;
}

sub is {
    my ($a, $b, $msg) = @_;
    if (! ok($a eq $b, $msg, 1)) {
        print "#        got: $a\n";
        print "#   expected: $b\n";
        return;
    }
    return 1;
}

sub like {
    my ($a, $b, $msg) = @_;
    if (! ok($a =~ $b, $msg, 1)) {
        print "#        got: $a\n";
        print "#   expected: $b\n";
        return;
    }
    return 1;
}

sub use_ok {
    my $pkg = shift;
    my $ok = eval("require $pkg") && eval {$pkg->import(@_);1};
    ok($ok, "use $pkg", 1) || do { print "#   failed to import $pkg: $@\n"; return 0 };
}

sub skip {
    my ($msg, $n) = @_;
    print "ok ".(++$env{'_ok_n'})." # skip $msg\n" for 1 .. $n;
    no warnings 'exiting';
    last SKIP;
}

sub note {
    for my $line (@_) {
        chomp $line;
        print "# $line\n";
    }
}

sub diag {
    for my $line (@_) {
        chomp $line;
        warn "# $line\n";
    }
}

1;
