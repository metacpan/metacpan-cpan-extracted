package Server::Control::t::Base;
use base qw(Test::Class);
use File::Slurp;
use File::Temp qw(tempfile tempdir);
use Guard;
use HTTP::Server::Simple;
use Log::Any;
use Net::Server;
use POSIX qw(geteuid getegid);
use Server::Control::Util
  qw(get_child_pids kill_my_children is_port_active something_is_listening_msg);
use Test::Log::Dispatch;
use Test::Most;
use Time::HiRes qw(usleep);
use strict;
use warnings;

my $port = 15432;

sub skip_if_listening {
    my $class = shift;
    $class->SKIP_CLASS("something listening to $port")
      if is_port_active( $port, 'localhost' );
}

our @ctls;

# Moved up from Server::Control::t::NetServer::create_ctl because it is used
# in test_port_busy too
sub create_net_server_ctl {
    my ( $self, $port, $temp_dir, %extra_params ) = @_;

    require Server::Control::NetServer;
    return Server::Control::NetServer->new(
        net_server_class  => 'Net::Server::PreForkSimple',
        net_server_params => {
            max_servers => 2,
            port        => $port,
            pid_file    => $temp_dir . "/server.pid",
            log_file    => $temp_dir . "/server.log",
            user        => geteuid(),
            group       => getegid()
        },
        %extra_params
    );
}

sub test_startup : Tests(startup) {
    my $self = shift;

    my $parent_pid = $$;
    $self->{stop_guard} = guard( sub { cleanup() if $$ == $parent_pid } );
}

sub test_setup : Tests(setup) {
    my $self = shift;

    $self->{port} = $port;
    $self->{temp_dir} =
      tempdir( 'Server-Control-XXXX', DIR => '/tmp', CLEANUP => 1 );
    $self->setup_test_logger('info');
    $self->{ctl} = $self->create_ctl( $self->{port}, $self->{temp_dir} );
    push( @ctls, $self->{ctl} );
}

sub setup_test_logger {
    my ( $self, $level ) = @_;

    $self->{log} = Test::Log::Dispatch->new( min_level => $level );
    Log::Any->set_adapter( 'Dispatch', dispatcher => $self->{log} );
}

sub test_simple : Tests(12) {
    my $self = shift;
    my $ctl  = $self->{ctl};
    my $log  = $self->{log};
    my $port = $self->{port};

    ok( !$ctl->is_running(), "not running" );
    ok( !$ctl->stop() );
    $log->contains_ok( qr/server '.*' is not running/, "stop: is not running" );

    ok( $ctl->start() );
    $log->contains_ok(qr/waiting for server start/);
    $log->contains_ok(qr/is now running.* and listening to port $port/);
    ok( $ctl->is_running(), "is running" );
    ok( !$ctl->start() );
    $log->contains_ok( qr/server '.*' is already running/,
        "start: already running" );

    ok( $ctl->stop() );
    $log->contains_ok(qr/stopped/);
    ok( !$ctl->is_running(), "not running" );
}

