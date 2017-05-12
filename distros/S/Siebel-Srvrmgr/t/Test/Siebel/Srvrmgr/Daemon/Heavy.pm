package Test::Siebel::Srvrmgr::Daemon::Heavy;

use Cwd;
use Test::Most;
use File::Spec;
use Test::Moose 2.1806 qw(has_attribute_ok does_ok);
use Siebel::Srvrmgr::Daemon::Heavy;
use Config;
use parent 'Test::Siebel::Srvrmgr::Daemon';
use Siebel::Srvrmgr;

sub class_methods : Test(+1) {
    my $test = shift;
    $test->SUPER::class_methods();
    can_ok(
        $test->{daemon},
        (
            'get_commands',     'set_commands',
            'get_write',        'get_read',
            'get_last_cmd',     'get_cmd_stack',
            'get_params_stack', 'get_buffer_size',
            'set_buffer_size',  'get_prompt',
            '_set_prompt',      '_create_child',
            '_process_stderr',  '_process_stdout',
            '_check_error',     '_check_child',
            '_submit_cmd',      'close_child',
            'has_pid',          'clear_pid',
            '_manage_handlers', 'get_retries',
            'get_max_retries'
        )
    );
}

sub _constructor : Test(+1) {
    my $test = shift;
    $test->SUPER::_constructor;
    does_ok( $test->{daemon}, 'Siebel::Srvrmgr::Daemon::Connection' );
}

sub class_attributes : Tests {
    my $test    = shift;
    my @attribs = (
        'write_fh',       'read_fh',
        'child_pid',      'last_exec_cmd',
        'cmd_stack',      'params_stack',
        'action_stack',   'ipc_buffer_size',
        'srvrmgr_prompt', 'read_timeout',
        'child_pid',      'retries',
        'maximum_retries'
    );
    $test->SUPER::class_attributes( \@attribs );
}

sub runs : Tests {
    my $test = shift;
    $test->{daemon}->set_read_timeout(3);
    $test->SUPER::runs();
}

sub runs_with_stderr : Test(4) {
    my $test = shift;
    $test->{daemon}->set_commands(
        [
            Siebel::Srvrmgr::Daemon::Command->new(
                command => 'list complexquery',
                action  => 'Dummy'
            ),
        ]
    );
    ok( $test->{daemon}->run( $test->{conn} ), 'run executes OK' );
    ok(
        $test->_search_log_msg(qr/oh\sgod\,\snot\stoday/),
        'can find warn message in the log file'
    );
    $test->{daemon}->set_commands(
        [
            Siebel::Srvrmgr::Daemon::Command->new(
                command => 'list frag',
                action  => 'Dummy'
            ),
        ]
    );
    dies_ok { $test->{daemon}->run( $test->{conn} ) }
    'run dies due fatal error';
    ok(
        $test->_search_log_msg(
            qr/FATAL.*Could\snot\sfind\sthe\sSiebel\sServer/),
        'can find fatal message in the log file'
    );
}

sub _poke_child {
    my $test = shift;

    if (    ( defined( $test->{daemon}->get_pid() ) )
        and ( $test->{daemon}->get_pid() =~ /\d+/ ) )
    {

        unless ( kill 0, $test->{daemon}->get_pid() ) {
            return 0;
        }
        else {
            return 1;
        }

    }
    else {
        return 0;
    }

}

sub the_termination : Tests(4) {
    my $test   = shift;
    my $logger = Siebel::Srvrmgr->gimme_logger( $test->class() );
    ok( $test->{daemon}->close_child($logger),
        'close_child returns true (termined child process)' );
    is( $test->{daemon}->close_child($logger),
        0, 'close_child returns false since there is no PID anymore' );
    is( $test->{daemon}->has_pid(), '', 'has_pid returns false' );
    is( $test->_poke_child(),       0,  'child PID is no more' );
    $test->{daemon} = undef;
}

sub _search_log_msg {
    my ( $test, $msg_regex ) = @_;
    my $found = 0;
    open( my $in, '<', $test->{log_file} )
      or die 'Cannot read ' . $test->{log_file} . ': ' . $! . "\n";

    while (<$in>) {
        chomp();

        if (/$msg_regex/) {
            $found = 1;
            last;
        }

    }

    close($in) or die 'Cannot close ' . $test->{log_file} . ': ' . $! . "\n";
    return $found;
}

1;
