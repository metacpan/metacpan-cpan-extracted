package Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListParams;

use base 'Test::Siebel::Srvrmgr::Daemon::Action::Serializable';
use Test::Most;

sub recover_me : Test(+1) {
    my $test = shift;
    $test->SUPER::recover_me();
    my $params = $test->recover( $test->get_dump() );
    isa_ok(
        $params,
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams',
        'component definitions were recovered successfuly'
    );
}

1;

