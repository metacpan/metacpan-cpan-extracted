package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers;

use Test::Most 0.25;
use Test::Moose 2.1605;
use Scalar::Util qw(blessed looks_like_number);
use parent 'Test::Siebel::Srvrmgr::ListParser::Output::Tabular';

sub get_data_type {
    return 'list_servers';
}

sub get_cmd_line {
    return 'list servers';
}

sub class_methods : Tests(+6) {
    my $test = shift;
    local $ENV{SIEBEL_TZ} = 'America/Sao_Paulo';
    my $list_servers = $test->get_output;
    does_ok(
        $list_servers,
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ByServer',
        'uses the ByServer role'
    );
    cmp_deeply( $list_servers->get_servers(),
        ('sieb_serv057'), 'get_servers returns the expected servers' );
    my $iterator = $list_servers->get_servers_iter;
    isa_ok( $iterator, 'CODE' );
    my $server = $iterator->();
    isa_ok(
        $server,
        'Siebel::Srvrmgr::ListParser::Output::ListServers::Server',
        'iterator returned data'
    );
    ok(
        looks_like_number( $list_servers->count_servers ),
        'count_servers method returns a number'
    );

    # got from Data::Dumper
    my $parsed_data = {
        'sieb_serv057' => {
            'SBLSRVR_STATE'      => 'Running',
            'SBLSRVR_STATUS'     => '8.1.1.11 [23030] LANG_INDEPENDENT',
            'START_TIME'         => '2016-09-22 14:17:33',
            'INSTALL_DIR'        => '/foobar/siebel/81/siebsrvr',
            'SBLMGR_PID'         => '1431',
            'SV_DISP_STATE'      => 'Running',
            'END_TIME'           => '',
            'SBLSRVR_GROUP_NAME' => '',
            'HOST_NAME'          => 'sieb_serv057',
            'SV_SRVRID'          => '1'
        }
    };
    cmp_deeply(
        $parsed_data,
        $test->get_output()->get_data_parsed(),
        'get_data_parsed() returns the correct data structure'
    );
}

1;
