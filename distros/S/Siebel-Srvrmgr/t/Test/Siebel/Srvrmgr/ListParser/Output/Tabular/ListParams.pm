package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr::ListParser::Output::Tabular';

sub get_data_type {

    return 'list_params';

}

sub class_methods : Tests(+10) {

    my $test = shift;

    $test->SUPER::class_methods( [qw(parse get_server get_comp_alias)] );

    is( $test->get_output()->get_comp_alias(),
        'SRProc', 'get_comp_alias returns the expected component alias' );

    my $data_ref = $test->get_output->get_data_parsed;
    is( $data_ref->{LogFilePeriod}->{PA_VALUE},
        'Hourly', 'LogFilePeriod PA_VALUE is correct' );
    is( $data_ref->{LogFilePeriod}->{PA_DATATYPE},
        'String', 'LogFilePeriod PA_DATATYPE is correct' );
    is( $data_ref->{LogFilePeriod}->{PA_SCOPE},
        'Subsystem', 'LogFilePeriod PA_SCOPE is correct' );
    is(
        $data_ref->{LogFilePeriod}->{PA_SUBSYSTEM},
        'Usage Tracking',
        'LogFilePeriod PA_SUBSYSTEM is correct'
    );
    is(
        $data_ref->{LogFilePeriod}->{PA_SETLEVEL},
        'Default value',
        'LogFilePeriod PA_SETLEVEL is correct'
    );
    is( $data_ref->{LogFilePeriod}->{PA_EFF_NEXT_TASK},
        'N', 'LogFilePeriod PA_EFF_NEXT_TASK is correct' );
    is( $data_ref->{LogFilePeriod}->{PA_EFF_CMP_RSTRT},
        'N', 'LogFilePeriod PA_EFF_CMP_RSTRT is correct' );
    is( $data_ref->{LogFilePeriod}->{PA_EFF_SRVR_RSTRT},
        'N', 'LogFilePeriod PA_EFF_SRVR_RSTRT is correct' );
    is( $data_ref->{LogFilePeriod}->{PA_REQ_COMP_RCFG},
        'N', 'LogFilePeriod PA_REQ_COMP_RCFG is correct' );
    is(
        $data_ref->{LogFilePeriod}->{PA_NAME},
        'UsageTracking LogFile Period',
        'LogFilePeriod PA_NAME is correct'
    );

}

# this method validates only the parsing of the command line, the data is never used
sub parse_cmd_line : Tests(13) {

    my $test = shift;

    my @data = (
'PA_ALIAS               |PA_VALUE                                                                      |PA_DATATYPE|PA_SCOPE |PA_SUBSYSTEM               |PA_SETLEVEL     |PA_DISP_SETLEVEL              |PA_EFF_NEXT_TASK|PA_EFF_CMP_RSTRT|PA_EFF_SRVR_RSTRT|PA_REQ_COMP_RCFG|PA_NAME                                       |',
'-----------------------  ------------------------------------------------------------------------------  -----------  ---------  ---------------------------  ----------------  ------------------------------  --  --  --  --  ----------------------------------------------  ',
'CACertFileName         |                                                                              |String     |Subsystem|Networking                 |Never set       |Never set                     |N |N |Y |N |CA certificate file name                      |',
'CertFileName           |                                                                              |String     |Subsystem|Networking                 |Never set       |Never set                     |N |N |Y |N |Certificate file name                         |'
    );

    my $cmd = 'list parameters for server foobar named subsystem foo';
    note("Using command '$cmd'");
    my $parser = $test->get_mock( \@data, $cmd );
    is( $parser->get_server, 'foobar',
        'get_server returns the correct server name' );
    is( $parser->get_named_subsys, 'foo',
        'get_named_subsys returns the correct named subsystem' );
    $cmd = 'list parameters for server foobar task 12345';
    note("Using command '$cmd'");
    $parser = $test->get_mock( \@data, $cmd );
    is( $parser->get_server, 'foobar',
        'get_server returns the correct server name' );
    cmp_ok( $parser->get_task, '==', 12345,
        'get_task returns the task number' );
    $cmd = 'list parameter foobar for component FooBar';
    note("Using command '$cmd'");
    $parser = $test->get_mock( \@data, $cmd );
    is( $parser->get_comp_alias, 'FooBar',
        'get_comp_alias returns the correct alias' );
    is( $parser->get_param, 'foobar',
        'get_param returns the correct parameter name' );
    $cmd = 'list params';
    note("Using command '$cmd'");
    $parser = $test->get_mock( \@data, $cmd );
    is( $parser->get_comp_alias,   undef, 'get_comp_alias is undef' );
    is( $parser->get_param,        undef, 'get_param is undef' );
    is( $parser->get_named_subsys, undef, 'get_named_subsys is undef' );
    is( $parser->get_task,         undef, 'get_task is undef' );
    is( $parser->get_server,       undef, 'get_server is undef' );
    $cmd = 'list advanced param foobar for component FooBar';
    note("Using command '$cmd'");
    $parser = $test->get_mock( \@data, $cmd );
    is( $parser->get_comp_alias, 'FooBar',
        'get_comp_alias returns the correct alias' );
    is( $parser->get_param, 'foobar',
        'get_param returns the correct parameter name' );

}

sub get_mock {

    my $test     = shift;
    my $data_ref = shift;
    my $command  = shift;

    return Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams->new(
        {
            data_type      => 'list_params',
            raw_data       => $data_ref,
            cmd_line       => $command,
            structure_type => 'delimited',
            col_sep        => '|'
        }
    );

}

sub class_attributes : Tests(no_plan) {

    my $test = shift;

    $test->SUPER::class_attributes( [qw(server comp_alias)] );

}

1;
