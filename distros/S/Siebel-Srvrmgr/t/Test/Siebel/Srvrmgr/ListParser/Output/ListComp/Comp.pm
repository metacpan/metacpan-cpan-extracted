package Test::Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;

use Test::Most;
use Test::Moose;
use parent 'Test::Siebel::Srvrmgr';
use Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp;
use Regexp::Common::time 0.07;
use Regexp::Common 2016060801 qw(time);

sub get_struct {
    my $test = shift;
    return $test->{structure_type};
}

sub get_col_sep {
    my $test = shift;
    return $test->{col_sep};
}

sub set_timezone : Test(startup) {
    $ENV{SIEBEL_TZ} = 'America/Sao_Paulo';
}

sub unset_timezone : Test(shutdown) {
    delete $ENV{IEBEL_TZ};
}

# :TODO:11-01-2014:: should refactor this because behavior is the same for other classes (maybe a Role?)
# overriding parent's because the files will have the command itself followed by the output of it
sub get_my_data {
    my $test     = shift;
    my $data_ref = $test->SUPER::get_my_data();
    shift( @{$data_ref} );    #command
    shift( @{$data_ref} );    #new line
    return $data_ref;
}

sub _constructor : Tests(2) {
    my $test = shift;
    my $list_comp;

    if ( ( $test->get_struct eq 'delimited' ) and ( $test->get_col_sep ) ) {
        $list_comp =
          Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp->new(
            {
                data_type      => 'list_comp',
                raw_data       => $test->get_my_data(),
                cmd_line       => 'list comp',
                structure_type => $test->get_struct(),
                col_sep        => $test->get_col_sep()
            }
          );
    }
    else {
        $list_comp =
          Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp->new(
            {
                data_type      => 'list_comp',
                raw_data       => $test->get_my_data(),
                cmd_line       => 'list comp',
                structure_type => $test->get_struct()
            }
          );
    }

    my $server   = $list_comp->get_server('siebel1');
    my $alias    = 'SRProc';
    my $data_ref = $server->get_data->{$alias};

    ok(
        $test->{comp} = $test->class()->new(
            {
                alias          => $alias,
                name           => $data_ref->{CC_NAME},
                ct_alias       => $data_ref->{CT_ALIAS},
                cg_alias       => $data_ref->{CG_ALIAS},
                run_mode       => $data_ref->{CC_RUNMODE},
                disp_run_state => $data_ref->{CP_DISP_RUN_STATE},
                start_mode     => $data_ref->{CP_STARTMODE},
                num_run_tasks  => $data_ref->{CP_NUM_RUN_TASKS},
                max_tasks      => $data_ref->{CP_MAX_TASKS},
                actv_mts_procs => $data_ref->{CP_ACTV_MTS_PROCS},
                max_mts_procs  => $data_ref->{CP_MAX_MTS_PROCS},
                start_datetime => $data_ref->{CP_START_TIME},
                end_datetime   => $data_ref->{CP_END_TIME},
                status         => $data_ref->{CP_STATUS},
                incarn_no      => $data_ref->{CC_INCARN_NO} || 0,
                desc_text      => $data_ref->{CC_DESC_TEXT}

            }

        ),
        'the constructor should succeed'
    );

    isa_ok( $test->{comp}, $test->class(),
        'the object is a instance of the correct class' );

}

sub class_attributes : Tests(20) {
    my $test    = shift;
    my @attribs = (
        'alias',          'name',
        'ct_alias',       'cg_alias',
        'run_mode',       'disp_run_state',
        'num_run_tasks',  'max_tasks',
        'actv_mts_procs', 'max_mts_procs',
        'start_datetime', 'end_datetime',
        'status',         'incarn_no',
        'desc_text',      'start_datetime',
        'curr_datetime',  'end_datetime',
        'time_zone',      'start_mode',
    );

    foreach my $attrib (@attribs) {
        has_attribute_ok( $test->{comp}, $attrib );
    }
}

sub class_methods : Tests(20) {
    my $test = shift;
    can_ok(
        $test->{comp},
        (
            'get_current',        'get_alias',
            'get_name',           'get_ct_alias',
            'get_cg_alias',       'get_run_mode',
            'get_disp_run_state', 'get_num_run_tasks',
            'get_max_tasks',      'get_actv_mts_procs',
            'get_max_mts_procs',  'get_start',
            'get_end',            'get_status',
            'get_incarn_no',      'get_desc_text',
            'get_start_mode',     'is_auto_start'
        )
    );
    does_ok(
        $test->{comp},
        'Siebel::Srvrmgr::ListParser::Output::ToString',
        'instance does ToString role'
    );
    does_ok(
        $test->{comp},
        'Siebel::Srvrmgr::ListParser::Output::Duration',
        'instance does Duration role'
    );
    is( $test->{comp}->get_num_run_tasks(),
        2, 'get_num_run_tasks returns the correct value' );
    is( $test->{comp}->get_incarn_no(),
        0, 'get_incarn_no returns the correct value' );
    is(
        $test->{comp}->get_name(),
        'Server Request Processor',
        'get_name returns the correct value'
    );
    is( $test->{comp}->get_ct_alias(),
        'SRProc', 'get_ct_alias returns the correct value' );
    is( $test->{comp}->get_cg_alias(),
        'SystemAux', 'get_cg_alias returns the correct value' );
    is( $test->{comp}->get_run_mode(),
        'Interactive', 'get_run_mode returns the correct value' );
    is( $test->{comp}->get_disp_run_state(),
        'Running', 'get_disp_run_state returns the correct value' );
    is( $test->{comp}->get_max_tasks(),
        20, 'get_max_tasks returns the correct value' );
    is( $test->{comp}->get_actv_mts_procs(),
        1, 'get_actv_mts_procs returns the correct value' );
    is( $test->{comp}->get_max_mts_procs(),
        1, 'get_max_mts_procs returns the correct value' );
    like( $test->{comp}->get_start(),
        qr/$RE{time}{iso}/, 'get_start returns a ISO-8601 value' );
    is( $test->{comp}->get_end, '', 'get_end returns the correct value' );
    is( $test->{comp}->get_status(),
        'Enabled', 'get_status returns the correct value' );
    is( $test->{comp}->get_desc_text(),
        '', 'get_desc_text returns the correct value' );
    like( $test->{comp}->get_duration,
        qr/\d+/, 'get_duration returns a number' );
    is( $test->{comp}->get_start_mode,
        'Auto', 'get_start_mode returns the expected value' );
    ok( $test->{comp}->is_auto_start, 'is_auto_start returns true' );

}

1;

