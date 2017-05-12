package P4::Server::Test::Server;

use strict;
use warnings;

use Cwd qw( getcwd abs_path );
use Data::Dumper;
use Error qw( :try );
use File::Basename;
use File::Path;
use File::Spec::Functions;
use File::Temp;
use IO::File;
use IPC::Cmd qw( can_run );
use Module::Locate;
use P4::Server;
use P4::Server::Test::Server::Helper::AllocateFixedPortFirst;
use P4::Server::Test::Server::Helper::ExtractFails;
use P4::Server::Test::Server::Helper::FailedExec;
use P4::Server::Test::Server::Helper::FailedSystem;
use P4::Server::Test::Server::Helper::KillChld;
use P4::Server::Test::Server::Helper::Timeout;

my $filetemplate = File::Spec->catfile(
    File::Spec->tmpdir(),
    'p4server-test-XXXXXX',
);

my $p4d_timeout;

use base qw(Test::Unit::TestCase);

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub set_up {
    # We want the timeout higher on Windows because of performance problems
    # starting p4d.
    $p4d_timeout = $^O eq 'Win32' ? 10 : 2; # seconds
}

sub tear_down {
}

sub test_new_no_args {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $expected_p4d_exe = 'p4d';
    my $expected_port = '1666';
    my $expected_log = 'log';
    my $expected_journal = 'journal';

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $self->assert_not_null( $server );
    # Check defaults
    $self->assert_equals( $expected_p4d_exe, $server->get_p4d_exe() );
    $self->assert_equals( $expected_port, $server->get_port() );
    $self->assert_equals( $expected_log, $server->get_log() );
    $self->assert_equals( $expected_journal, $server->get_journal() );
    $self->assert_equals( 0, $server->get_pid() );

    return;
}

sub test_new_args {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $expected_p4d_exe = 'p4d';
    my $expected_port = '1717';
    my $expected_log = 'log';
    my $expected_journal = 'journal';
    my $expected_timeout = 12345;

    # Timeout set differently to test the value
    my $server = P4::Server->new( {
        p4d_exe     =>  $expected_p4d_exe,
        port        =>  $expected_port,
        log         =>  $expected_log,
        journal     =>  $expected_journal,
        p4d_timeout =>  $expected_timeout,
    } );
    $self->assert_not_null( $server );
    # Check defaults
    $self->assert_equals( $expected_p4d_exe, $server->get_p4d_exe() );
    $self->assert_equals( $expected_port, $server->get_port() );
    $self->assert_equals( $expected_log, $server->get_log() );
    $self->assert_equals( $expected_journal, $server->get_journal() );
    $self->assert_equals( $expected_timeout, $server->get_p4d_timeout() );
    $self->assert_equals( 0, $server->get_pid() );

    return;
}

sub test_set_p4d_exe {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $exe_file_name = 'p4d';
    my $exe_file = can_run( $exe_file_name );
    $self->assert_not_null( $exe_file, 'Test required p4d in path' );
    $self->assert_not_equals( $exe_file_name, $exe_file );

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $server->set_p4d_exe( $exe_file );

    my $new_exe = $server->get_p4d_exe();
    $self->assert_not_null( $new_exe );
    $self->assert_equals( $exe_file, $new_exe );

    return;
}

sub test_set_p4d_undef {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $exe_file_name = 'p4d';

    # Don't need timeout. p4d never started
    my $server = P4::Server->new( {
        p4d_exe     => can_run( $exe_file_name ),
    } );

    $self->assert_not_equals( $exe_file_name, $server->get_p4d_exe() );

    $server->set_p4d_exe( undef );
    $self->assert_equals( $exe_file_name, $server->get_p4d_exe() );

    return;
}