sub test_stopstart : Tests(16) {
    my $self = shift;
    my $ctl  = $self->{ctl};
    my $log  = $self->{log};

    ok( !$ctl->is_running(), "not running" );
    ok( $ctl->stopstart() );
    ok( $ctl->is_running(), "is running" );
    ok( $ctl->stop() );
    ok( !$ctl->is_running(), "not running" );
    ok( $ctl->start() );
    ok( $ctl->is_running(), "is running" );
    ok( $ctl->stopstart() );
    ok( $ctl->is_running(), "is still running" );
    ok( $ctl->stop() );

    # Make sure stopstart aborts when stop fails
    my $orig_class  = ref($ctl);
    my $unstoppable = Class::MOP::Class->create_anon_class(
        superclasses => [$orig_class],
        methods      => {
            do_stop => sub { die "can't stop!" }
        }
    );
    bless( $ctl, $unstoppable->name );
    ok( $ctl->start() );
    ok( !$ctl->stop() );
    $log->contains_ok(qr/can't stop/);
    ok( !$ctl->stopstart() );
    $log->contains_ok(qr/could not stop.*will not attempt start/);
    bless( $ctl, $orig_class );
    ok( $ctl->stop() );
}

sub test_refork : Tests(7) {

    return 'release testing only' unless $ENV{RELEASE_TESTING};

    my $self = shift;
    my $ctl  = $self->{ctl};

    ok( $ctl->start() );
    my $proc = $ctl->is_running();
    ok( $proc, "is running" );

    my @pids = wait_for_child_pids( $proc->pid );
    ok( @pids >= 1, "at least one child pid" );
    $ctl->refork();
    usleep(500000);    # wait for pids to die

    my @pids2 = wait_for_child_pids( $proc->pid );
    ok( @pids2 >= 1, "at least one child pid after refork" );
    my %in_pids = map { ( $_, 1 ) } @pids;
    ok( !grep { $in_pids{$_} } @pids2, "none of pids2 are in pids" );

    ok( $ctl->stop() );
    ok( !$ctl->is_running(), "not running" );
}

sub wait_for_child_pids {
    my ($pid) = @_;
    my @child_pids;
    for my $count ( 0 .. 9 ) {
        Time::HiRes::sleep(0.5);
        last if @child_pids = get_child_pids($pid);
    }
    return @child_pids;
}

sub test_port_busy : Tests(6) {
    my $self = shift;
    my $ctl  = $self->{ctl};
    my $log  = $self->{log};
    my $port = $self->{port};

    # Start another server listening on same port
    my $temp_dir2 =
      tempdir( 'Server-Control-XXXX', DIR => '/tmp', CLEANUP => 1 );
    my $ctl2 = $self->create_net_server_ctl( $port, $temp_dir2 );
    ok( $ctl2->start() );

    ok( !$ctl->is_running(),  "not running" );
    ok( $ctl->is_listening(), "listening" );
    ok( !$ctl->start() );
    $log->contains_ok(
        qr/pid file '.*' does not exist, but something.*is listening to localhost:$port/
    );

    ok( $ctl2->stop() );
}

sub test_wrong_port : Tests(8) {
    my $self = shift;
    my $ctl  = $self->{ctl};
    my $log  = $self->{log};
    my $port = $self->{port};

    # Tell ctl object to expect wrong port, to simulate a server not starting properly
    my $new_port = $port + 1;
    $ctl->{port}                 = $new_port;
    $ctl->{wait_for_status_secs} = 3;
    ok( !$ctl->start() );
    $log->contains_ok(qr/waiting for server start/);
    $log->contains_ok(
        qr/after .*, server .* appears to be running \(pid .*\), but not listening to port $new_port/
    );
    ok( $ctl->is_running(),    "running" );
    ok( !$ctl->is_listening(), "not listening" );

    $ctl->{wait_for_status_secs} = 10;
    ok( $ctl->stop() );
    $log->contains_ok(qr/stopped/);
    ok( !$ctl->is_running(), "not running" );
}

sub test_corrupt_pid_file : Test(5) {
    my $self     = shift;
    my $ctl      = $self->{ctl};
    my $log      = $self->{log};
    my $pid_file = $ctl->pid_file;

    write_file( $pid_file, "blah" );
    ok( $ctl->start(), "started ok" );
    $log->contains_ok(qr/pid file '.*' does not contain a valid process id/);
    $log->contains_ok(qr/deleting bogus pid file/);
    ok( $ctl->is_running(), "is running" );
    ok( $ctl->stop() );
}

sub test_rc_file : Tests(6) {
    my $self = shift;

    my $rc_contents =
      "bind_addr: 1.2.3.4\nname: foo\nwait-for-status-secs: 7\n";
    my $temp_dir2 =
      tempdir( 'Server-Control-XXXX', DIR => '/tmp', CLEANUP => 1 );

    my $test_properties = sub {
        my $ctl = shift;
        is( $ctl->bind_addr,            "1.2.3.4", "bind_addr" );
        is( $ctl->name,                 "bar",     "name" );
        is( $ctl->wait_for_status_secs, 7,         "wait_for_status_secs" );
    };

    {
        write_file( $temp_dir2 . "/serverctl.yml", $rc_contents );
        my $ctl = $self->create_ctl(
            $self->{port}, $temp_dir2,
            server_root => $temp_dir2,
            name        => "bar"
        );
        $test_properties->($ctl);
    }

    {
        my $temp_dir3 =
          tempdir( 'Server-Control-XXXX', TMPDIR => 1, CLEANUP => 1 );
        my $rc_file = "$temp_dir3/foo.yml";
        write_file( $rc_file, $rc_contents );
        my $ctl = $self->create_ctl(
            $self->{port}, $temp_dir2,
            serverctlrc => $rc_file,
            name        => "bar"
        );
        $test_properties->($ctl);
    }
}

sub cleanup {
    foreach my $ctl (@ctls) {
        if ( $ctl->is_running() ) {
            $ctl->stop();
        }
    }
    kill_my_children();
}

1;
