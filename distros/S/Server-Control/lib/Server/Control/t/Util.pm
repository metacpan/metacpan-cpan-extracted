package Server::Control::t::Util;
use base qw(Test::Class);
use File::Temp qw(tempdir);
use Guard;
use Test::Most;
use Server::Control::Util
  qw(is_port_active kill_my_children process_listening_to_port something_is_listening_msg);
use Net::Server;
use strict;
use warnings;

sub test_startup : Tests(startup) {
    my $self = shift;

    my $parent_pid = $$;
    $self->{stop_guard} = guard( sub { cleanup() if $$ == $parent_pid } );
}

sub test_listening : Test(5) {
    my $port      = 15432;
    my $bind_addr = 'localhost';

    die "port $port active - cannot run test"
      if is_port_active( $port, $bind_addr );

    use_ok('Unix::Lsof');

    my $temp_dir =
      tempdir( 'Server-Control-XXXX', DIR => '/tmp', CLEANUP => 1 );
    my $error_log = "$temp_dir/error.log";

    # Fork and start another server listening on same port
    my $child = fork();
    if ( !$child ) {
        Net::Server->run( port => $port, log_file => $error_log );
        exit;
    }
    sleep(1);

    ok( is_port_active( $port, $bind_addr ), "port active now" );
    my $proc = process_listening_to_port( $port, $bind_addr );
    isa_ok( $proc, 'Proc::ProcessTable::Process', "got proc" );
    is( $proc->pid, $child, "got pid $child" );
    like(
        something_is_listening_msg( $port, $bind_addr ),
        qr/something \(possibly pid $child - ".*perl.*"\) is listening to $bind_addr:$port/,
        "got right listening message"
    );

    kill 15, $child;
}

sub cleanup {
    kill_my_children();
}

1;
