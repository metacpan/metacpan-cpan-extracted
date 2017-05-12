package Test::Siebel::Srvrmgr::ListParser::Output::ListTasks::Task;

use Test::Most;
use Test::Moose;
use DateTime;
use base 'Test::Siebel::Srvrmgr';

sub set_timezone : Test(startup) {

    $ENV{SIEBEL_TZ} = 'America/Sao_Paulo';

}

sub unset_timezone : Test(shutdown) {

    delete $ENV{IEBEL_TZ};

}

sub _constructor : Tests(3) {

    my $test = shift;

    ok(
        $test->{task} = $test->class()->new(
            {
                server_name    => 'siebfoobar',
                comp_alias     => 'SRProc',
                id             => 5242888,
                pid            => 20503,
                run_state      => 'Running',
                start_datetime => '2014-08-21 02:52:00',
                end_datetime   => '2000-00-00 00:00:00',
            }
        ),
        'the constructor should succeed'
    );

    dies_ok {
        my $task = $test->class()->new(
            {
                server_name => 'siebfoobar',
                comp_alias  => 'SRProc',
                id          => 5242888,
                pid         => undef,
                run_state   => 'Running'
            }
        );
    }
    'the constructor cannot accept undefined values for attributes';

    isa_ok( $test->{task}, $test->class() );

}

sub class_attributes : Tests(no_plan) {

    my $test = shift;

    my @attribs = (
        'server_name', 'comp_alias', 'id', 'pid', 'run_state', 'run_mode',
        'start_datetime', 'end_datetime', 'curr_datetime', 'status',
        'group_alias', 'parent_id', 'incarn_no', 'label', 'type', 'ping_time',

        # from Moose roles
        'start_datetime', 'curr_datetime', 'end_datetime', 'time_zone'

    );

    $test->num_tests( scalar(@attribs) );

    for my $attrib (@attribs) {

        has_attribute_ok( $test->{task}, $attrib );

    }

}

sub class_methods : Tests(16) {

    my $test = shift;

    can_ok(
        $test->{task},      'new',
        'get_server_name',  'get_comp_alias',
        'get_id',           'get_pid',
        'get_run_state',    'get_run_mode',
        'get_start',        'get_end',
        'get_status',       'get_group_alias',
        'get_parent_id',    'get_incarn_no',
        'get_label',        'get_type',
        'get_ping_time',    'to_string',
        'to_string_header', 'get_current',
    );
    does_ok(
        $test->{task},
        'Siebel::Srvrmgr::ListParser::Output::ToString',
        'instance does ToString role'
    );
    does_ok(
        $test->{task},
        'Siebel::Srvrmgr::ListParser::Output::Duration',
        'instance does Duration role'
    );
    like( $test->{task}->get_duration,
        qr/^\d+$/, 'get_duration returns a positive integer' );
    is( $test->{task}->get_server_name(),
        'siebfoobar', 'get_server_name method returns the expected value' );
    is( $test->{task}->get_comp_alias(),
        'SRProc', 'get_comp_alias method returns the expected value' );
    is( $test->{task}->get_id(),
        5242888, 'get_id method returns the expected value' );
    is( $test->{task}->get_pid(),
        20503, 'get_pid method returns the expected value' );
    is( $test->{task}->get_run_state(),
        'Running', 'get_run_state method returns the expected value' );
    dies_ok { $test->{task}->to_string }
    'to_string expects a single character as parameter';
    my $separator = '|';
    my $string    = $test->{task}->to_string($separator);
    like(
        $string,
qr/SRProc\|\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}\|\|\|5242888\|\|\|\|20503\|\|\|Running\|siebfoobar\|2014-08-21 02:52:00\|\|/,
        'to_string returns the expected string'
    );
    my $header = $test->{task}->to_string_header($separator);
    is(
        $header,
'comp_alias|curr_datetime|end_datetime|group_alias|id|incarn_no|label|parent_id|pid|ping_time|run_mode|run_state|server_name|start_datetime|status|time_zone|type',
        'to_string_header returns the expected string'
    );

}

1;
