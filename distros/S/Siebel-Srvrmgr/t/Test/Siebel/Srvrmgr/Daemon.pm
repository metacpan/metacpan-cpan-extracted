package Test::Siebel::Srvrmgr::Daemon;

use Test::Most;
use File::Spec;
use Test::Moose 'has_attribute_ok';
use Siebel::Srvrmgr::Daemon;
use Siebel::Srvrmgr::Daemon::Command;
use Log::Log4perl;
use Test::TempDir::Tiny;
use Scalar::Util qw(blessed);
use Test::Differences 0.63;
use Cwd;
use Siebel::Srvrmgr;
use Carp qw(cluck);
use Siebel::Srvrmgr::Connection;

use parent 'Test::Siebel::Srvrmgr';

$SIG{INT} = \&clean_up;

sub _set_log {
    my $test = shift;
    $test->{tmp_dir} = tempdir();
    my $log_file = File::Spec->catfile( $test->{tmp_dir}, 'daemon.log' );
    $test->{log_cfg} = File::Spec->catfile( $test->{tmp_dir}, 'log4perl.cfg' );
    open( my $out, '>', $test->{log_cfg} )
      or die 'Cannot create ' . $test->{log_cfg} . ": $!\n";
    print $out <<BLOCK;
log4perl.logger.Siebel.Srvrmgr.Daemon = WARN, LOG1
log4perl.appender.LOG1 = Log::Log4perl::Appender::File
log4perl.appender.LOG1.filename  = $log_file
log4perl.appender.LOG1.mode = clobber
log4perl.appender.LOG1.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG1.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n
BLOCK
    close($out) or die 'Could not close ' . $test->{log_cfg} . ": $!\n";
    $ENV{SIEBEL_SRVRMGR_DEBUG} = $test->{log_cfg};
    $test->{log_file} = $log_file;
}

sub _constructor : Test(2) {
    my $test = shift;
    $test->_set_log();

  SKIP: {
        skip 'superclass only validates commands with _setup_commands', 2
          if ( $test->class() eq 'Siebel::Srvrmgr::Daemon' );

        $test->{conn} = Siebel::Srvrmgr::Connection->new(
            {
                bin =>
                  File::Spec->catfile( 'blib', 'script', 'srvrmgr-mock.pl' ),
                user       => 'foo',
                password   => 'bar',
                gateway    => 'foobar',
                enterprise => 'foobar',
            }
        );

        ok(
            $test->{daemon} = $test->class()->new(
                {
                    lock_dir   => $test->{tmp_dir},
                    has_lock   => 1,
                    use_perl   => 1,
                    time_zone  => 'America/Sao_Paulo',
                    connection => $test->{conn},
                    commands   => [
                        Siebel::Srvrmgr::Daemon::Command->new(
                            command => 'load preferences',
                            action  => 'LoadPreferences'
                        ),
                        Siebel::Srvrmgr::Daemon::Command->new(
                            command => 'list comp type',
                            action  => 'ListCompTypes',
                            params  => ['dump1']
                        ),
                        Siebel::Srvrmgr::Daemon::Command->new(
                            command => 'list comp',
                            action  => 'ListComps',
                            params  => ['dump2']
                        ),
                        Siebel::Srvrmgr::Daemon::Command->new(
                            command => 'list comp def',
                            action  => 'ListCompDef',
                            params  => ['dump3']
                        )
                    ]
                }
            ),
            '... and the constructor should succeed'
        );

        isa_ok( $test->{daemon}, $test->class() );

    }    # end of SKIP

    unless (( defined( $test->{daemon} ) )
        and ( $test->{daemon}->isa( $test->class() ) ) )
    {
        note(
'Explicit disabling some tests for superclass Siebel::Srvrmgr::Daemon'
        );
        $test->{daemon} = $test->class();
    }

}

sub class_methods : Test {
    my $test = shift;
    can_ok(
        $test->{daemon},
        (
            'get_commands',    'set_commands',
            '_setup_commands', 'run',
            'DEMOLISH',        'shift_command',
            'use_perl',        '_set_child_runs',
            '_check_error',    'check_cmd',
            'clear_raw',       'set_clear_raw',
            'use_perl',        'set_alarm',
            'get_alarm',       'get_time_zone',
            'push_command',    'cmds_vs_tree'
        )
    );
}

sub class_methods2 : Test(4) {
    my $test = shift;
    dies_ok { $test->{daemon}->check_cmd('shutdown comp foobar') }
    'check_cmd raises an exception with shutdown command';
    dies_ok { $test->{daemon}->check_cmd('change parameter foobar') }
    'check_cmd raises an exception with change command';

  SKIP: {
        skip 'Siebel::Srvrmgr::Daemon cannot run these methods', 2
          if ( $test->class() eq 'Siebel::Srvrmgr::Daemon' );
        ok( $test->{daemon}->_setup_commands(), '_setup_commands works' );
        isa_ok( Siebel::Srvrmgr->gimme_logger( $test->class() ),
            'Log::Log4perl::Logger' );
    }

}