sub test_set_p4d_exe_fail {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $exe_file = '/some/unlikely/bogus/p4d';
    $self->assert( ! -f $exe_file );
    # Check some common Windows executable extension, too
    $self->assert( ! -f $exe_file . '.exe' );
    $self->assert( ! -f $exe_file . '.bat' );

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    try {
        $server->set_p4d_exe( $exe_file );
        $self->assert( 0, 'Did not receive exception as expected' );
    }
    catch P4::Server::Exception::InvalidExe with {
        my $e = shift;
        $self->assert_equals( 'p4d', $e->role() );
        $self->assert_equals( $exe_file, $e->exe() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_init_get_p4d_timeout {
    my $self = shift;

    my $expected_timeout = 17;

    my $server = P4::Server->new( { p4d_timeout => $expected_timeout } );

    $self->assert_equals( $expected_timeout, $server->get_p4d_timeout() );

    return;
}

sub test_set_get_p4d_timeout {
    my $self = shift;

    my $expected_timeout = 17;

    # Timeout not set because that's what we're testing
    my $server = P4::Server->new();

    $self->assert_not_equals( $expected_timeout, $server->get_p4d_timeout() );

    $server->set_p4d_timeout( $expected_timeout );

    $self->assert_equals( $expected_timeout, $server->get_p4d_timeout() );

    return;
}

sub test_set_get_root_dir {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";
    my $expected_root = '/a/real/path/name';

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $server->set_root( $expected_root );
    $self->assert_equals( $expected_root, $server->get_root() );

    return;
}

sub test_set_get_root_undef {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $server->set_root();
    $self->assert_null( $server->get_root() );

    $server->set_root( undef );
    $self->assert_null( $server->get_root() );

    return;
}

sub test_create_temp_root {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();

    # Assert initial conditions
    $self->assert_null( $server->get_root() );

    $server->create_temp_root();
    my $root = $server->get_root();
    $self->assert_not_null( $root );
    $self->assert( -d $root );

    # Manuallly clean it up for this test
    rmtree( $root );

    return;
}

sub test_clean_up_root {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();

    $server->create_temp_root();
    my $root = $server->get_root();
    $self->assert_not_null( $root );
    $self->assert( -d $root );

    $server->clean_up_root();

    $self->assert( ! -d $root );

    return;
}

sub test_set_cleanup_true {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $root;
    {
        my $server = P4::Server->new( { p4d_timeout => $p4d_timeout } );
        $server->set_port( undef );
        $server->create_temp_root();
        $root = $server->get_root();

        $self->assert( -d $root );

        $server->set_cleanup( 1 );
        $server->start_p4d();
        $server->stop_p4d();
    }

    $self->assert( ! -d $root );

    return;
}

sub test_set_cleanup_false {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $root;
    {
        my $server = P4::Server->new( { p4d_timeout => $p4d_timeout } );
        $server->set_port( undef );
        $server->create_temp_root();
        $root = $server->get_root();

        $self->assert( -d $root );

        $server->set_cleanup( 0 );
        $server->start_p4d();
        $server->stop_p4d();
    }

    $self->assert( -d $root );

    rmtree( $root );

    return;
}

sub test_start_p4d_fixed_port {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # This is the only test the hardcodes the port and runs start_p4d()
    # because of the nature of the test.
    my $port = '1717';

    my $server = P4::Server->new( {
        port        => $port,
        p4d_timeout => $p4d_timeout,
    } );
    $server->create_temp_root();

    # Assert initial conditions
    $self->assert_equals( 0, $server->get_pid() );

    $server->start_p4d();

    my $pid = $server->get_pid();
    $self->assert( $pid > 0 );
    $self->assert( kill( 0, $pid ) > 0 );

    $self->_assert_p4info( $port );

    return;
}

sub test_start_p4d_dynamic_port {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $server = P4::Server->new( { p4d_timeout => $p4d_timeout } );

    $server->set_port( undef );
    $self->assert_null( $server->get_port() );

    $server->create_temp_root();
    $server->start_p4d();

    my $new_port = $server->get_port();
    $self->assert_not_null( $new_port );
    $self->_assert_p4info( $new_port );

    return;
}

# For coverage
sub test_start_p4d_dynamic_port_retry {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $server1 = P4::Server->new( { p4d_timeout => $p4d_timeout } );
    $server1->set_port( undef );
    $server1->create_temp_root();
    $server1->start_p4d();

    my $port = $server1->get_port();

    my $server2 = P4::Server::Test::Server::Helper::AllocateFixedPortFirst->new( {
        fixed_port  => $port,
        p4d_timeout => $p4d_timeout,
    } );
    $server2->set_port( undef );
    $server2->create_temp_root();
    $server2->start_p4d();

    $self->assert_not_equals( $port, $server2->get_port() );

    return;
}

sub test_start_p4d_fail_already_running {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $server = P4::Server->new( { p4d_timeout => $p4d_timeout } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->start_p4d();

    try {
        $server->start_p4d();
    }
    catch P4::Server::Exception::ServerRunning with {
        # Expected behavior
    }
    otherwise {
        $self->assert( 0, 'No or unexpected exception' );
    };

    return;
}

sub test_start_p4d_fail_port_in_use {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $server1 = P4::Server->new( { p4d_timeout => $p4d_timeout } );
    $server1->set_port( undef );
    $server1->create_temp_root();
    $server1->set_cleanup( 1 );
    try {
        $server1->start_p4d();
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected failure starting first p4d: '
                            . Dumper( $e ) );
    };

    my $port = $server1->get_port();

    my $server2 = P4::Server->new( {
        port        => $port,
        p4d_timeout => $p4d_timeout,
    } );
    $server2->create_temp_root();
    $server2->set_cleanup( 0 );
    try {
        $server2->start_p4d();
        $self->assert( 0, 'Did not receive exception as expected' );
    }
    catch P4::Server::Exception::ServerListening with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected failure starting second p4d: '
                            . Dumper( $e ) );
    };

    return;
}

sub test_start_p4d_fail_failed_exec {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Timeout not set because this test fails to start p4d deliberately
    my $server = P4::Server::Test::Server::Helper::FailedExec->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    try {
        $server->start_p4d();
    }
    catch P4::Server::Exception::FailedExec with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected failure starting first p4d: '
                            . Dumper( $e ) );
    };

    return;
}

