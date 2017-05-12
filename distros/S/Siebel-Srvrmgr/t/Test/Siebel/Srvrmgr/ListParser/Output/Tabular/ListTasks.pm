package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks;

use Test::Moose;
use Test::Most;
use parent qw(Test::Siebel::Srvrmgr::ListParser::Output::Tabular);

sub set_timezone : Test(startup) {

    $ENV{SIEBEL_TZ} = 'America/Sao_Paulo';

}

sub unset_timezone : Test(shutdown) {

    delete $ENV{IEBEL_TZ};

}

sub get_data_type {

    return 'list_tasks';

}

sub get_cmd_line {

    return 'list tasks';

}

sub class_methods : Tests(no_plan) {

    my $test = shift;

    does_ok( $test->get_output(),
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ByServer' );

    $test->SUPER::class_methods( [qw(get_tasks)] );

    my @fixed_attribs = qw(server_name comp_alias id pid status);
    my @del_attribs   = (
        'run_mode',    'start_datetime', 'end_datetime', 'status',
        'group_alias', 'parent_id',      'incarn_no',    'label',
        'type',        'ping_time'
    );

    $test->num_tests(
        '+'
          . (
            (
                scalar(
                    @{ $test->get_output()->get_data_parsed()->{siebel1} }
                ) * ( scalar(@fixed_attribs) + scalar(@del_attribs) + 1 )
            ) + 13
          )
    );

    ok( $test->get_output()->get_data_parsed(), 'get_data_parsed works' );

    my $expected;

    if ( $test->get_output()->get_type() eq 'fixed' ) {

        $expected = $test->get_expected_fixed();

    }
    else {

        $expected = $test->get_expected_del();

    }

    cmp_deeply(
        $expected,
        $test->get_output()->get_data_parsed(),
        'get_data_parsed() returns the correct data structure'
    );

    cmp_deeply( $test->get_output()->get_servers(),
        (qw(siebel1)), 'get_servers() returns the expected value' );

    dies_ok { $test->get_output()->get_tasks() }
    'get_tasks dies when invoked without a Siebel server name';
    like(
        $@,
        qr/Siebel\sServer\sname\sparameter\sis\srequired\sand\smust\sbe\svalid/,
        'dies with correct message'
    );
    dies_ok { $test->get_output()->get_tasks('') }
    'get_tasks dies when invoked with an invalid Siebel server name';
    like(
        $@,
        qr/Siebel\sServer\sname\sparameter\sis\srequired\sand\smust\sbe\svalid/,
        'dies with correct message'
    );

    dies_ok { $test->get_output()->get_tasks('foobar') }
    'get_tasks dies when invoked with an unexisting Siebel server name';
    like(
        $@,
        qr/\sis\snot\savailable\sin\sthe\soutput\sparsed/,
        'dies with correct message'
    );

    my $next_task = $test->get_output()->get_tasks('siebel1');

    is( ref($next_task), 'CODE', 'get_tasks returns a code reference' );

    while ( my $task = $next_task->() ) {

        isa_ok( $task, 'Siebel::Srvrmgr::ListParser::Output::ListTasks::Task' );

        foreach my $attrib (@fixed_attribs) {

            has_attribute_ok( $task, $attrib );

        }

      SKIP: {

            skip 'These tests are for delimited output type only',
              scalar(@del_attribs)
              unless ( $test->get_output()->get_type() eq 'delimited' );

            foreach my $attrib (@del_attribs) {

                has_attribute_ok( $task, $attrib );

            }

        }

    }

    ok(
        $test->get_output()->set_data_parsed(
            {
                'my_server' => [
                    Siebel::Srvrmgr::ListParser::Output::ListTasks::Task->new(
                        {
                            comp_alias     => 'eChannelCMEObjMgr_ptb',
                            pid            => '5364',
                            run_state      => 'Completed',
                            id             => '127926815',
                            server_name    => 'siebfoobar2',
                            start_datetime => '2013-12-08 18:31:48'
                        }
                    )
                ]
            }
        ),
        'set_data_parsed works with correct parameters'
    );

    dies_ok { $test->get_output()->set_data_parsed('foobar') }
    'set_data_parsed dies with incorrect parameters';

}

sub get_expected_del {

    return {
        'siebel1' => [
            [
                'siebel1',                         'ServerMgr',
                '15728642',                        '6963',
                'Running',                         'Interactive',
                '2013-12-08 18:31:48',             '2000-00-00 00:00:00',
                'Processing "List Tasks" command', 'System',
                '',                                '0',
                '',                                'Normal',
                ''
            ],
            [
                'siebel1',             'ServerMgr',
                '14680066',            '6948',
                'Completed',           'Interactive',
                '2013-12-08 18:29:55', '2013-12-08 18:31:00',
                '',                    'System',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',             'ServerMgr',
                '13631490',            '6932',
                'Completed',           'Interactive',
                '2013-12-08 18:25:32', '2013-12-08 18:28:31',
                '',                    'System',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',             'ServerMgr',
                '12582914',            '6918',
                'Completed',           'Interactive',
                '2013-12-08 18:24:15', '2013-12-08 18:25:30',
                '',                    'System',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',
                'ServerMgr',
                '11534338',
                '6910',
                'Exited with error',
                'Interactive',
                '2013-12-08 18:23:50',
                '2013-12-08 18:24:00',
'SBL-SEC-10007: The password you have entered is not correct. Pl',
                'System',
                '',
                '0',
                '',
                'Normal',
                ''
            ],
            [
                'siebel1',
                'SvrTblCleanup',
                '8388610',
                '3294',
                'Running',
                'Background',
                '2013-12-08 17:11:30',
                '2000-00-00 00:00:00',
'Method DelCompletedDelExpiredReq for service Message Board Maintenance Service has executed 16 times -- Sleeping',
                'SystemAux',
                '',
                '0',
                'SADMIN',
                'Normal',
                ''
            ],
            [
                'siebel1',
                'SvrTaskPersist',
                '7340034',
                '3257',
                'Running',
                'Background',
                '2013-12-08 17:11:30',
                '2000-00-00 00:00:00',
'Method InsertUpdateTaskHistory for service Message Board Maintenance Service has executed 157 times -- Sleeping',
                'SystemAux',
                '',
                '0',
                'SADMIN',
                'Normal',
                ''
            ],
            [
                'siebel1',             'SRProc',
                '5242887',             '3258',
                'Running',             'Interactive',
                '2013-12-08 17:12:12', '2000-00-00 00:00:00',
                '',                    'SystemAux',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',             'SRProc',
                '5242885',             '3258',
                'Running',             'Interactive',
                '2013-12-08 17:12:03', '2000-00-00 00:00:00',
                '',                    'SystemAux',
                '',                    '0',
                'Forwarding Task',     'Worker',
                ''
            ],
            [
                'siebel1',             'SCBroker',
                '3145730',             '3226',
                'Running',             'Background',
                '2013-12-08 17:11:25', '2000-00-00 00:00:00',
                '',                    'System',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',             'SRBroker',
                '2097167',             '3225',
                'Running',             'Interactive',
                '2013-12-08 17:12:15', '2000-00-00 00:00:00',
                '',                    'System',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',             'SRBroker',
                '2097166',             '3225',
                'Running',             'Interactive',
                '2013-12-08 17:12:15', '2000-00-00 00:00:00',
                '',                    'System',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',             'SRBroker',
                '2097165',             '3225',
                'Running',             'Interactive',
                '2013-12-08 17:12:12', '2000-00-00 00:00:00',
                '',                    'System',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',             'SRBroker',
                '2097164',             '3225',
                'Running',             'Interactive',
                '2013-12-08 17:12:12', '2000-00-00 00:00:00',
                '',                    'System',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',             'SRBroker',
                '2097161',             '3225',
                'Running',             'Interactive',
                '2013-12-08 17:12:12', '2000-00-00 00:00:00',
                '',                    'System',
                '',                    '0',
                'Response task',       'Worker',
                ''
            ],
            [
                'siebel1',             'SRBroker',
                '2097160',             '3225',
                'Running',             'Interactive',
                '2013-12-08 17:12:12', '2000-00-00 00:00:00',
                '',                    'System',
                '',                    '0',
                'Store task',          'Worker',
                ''
            ],
            [
                'siebel1',             'SRBroker',
                '2097159',             '3225',
                'Running',             'Interactive',
                '2013-12-08 17:12:12', '2000-00-00 00:00:00',
                '',                    'System',
                '',                    '0',
                '',                    'Normal',
                ''
            ],
            [
                'siebel1',             'SRBroker',
                '2097158',             '3225',
                'Running',             'Interactive',
                '2013-12-08 17:12:12', '2000-00-00 00:00:00',
                '',                    'System',
                '',                    '0',
                'Task creation task',  'Worker',
                ''
            ],
            [
                'siebel1',                  'SRBroker',
                '2097157',                  '3225',
                'Running',                  'Interactive',
                '2013-12-08 17:12:12',      '2000-00-00 00:00:00',
                '',                         'System',
                '',                         '0',
                'Information caching task', 'Worker',
                ''
            ]
        ]
    };

}

sub get_expected_fixed {

    return {
        'siebel1' => [
            [ 'siebel1', 'ServerMgr', '16777218', '6974', 'Running' ],
            [ 'siebel1', 'ServerMgr', '15728642', '6963', 'Completed' ],
            [ 'siebel1', 'ServerMgr', '14680066', '6948', 'Completed' ],
            [ 'siebel1', 'ServerMgr', '13631490', '6932', 'Completed' ],
            [ 'siebel1', 'ServerMgr', '12582914', '6918', 'Completed' ],
            [ 'siebel1', 'ServerMgr', '11534338', '6910', 'Exited with error' ],
            [ 'siebel1', 'SvrTblCleanup',  '8388610', '3294', 'Running' ],
            [ 'siebel1', 'SvrTaskPersist', '7340034', '3257', 'Running' ],
            [ 'siebel1', 'SRProc',         '5242887', '3258', 'Running' ],
            [ 'siebel1', 'SRProc',         '5242885', '3258', 'Running' ],
            [ 'siebel1', 'SCBroker',       '3145730', '3226', 'Running' ],
            [ 'siebel1', 'SRBroker',       '2097167', '3225', 'Running' ],
            [ 'siebel1', 'SRBroker',       '2097166', '3225', 'Running' ],
            [ 'siebel1', 'SRBroker',       '2097165', '3225', 'Running' ],
            [ 'siebel1', 'SRBroker',       '2097164', '3225', 'Running' ],
            [ 'siebel1', 'SRBroker',       '2097161', '3225', 'Running' ],
            [ 'siebel1', 'SRBroker',       '2097160', '3225', 'Running' ],
            [ 'siebel1', 'SRBroker',       '2097159', '3225', 'Running' ],
            [ 'siebel1', 'SRBroker',       '2097158', '3225', 'Running' ],
            [ 'siebel1', 'SRBroker',       '2097157', '3225', 'Running' ]
          ]

    };

}

1;