sub class_attributes : Tests {
    my ( $test, $attribs_ref ) = @_;
    my @attribs = (
        'commands',  'use_perl', 'child_runs', 'alarm_timeout',
        'clear_raw', 'time_zone'
    );

    if (    ( defined($attribs_ref) )
        and ( ref($attribs_ref) eq 'ARRAY' )
        and ( scalar( @{$attribs_ref} ) > 0 ) )
    {
        $test->num_method_tests( 'class_attributes',
            ( scalar(@attribs) + scalar( @{$attribs_ref} ) ) );

        foreach my $attribute ( @attribs, @{$attribs_ref} ) {
            has_attribute_ok( $test->{daemon}, $attribute );
        }

    }
    else {
        $test->num_method_tests( 'class_attributes', scalar(@attribs) );

        foreach my $attribute (@attribs) {
            has_attribute_ok( $test->{daemon}, $attribute );
        }

    }

}

sub the_last_run : Test(1) {
    my $test = shift;

  SKIP: {

# :WORKAROUND:06-06-2015 16:05:20:: modified to execute only in development since there are smokers running tests
# in parallel and the locking will cause exception because of that
        skip 'Not a developer machine', 1
          unless ( $ENV{SIEBEL_SRVRMGR_DEVEL} );
        skip 'only subclasses are capable of calling run method', 1
          unless ( $test->class() ne 'Siebel::Srvrmgr::Daemon' );

        my $daemon2 = $test->class()->new(
            {
                has_lock   => 1,
                lock_dir   => $test->{tmp_dir},
                use_perl   => 1,
                time_zone  => 'America/Sao_Paulo',
                connection => $test->{conn},
                , # important to avoid calling another interpreter besides perl when invoked by IPC::Open3
                commands => [
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'load preferences',
                        action  => 'LoadPreferences'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp type',
                        action  => 'ListCompTypes',
                        params  => ['dump1']
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp',
                        action  => 'ListComps',
                        params  => ['dump2']
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp def',
                        action  => 'ListCompDef',
                        params  => ['dump3']
                    )
                ]
            }
        );

        note('Testing lock control');
        my $fake_pid = $$ * 2;
        open( my $out, '>', $test->{lock_file} )
          or confess( 'Cannot change ' . $test->{lock_file} . $! );
        print $out $fake_pid;
        close($out);
        dies_ok { $daemon2->run( $test->{conn} ) }
        'a second instance cannot run while there is a lock available';

    }

}

sub runs : Test(18) {
    my $test  = shift;
    my $class = blessed( $test->{daemon} );

  SKIP: {
        skip
          'only subclasses of Siebel::Srvrmgr::Daemon can execute those tests',
          18
          unless ( defined($class)
            and ( $class ne 'Siebel::Srvrmgr::Daemon' ) );
        ok(
            $test->{daemon}->run( $test->{conn} ),
            'run method executes successfuly'
        );
        my $lock_file = $test->{daemon}->get_lock_file;
        $test->{lock_file} = $lock_file;
        is( $test->{daemon}->get_child_runs(),
            1, 'get_child_runs returns the expected number' );
        ok( my @originals = @{ $test->{daemon}->get_commands() },
            'get_commands works' );
        ok( my $shifted_cmd = $test->{daemon}->shift_command(),
            'shift_command works' );
        isa_ok( $shifted_cmd, 'Siebel::Srvrmgr::Daemon::Command' );
        ok( $test->{daemon}->shift_command(), 'shift_command works' );
        ok( $test->{daemon}->shift_command(), 'shift_command works' );
        is( $test->{daemon}->shift_command(),
            undef, 'last shift_command returns undef' );
        is( scalar( @{ $test->{daemon}->get_commands } ),
            0, 'get_commands now returns zero commands' );
        ok(
            $test->{daemon}->push_command(
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'load preferences',
                    action  => 'LoadPreferences',
                )
            ),
            'push_command works'
        );
        ok(
            $test->{daemon}->push_command(
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp type',
                    action  => 'ListCompTypes',
                    params  => ['dump1']
                )
            ),
            'push_command works'
        );
        ok(
            $test->{daemon}->push_command(
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp',
                    action  => 'ListComps',
                    params  => ['dump2']
                )
            ),
            'push_command works'
        );
        ok(
            $test->{daemon}->push_command(
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list comp def',
                    action  => 'ListCompDef',
                    params  => ['dump3']
                )
            ),
            'push_command works'
        );
        eq_or_diff_data( $test->{daemon}->get_commands,
            \@originals, 'get_commands returns the original set of commands' );
        ok(
            $test->{daemon}->run( $test->{conn} ),
            'run method executes successfuly (2)'
        );
        is( $test->{daemon}->get_child_runs(),
            2, 'get_child_runs returns the expected number' );
        ok(
            $test->{daemon}->run( $test->{conn} ),
            'run method executes successfuly (3)'
        );
        is( $test->{daemon}->get_child_runs(),
            3, 'get_child_runs returns the expected number' );

    }

}

sub clean_up : Test(shutdown) {
    my $test = shift;

    # attempt to force log4perl to close the log file on Win32
    if ( exists( $test->{daemon} ) ) {
        delete( $test->{daemon} );
    }

    sleep 5;

    # removes the dump files
    my $dir = getcwd();
    my @files;
    opendir( DIR, $dir ) or die "Cannot read $dir: $!\n";

    while ( readdir(DIR) ) {

        if ( defined($_) ) {
            push( @files, $_ ) if (/^dump\w/);
        }

    }

    close(DIR);

    foreach my $file (@files) {

        if ( -e $file ) {
            my $exit = unlink $file;

            if ($exit) {
                note("$file removed successfully");
            }
            else {
                note("Cannot remove $file: $!");
            }

        }

    }

    $ENV{SIEBEL_SRVRMGR_DEBUG} = undef;

}

1;