sub test_start_p4d_fail_default_timeout {
    my $self = shift;

    $self->_start_p4d_fail_timeout_helper();

    return;
}

sub test_start_p4d_fail_specified_timeout {
    my $self = shift;

    $self->_start_p4d_fail_timeout_helper( 5 );

    return;
}

sub _start_p4d_fail_timeout_helper {
    my ($self, $timeout) = @_;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Timeout set based on the test parameters
    my $server = P4::Server::Test::Server::Helper::Timeout->new();
    if( defined( $timeout ) ) {
        $server->set_p4d_timeout( $timeout );
    }
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    my $starttime = time();
    try {
        $server->start_p4d();
    }
    catch P4::Server::Exception::FailedToStart with {
        # Expected behavior
        my $duration = time() - $starttime;
        my $expected_timeout = $server->get_p4d_timeout();
        $self->assert(
            # We'll allow the duration of the timeout to be at most 1 second
            # less than set and any amount more.
            $expected_timeout - $duration <= 1,
            "Expected $expected_timeout seconds, got $duration"
        );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected failure starting first p4d: '
                            . Dumper( $e ) );
    };

    return;
}

sub test_start_p4d_fail_child_quit {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";
    # Disable: killing yourself apparently isn't trappable on Windows
    return if( $^O eq 'MSWin32' );

    # Timeout not necessary because process never forked
    my $server = P4::Server::Test::Server::Helper::KillChld->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    try {
        $server->start_p4d();
    }
    catch P4::Server::Exception::P4DQuit with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected failure starting first p4d: '
                            . Dumper( $e ) );
    };

    return;
}

