package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited;

use Test::Most;
use parent qw(Test::Siebel::Srvrmgr::ListParser::Output::Tabular::Struct);

sub get_sep {

    return '\\|';

}

sub get_fields_data {

    my $test = shift;
    return
'siebel1|FSMSrvr       |File System Manager                         |FSMSrvr    |SystemAux|Batch      |Online           |0               |20          ';

}

sub _constructor : Test(no_plan) {

    my $test = shift;
    $test->SUPER::_constructor( { col_sep => '|' } );

}

sub get_to_split {

    return 'AAAA|BBBB|CCCC';

}

sub class_attributes : Test(+1) {

    my $test = shift;
    $test->SUPER::class_attributes( ['trimmer'] );

}

sub class_methods : Tests(+3) {

    my $test = shift;
    $test->SUPER::class_methods;
    ok(
        $test->get_struct()->define_fields_pattern(),
        'define_fields_pattern returns true'
    );
    is_deeply(
        $test->get_struct()->get_fields( $test->get_fields_data() ),
        [
            'siebel1',             'FSMSrvr',
            'File System Manager', 'FSMSrvr',
            'SystemAux',           'Batch',
            'Online',              '0',
            '20'
        ],
        'get_fields returns an array reference with the correct fields'
    );
    is(
        $test->get_struct()->get_header_regex(),
        join( ( '(\s+)?' . $test->get_sep() ), @{ $test->get_cols() } ),
        'get_header_regex returns the correct value'
    );

}

1;
