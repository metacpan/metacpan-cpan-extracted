package Test::Siebel::Srvrmgr::ListParser::Output::LoadPreferences;

use Test::Most;
use parent qw(Test::Siebel::Srvrmgr::ListParser::Output);

sub get_data_type {

    return 'load_preferences';

}

sub get_cmd_line {

    return 'load preferences';

}

sub class_attributes : Test(no_plan) {

    my $test = shift;

    $test->SUPER::class_attributes( ['location'] );

}

sub class_methods : Tests(+1) {

    my $test = shift;

    $test->SUPER::class_methods( [qw(get_location set_location)] );

    is(
        $test->get_output()->get_location(),
        '/opt/oracle/app/product/8.0.0/siebel_1/siebsrvr/bin/.Siebel_svrmgr.pref',
        'get_location returns the correct data'
    );

}

1;