sub test_set_root_running {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";
    my $server = P4::Server->new( { p4d_timeout => $p4d_timeout } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->start_p4d();

    try {
        $server->set_root( '/some/bogus/path' );
    }
    catch P4::Server::Exception::ServerRunning with {
        # Expected behavior
    }
    otherwise {
        $self->assert( 0, 'No or unexpected exception' );
    };

    return;
}

sub test_clean_up_root_running {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $server = P4::Server->new( { p4d_timeout => $p4d_timeout } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->start_p4d();

    try {
        $server->clean_up_root();
    }
    catch P4::Server::Exception::ServerRunning with {
        # Expected behavior
    }
    otherwise {
        $self->assert( 0, 'No or unexpected exception' );
    };

    return;
}

sub test_stop_p4d {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $server = P4::Server->new( { p4d_timeout => $p4d_timeout } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    $server->start_p4d();
    my $pid = $server->get_pid();
    my $root = $server->get_root();
    my $port = $server->get_port();

    # Assert initial conditions
    $self->assert( $pid > 0 );
    $self->assert( kill( 0, $pid ) > 0 );
    $self->_assert_p4info( $port );

    $server->stop_p4d();

    $self->assert_equals( 0, $server->get_pid() );
    $self->assert_equals( 0, kill( 0, $pid ) );
    $self->_assert_p4info( $port );

    return;
}

sub test_load_journal_file {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $server = P4::Server->new( { p4d_timeout => $p4d_timeout } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    $server->start_p4d();

    my $port = $server->get_port();

    # Assert initial conditions
    $self->_assert_p4info( $port , 'initial p4 info failed' );
    $self->assert_equals( 0, $self->_get_num_clients( $port ) );

    my $cwd = getcwd();
    my $checkpoint = <<EOF;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 21615 1183413041
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183413012 1183413012 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 21615 1183413041
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183412984 1183412984 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@foobarama\@ 99 \@stephen-vances-computer.local\@ \@/some/special/path\@ \@\@ \@\@ \@svance\@ 1183413030 1183413030 0 \@Created by svance.
\@ 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.view\@ \@foobarama\@ 0 0 \@//foobarama/...\@ \@//depot/...\@ 
\@ex\@ 21615 1183413041
EOF

    my $fh = File::Temp->new( TEMPLATE => $filetemplate );
    print $fh $checkpoint;
    $server->load_journal_file( $fh->filename );

    $self->assert_equals( 1, $self->_get_num_clients( $port ) );

    return;
}

sub test_load_journal_file_system_fail_exit {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $retval = 1 << 8;

    my $server = P4::Server::Test::Server::Helper::FailedSystem->new( {
        retval      => $retval,
        p4d_timeout => $p4d_timeout,
    } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    $server->start_p4d();

    my $port = $server->get_port();

    # Assert initial conditions
    $self->_assert_p4info( $port , 'initial p4 info failed' );
    $self->assert_equals( 0, $self->_get_num_clients( $port ) );

    my $cwd = getcwd();
    my $checkpoint = <<EOF;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 21615 1183413041
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183413012 1183413012 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 21615 1183413041
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183412984 1183412984 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@foobarama\@ 99 \@stephen-vances-computer.local\@ \@/some/special/path\@ \@\@ \@\@ \@svance\@ 1183413030 1183413030 0 \@Created by svance.
\@ 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.view\@ \@foobarama\@ 0 0 \@//foobarama/...\@ \@//depot/...\@ 
\@ex\@ 21615 1183413041
EOF

    my $fh = File::Temp->new( TEMPLATE => $filetemplate );
    print $fh $checkpoint;
    try {
        $server->load_journal_file( $fh->filename );
    }
    catch P4::Server::Exception::FailedSystem with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( $retval, $e->retval ); 
    }
    otherwise {
        $self->assert( 0, 'No or unexpected exception' );
    };

    return;
}

sub test_load_journal_file_system_fail_minus_1 {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $retval = -1;

    my $server = P4::Server::Test::Server::Helper::FailedSystem->new( {
        retval      => $retval,
        p4d_timeout => $p4d_timeout,
    } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    $server->start_p4d();

    my $port = $server->get_port();

    # Assert initial conditions
    $self->_assert_p4info( $port , 'initial p4 info failed' );
    $self->assert_equals( 0, $self->_get_num_clients( $port ) );

    my $cwd = getcwd();
    my $checkpoint = <<EOF;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 21615 1183413041
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183413012 1183413012 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 21615 1183413041
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183412984 1183412984 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@foobarama\@ 99 \@stephen-vances-computer.local\@ \@/some/special/path\@ \@\@ \@\@ \@svance\@ 1183413030 1183413030 0 \@Created by svance.
\@ 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.view\@ \@foobarama\@ 0 0 \@//foobarama/...\@ \@//depot/...\@ 
\@ex\@ 21615 1183413041
EOF

    my $fh = File::Temp->new( TEMPLATE => $filetemplate );
    print $fh $checkpoint;
    try {
        $server->load_journal_file( $fh->filename );
    }
    catch P4::Server::Exception::FailedSystem with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( $retval, $e->retval ); 
    }
    otherwise {
        $self->assert( 0, 'No or unexpected exception' );
    };

    return;
}

sub test_load_journal_file_system_fail_child_die_nocore {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $retval = 127;

    my $server = P4::Server::Test::Server::Helper::FailedSystem->new( {
        retval      => $retval,
        p4d_timeout => $p4d_timeout,
    } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    $server->start_p4d();

    my $port = $server->get_port();

    # Assert initial conditions
    $self->_assert_p4info( $port , 'initial p4 info failed' );
    $self->assert_equals( 0, $self->_get_num_clients( $port ) );

    my $cwd = getcwd();
    my $checkpoint = <<EOF;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 21615 1183413041
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183413012 1183413012 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 21615 1183413041
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183412984 1183412984 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@foobarama\@ 99 \@stephen-vances-computer.local\@ \@/some/special/path\@ \@\@ \@\@ \@svance\@ 1183413030 1183413030 0 \@Created by svance.
\@ 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.view\@ \@foobarama\@ 0 0 \@//foobarama/...\@ \@//depot/...\@ 
\@ex\@ 21615 1183413041
EOF

    my $fh = File::Temp->new( TEMPLATE => $filetemplate );
    print $fh $checkpoint;
    try {
        $server->load_journal_file( $fh->filename );
    }
    catch P4::Server::Exception::FailedSystem with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( $retval, $e->retval ); 
    }
    otherwise {
        $self->assert( 0, 'No or unexpected exception' );
    };

    return;
}

sub test_load_journal_file_system_fail_child_die_core {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $retval = 127 | 128;

    my $server = P4::Server::Test::Server::Helper::FailedSystem->new( {
        retval      => $retval,
        p4d_timeout => $p4d_timeout,
    } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    $server->start_p4d();

    my $port = $server->get_port();

    # Assert initial conditions
    $self->_assert_p4info( $port , 'initial p4 info failed' );
    $self->assert_equals( 0, $self->_get_num_clients( $port ) );

    my $cwd = getcwd();
    my $checkpoint = <<EOF;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 21615 1183413041
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183413012 1183413012 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 21615 1183413041
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183412984 1183412984 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@foobarama\@ 99 \@stephen-vances-computer.local\@ \@/some/special/path\@ \@\@ \@\@ \@svance\@ 1183413030 1183413030 0 \@Created by svance.
\@ 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.view\@ \@foobarama\@ 0 0 \@//foobarama/...\@ \@//depot/...\@ 
\@ex\@ 21615 1183413041
EOF

    my $fh = File::Temp->new( TEMPLATE => $filetemplate );
    print $fh $checkpoint;
    try {
        $server->load_journal_file( $fh->filename );
    }
    catch P4::Server::Exception::FailedSystem with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( $retval, $e->retval ); 
    }
    otherwise {
        $self->assert( 0, 'No or unexpected exception' );
    };

    return;
}

sub test_load_journal_file_nonexistant {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";
    my $nojournalfile = '/some/unlikely/path/to/a/journal/file';

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    # Assert pre-conditions
    $self->assert( ! -f $nojournalfile );

    try {
        $server->load_journal_file( $nojournalfile );
    }
    catch P4::Server::Exception::NoJournalFile with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( $nojournalfile, $e->filename() );
    }
    otherwise {
        $self->assert( 0, "No or undexpected exception" );
    };

    return;
}

sub test_load_journal_string {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    my $server = P4::Server->new( { p4d_timeout => $p4d_timeout } );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    $server->start_p4d();

    my $port = $server->get_port();

    # Assert initial conditions
    $self->_assert_p4info( $port , 'initial p4 info failed' );
    $self->assert_equals( 0, $self->_get_num_clients( $port ) );

    my $cwd = getcwd();
    my $checkpoint = <<EOF;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 21615 1183413041
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183413012 1183413012 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 21615 1183413041
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183412984 1183412984 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@foobarama\@ 99 \@stephen-vances-computer.local\@ \@/some/special/path\@ \@\@ \@\@ \@svance\@ 1183413030 1183413030 0 \@Created by svance.
\@ 
\@ex\@ 21615 1183413041
\@pv\@ 1 \@db.view\@ \@foobarama\@ 0 0 \@//foobarama/...\@ \@//depot/...\@ 
\@ex\@ 21615 1183413041
EOF

    $server->load_journal_string( $checkpoint );

    $self->assert_equals( 1, $self->_get_num_clients( $port ) );

    return;
}

sub test_unpack_archive_to_root_dir {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $server->set_root( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    my $archive = $self->_get_test_data_file_name( 'unpack_test.tgz' );

    $server->unpack_archive_to_root_dir( $archive );

    my $root = $server->get_root();

    # Things we know exist in the archive
    my $checkpoint = catfile( $root, 'checkpoint' );
    $self->assert( -f $checkpoint,
        "Checkpoint file $checkpoint does not exist"
    );

    my $depotroot = catfile( $root, 'depot' );
    $self->assert( -d $depotroot, "Depot root $depotroot does not exist" );

    my $textarchive = catfile( $depotroot, 'text.txt,v' );
    $self->assert( -f $textarchive,
        "Text archive file $textarchive does not exist"
    );

    my $binarchivedir = catfile( $depotroot, 'binary.bin,d' );
    $self->assert( -d $binarchivedir,
        "Binary archive directory $binarchivedir does not exist"
    );

    my $binarchiverev = catfile( $binarchivedir, '1.1.gz' );
    $self->assert( -f $binarchiverev,
        "Binary archive revision $binarchiverev does not exist"
    );

    return;
}

sub test_unpack_archive_to_root_dir_bad_archive {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    my $archive = '/some/unlikely/archive/file/name.tgz';

    # Assert pre-conditions
    $self->assert( ! -f $archive,
        "Dummy archive file name $archive exists!"
    );

    try {
        $server->unpack_archive_to_root_dir( $archive );
    }
    catch P4::Server::Exception::NoArchiveFile with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( $archive, $e->filename() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "No or unexpected exception: " . ref( $e ) );
    };

    return;
}

sub test_unpack_archive_to_root_dir_unreadable_archive {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # We're going to skip this one on Windows because the permission model for
    # files isn't as tractable.
    return if( $^O eq 'MSWin32' );

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );

    # Enough to fake out the archive existence check
    my $fh = File::Temp->new( TEMPLATE => $filetemplate );
    print $fh 'Nothing';
    my $archive = $fh->filename;
    chmod( 0, $archive );

    # Assert pre-conditions
    $self->assert( ! -r $archive,
        "Temp archive file name $archive readable!"
    );

    try {
        $server->unpack_archive_to_root_dir( $archive );
    }
    catch P4::Server::Exception::NoArchiveFile with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( $archive, $e->filename() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "No or unexpected exception: " . ref( $e ) );
    };

    return;
}

sub test_unpack_archive_to_root_dir_undef_root {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $server->set_port( undef );

    # Enough to fake out the archive existence check
    my $fh = File::Temp->new( TEMPLATE => $filetemplate );
    print $fh 'Nothing';
    my $archive = $fh->filename;

    # Assert pre-conditions
    $self->assert_null( $server->get_root() );

    try {
        $server->unpack_archive_to_root_dir( $archive );
    }
    catch P4::Server::Exception::UndefinedRoot with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "No or unexpected exception: " . ref( $e ) );
    };

    return;
}

