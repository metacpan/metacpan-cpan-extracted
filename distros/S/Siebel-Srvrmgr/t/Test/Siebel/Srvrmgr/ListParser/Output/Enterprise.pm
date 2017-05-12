package Test::Siebel::Srvrmgr::ListParser::Output::Enterprise;

use Test::Most;
use parent 'Test::Siebel::Srvrmgr::ListParser::Output';

sub class_attributes : Tests {

    my $test = shift;

    $test->SUPER::class_attributes(
        [
            'version',         'patch',
            'copyright',       'total_servers',
            'total_connected', 'help'
        ]
    );

}

sub get_data_type {

    return 'greetings';

}

sub class_methods : Tests(+5) {

    my $test = shift;

    $test->SUPER::class_methods(
        [
            qw(get_version get_patch get_copyright get_total_servers get_total_conn get_help)
        ]
    );

    is( $test->get_output()->get_version(),
        '8.0.0.2', 'can get the correct version' );
    is( $test->get_output()->get_patch(), '20412',
        'can get the correct patch' );
    is( ref( $test->get_output()->get_copyright() ),
        'ARRAY', 'can get the correct copyright' );
    is( $test->get_output()->get_total_servers(),
        1, 'can get the correct number of configured servers' );

    is( $test->get_output()->get_total_conn(),
        1, 'can get the correct number of available servers' );

}

1;
