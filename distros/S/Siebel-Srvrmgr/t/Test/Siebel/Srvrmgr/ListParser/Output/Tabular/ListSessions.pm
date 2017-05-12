package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions;

use Test::Most;
use parent 'Test::Siebel::Srvrmgr::ListParser::Output::Tabular';

sub get_data_type {

    return 'list_sessions';

}

sub get_cmd_line {

    return 'list sessions';

}

sub class_methods : Tests(+11) {

    my $test = shift;

    my $parsed_data;

    if ( $test->get_structure_type eq 'fixed' ) {

        $parsed_data = get_fixed_data();

    }
    else {

        $parsed_data = get_del_data();

    }

    cmp_deeply(
        $parsed_data,
        $test->get_output()->get_data_parsed(),
        'get_data_parsed() returns the correct data structure'
    );

    is( ref( $test->get_output->get_alias_sessions ),
        'HASH', 'get_alias_sessions returns correct data type' );

    my @servers = $test->get_output->get_servers;

    is( scalar(@servers), 1,
        'get_servers returns the correct number of servers' );

    my $server_name = 'foobar_0002';
    is( $servers[0], $server_name, 'get correct servername from get_servers' );

    @servers = undef;

    dies_ok { $test->get_output->count_server_sessions }
'count_server_sessions causes an exception with invalid server name as parameter';
    like(
        $@,
        qr/Siebel\sServer\sname\sparameter\sis\srequired\sand\smust\sbe\svalid/,
        'correct message received from exception'
    );

    is( $test->get_output->count_server_sessions($server_name),
        '15', 'count_server_sessions returns the correct number of sessions' );

    dies_ok { $test->get_output->count_alias_sessions }
    'count_alias_sessions dies with invalid alias parameter';
    like(
        $@,
        qr/component\salias\sis\srequired\sand\smust\sbe\svalid/,
        'correct message received from exception'
    );

    my $comp_alias = 'ServerMgr';

    is( $test->get_output->count_alias_sessions($comp_alias),
        2, 'count_alias_sessions returns the correct number' );

    is(
        $test->get_output->count_sv_alias_sessions( $server_name, $comp_alias ),
        2,
        'count_sv_alias_sessions returns the correct number'
    );

}

sub get_fixed_data {

    return

      {
        'foobar_0002' => [
            [
                'ServerMgr', 'System', '54525954', '', 'Running',
                'FALSE', '', '', '', '', '', '', '', ''
            ],
            [
                'ServerMgr', 'System', '47185922', '', 'Finished',
                'FALSE', '', '', '', '', '', '', '', ''
            ],
            [
                'eCommunicationsObjMgr_esn', 'Communications',
                '36700181',                  '',
                'Finished',                  'FALSE',
                '',                          '',
                'Shared Connection Id:',     'sadmin',
                '',                          '',
                '',                          ''
            ],
            [
                'eCommunicationsObjMgr_esn', 'Communications',
                '36700178',                  '',
                'Finished',                  'FALSE',
                '',                          '',
                'Shared Connection Id:',     'AADMIN',
                '',                          '',
                '',                          ''
            ],
            [
                'eCommunicationsObjMgr_esn', 'Communications',
                '36700174',                  '',
                'Finished',                  'FALSE',
                '',                          '',
                'Shared Connection Id:',     'GZURITA',
                '',                          '',
                '',                          ''
            ],
            [
                'eCommunicationsObjMgr_esn', 'Communications',
                '36700170',                  '',
                'Finished',                  'FALSE',
                '',                          '',
                'Shared Connection Id:',     'sblanon',
                '',                          '',
                '',                          ''
            ],
            [
                'SRProc', 'SystemAux', '5242888', '', 'Running',
                'FALSE', '', '', '', '', '', '', '', ''
            ],
            [
                'SRProc', 'SystemAux', '5242885', '', 'Running',
                'FALSE', '', '', '', 'Forwarding Task',
                '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097184', '', 'Running',
                'FALSE', '', '', '', 'COMP:FSMSrvr', '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097182', '', 'Running',
                'FALSE', '', '', '', 'COMP:WfProcMgr', '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097180', '', 'Running',
                'FALSE', '', '', '', '', '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097161', '', 'Running',
                'FALSE', '', '', '', 'Response task',
                '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097160', '', 'Running',
                'FALSE', '', '', '', 'Task creation task',
                '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097159', '', 'Running',
                'FALSE', '', '', '', 'Store task', '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097157', '', 'Running',
                'FALSE', '', '', '', 'Information caching task',
                '', '', '', ''
            ]
        ]
      };

}

sub get_del_data {

    return {
        'foobar_0002' => [
            [
                'ServerMgr', 'System', '58720258', '', 'Running',
                'FALSE', '', '', '', '', '', '', '', ''
            ],
            [
                'ServerMgr', 'System', '57671682', '', 'Finished',
                'FALSE', '', '', '', '', '', '', '', ''
            ],
            [
                'eCommunicationsObjMgr_esn', 'Communications',
                '36700217',                  '',
                'Running',                   'FALSE',
                '',                          '',
                'Shared Connection Id:',     'EELENO',
                '',                          '',
                '',                          ''
            ],
            [
                'eCommunicationsObjMgr_esn',
                'Communications',
                '36700205',
                '',
                'Running',
                'FALSE',
                '',
                '',
                'Shared Connection Id: , Transaction Connection Id:',
                'AADMIN',
                '',
                '',
                '',
                ''
            ],
            [
                'eCommunicationsObjMgr_esn', 'Communications',
                '36700202',                  '',
                'Running',                   'FALSE',
                '',                          '',
                'Shared Connection Id:',     'GZURITA',
                '',                          '',
                '',                          ''
            ],
            [
                'eCommunicationsObjMgr_esn', 'Communications',
                '36700199',                  '',
                'Running',                   'FALSE',
                '',                          '',
                'Shared Connection Id:',     'sadmin',
                '',                          '',
                '',                          ''
            ],
            [
                'eCommunicationsObjMgr_esn', 'Communications',
                '36700196',                  '',
                'Finished',                  'FALSE',
                '',                          '',
                'Shared Connection Id:',     'sblanon',
                '',                          '',
                '',                          ''
            ],
            [
                'EAIObjMgr_esn', 'EAI', '26214494', '',
                'Running', 'FALSE', '', '', 'Shared Connection Id:',
                'INT_USER', '', '', '', ''
            ],
            [
                'EAIObjMgr_esn', 'EAI', '26214491', '',
                'Finished', 'FALSE', '', '', 'Shared Connection Id:',
                'INT_USER', '', '', '', ''
            ],
            [
                'SRProc', 'SystemAux', '5242885', '', 'Running',
                'FALSE', '', '', '', 'Forwarding Task',
                '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097184', '', 'Running',
                'FALSE', '', '', '', 'COMP:FSMSrvr', '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097161', '', 'Running',
                'FALSE', '', '', '', 'Response task',
                '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097160', '', 'Running',
                'FALSE', '', '', '', 'Task creation task',
                '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097159', '', 'Running',
                'FALSE', '', '', '', 'Store task', '', '', '', ''
            ],
            [
                'SRBroker', 'System', '2097157', '', 'Running',
                'FALSE', '', '', '', 'Information caching task',
                '', '', '', ''
            ]
        ]
    };

}

1;