sub test_unpack_archive_to_root_dir_bad_root {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Don't need timeout. p4d never started
    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->set_root( '/some/unlikely/root/dir' );

    # Enough to fake out the archive existence check
    my $fh = File::Temp->new( TEMPLATE => $filetemplate );
    print $fh 'Nothing';
    my $archive = $fh->filename;

    # Assert pre-conditions
    $self->assert( ! -d $server->get_root() );

    try {
        $server->unpack_archive_to_root_dir( $archive );
    }
    catch P4::Server::Exception::BadRoot with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "No or unexpected exception: " . ref( $e ) );
    };

    return;
}

sub test_unpack_archive_to_root_dir_fail_extract {
    my $self = shift;
    #print "\nEntering ", (caller(0))[3], ' at ', __FILE__, ': ', __LINE__, "\n";

    # Don't need timeout. p4d never started
    my $server = P4::Server::Test::Server::Helper::ExtractFails->new();
    $server->create_temp_root();

    # Enough to fake out the archive existence check
    my $fh = File::Temp->new( TEMPLATE => $filetemplate );
    print $fh 'Nothing';
    my $archive = $fh->filename;

    try {
        $server->unpack_archive_to_root_dir( $archive );
        $self->assert( 0, 'Did not receive exception as expected' );
    }
    catch P4::Server::Exception::ArchiveError with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Caught unexpected exception: " . Dumper( $e ) );
    };

    return;
}

