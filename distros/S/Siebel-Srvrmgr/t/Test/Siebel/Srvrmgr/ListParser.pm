package Test::Siebel::Srvrmgr::ListParser;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use parent 'Test::Siebel::Srvrmgr';
use Siebel::Srvrmgr::Regexes qw(SRVRMGR_PROMPT prompt_slices);

sub get_col_sep {
    my $self = shift;
    return $self->{col_sep};
}

sub count_cmds {
    my $test     = shift;
    my $data_ref = $test->get_my_data();
    my $counter  = 0;

    foreach my $line ( @{$data_ref} ) {
        if ( $line =~ SRVRMGR_PROMPT ) {
            my ( $server, $cmd ) = prompt_slices($line);
            $counter++ if ( defined($cmd) );
        }
    }

    return $counter;
}

sub class_attributes : Tests(no_plan) {
    my $test    = shift;
    my @attribs = (
        'parsed_tree',  'has_tree',
        'last_command', 'is_cmd_changed',
        'buffer',       'enterprise',
        'clear_raw',    'fsa',
        'field_delimiter'
    );

    $test->num_tests( scalar(@attribs) );

    foreach my $attrib (@attribs) {
        has_attribute_ok( $test->{parser}, $attrib );
    }

}

sub _constructor : Test(2) {
    my $test = shift;
    note( 'Validating the file ' . $test->get_output_file );

    if ( $test->get_col_sep() ) {
        ok(
            $test->{parser} =
              $test->class()
              ->new( { field_delimiter => $test->get_col_sep() } ),
            'it is possible to create an instance'
        );
    }
    else {
        ok(
            $test->{parser} = $test->class()->new(),
            'it is possible to create an instance'
        );
    }

    isa_ok( $test->{parser}, $test->class(),
        'the instance is from the expected class' );

}

sub class_methods : Tests(11) {
    my $test = shift;
    can_ok(
        $test->{parser},
        (
            'get_parsed_tree', 'get_last_command',
            'is_cmd_changed',  'set_last_command',
            'set_buffer',      'clear_buffer',
            'count_parsed',    'clear_parsed_tree',
            'set_parsed_tree', 'append_output',
            'parse',           'get_buffer',
            'new',             'get_enterprise',
            '_set_enterprise'
        )
    );

    is(
        ref( $test->{parser}->get_buffer() ),
        ref( [] ),
        'get_buffer returns an array reference'
    );

    ok( $test->{parser}->parse( $test->get_my_data() ), 'parse method works' );
    isa_ok( $test->{parser}->get_enterprise(),
        'Siebel::Srvrmgr::ListParser::Output::Enterprise' );
    is(
        scalar( @{ $test->{parser}->get_buffer() } ),
        scalar( @{ [] } ),
        'calling parse method automatically resets the buffer'
    );
    ok( $test->{parser}->clear_buffer(), 'clear_buffer method works' );
    ok( $test->{parser}->has_tree(),     'the parser has a parsed tree' );
    is( $test->{parser}->get_last_command(),
        '', 'get_last_command method returns the expected value' );
    is( $test->{parser}->count_parsed(),
        $test->count_cmds, 'count_parsed method returns the correct number' );
    my @data = (
        'srvrXXXXmgr> list comp',
        '',
'SV_NAME|CC_ALIAS      |CC_NAME                                     |CT_ALIAS   |CG_ALIAS |CC_RUNMODE |CP_DISP_RUN_STATE|CP_NUM_RUN_TASKS|CP_MAX_TASKS|CP_ACTV_MTS_PROCS|CP_MAX_MTS_PROCS|CP_START_TIME      |CP_END_TIME|CP_STATUS|CC_INCARN_NO|CC_DESC_TEXT|',
'-------  --------------  --------------------------------------------  -----------  ---------  -----------  -----------------  ----------------  ------------  -----------------  ----------------  -------------------  -----------  ---------  ------------  ------------  ',
'siebel1|FSMSrvr       |File System Manager                         |FSMSrvr    |SystemAux|Batch      |Online           |0               |20          |1                |1               |2014-01-06 18:22:00|           |Enabled  |            |            |',
'siebel1|SSEObjMgr_enu |Sales Object Manager (ENU)                  |AppObjMgr  |Sales    |Interactive|Online           |0               |20          |1                |1               |2014-01-06 18:22:30|           |Enabled  |            |            |',
        '',
        '10 rows returned.',
        ''
    );

    dies_ok(
        sub { $test->{parser}->parse( \@data ) },
        'parse() dies if cannot find the prompt'
    );
    like(
        $@,
        qr/could\snot\sfind\sthe\scommand\sprompt/,
        'get the correct error message'
    );

}

1;

