package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed;

use Test::Most;
use parent 'Test::Siebel::Srvrmgr::ListParser::Output::Tabular::Struct';

sub get_to_unpack {

    return
      'siebel1  FSMSrvr         File System Manager                           ';

}

sub class_methods : Tests(+3) {

    my $test = shift;

    $test->SUPER::class_methods( [qw(get_fields_pattern _set_fields_pattern)] );

    ok(
        $test->get_struct()->define_fields_pattern(
'-------  --------------  --------------------------------------------  '
        ),
        'define_fields_pattern returns true'
    );

    is_deeply(
        $test->get_struct()->get_fields( $test->get_to_unpack() ),
        [ 'siebel1', 'FSMSrvr', 'File System Manager' ],
        'get_fields returns an array reference with the correct fields'
    );

    is(
        $test->get_struct()->get_header_regex(),
        join( $test->get_sep(), @{ $test->get_cols() } ),
        'get_header_regex returns the correct value'
    );

}

1;