# PRIVATE NON-TEST METHODS

sub _assert_p4info {
    my ($self, $port, $message) = @_;

    my @args = (
        'p4',
        '-p', $port,
        'info'
    );

    $message = defined( $message ) ? $message : 'p4 info failed';

    my $cmd = join( ' ', @args );
    my @output = `$cmd 2>&1`;
    $self->assert_equals( 0, $? & 255, $message );
    return;
}

sub _get_num_clients {
    my ($self, $port) = @_;

    my @output = `p4 -p $port clients`;

    return scalar @output;
}

# These methods are good candidates for refactoring to a P4::Objects base
# TestCase class when these are needed for other class tests.
sub _get_test_data_dir {
    my ($self) = @_;

    my $loc = Module::Locate::locate( __PACKAGE__ );
    $self->assert_not_equals( '', $loc, "Failed to get test package" );

    my $path = abs_path( $loc );
    my $parentdir = dirname( $path );
    my $datadir = catfile( $parentdir, 'data' );

    return $datadir;
}

sub _get_test_data_file_name {
    my ($self, $filename) = @_;

    my $dir = $self->_get_test_data_dir();
    $self->assert( -d $dir, "Test data dir $dir does not exist" );

    my $path = catfile( $dir, $filename );
    $self->assert( -f $path, "Test data file $path does not exist" );

    return $path;
}

1;
