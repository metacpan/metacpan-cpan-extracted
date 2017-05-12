package Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListCompDef;

use base 'Test::Siebel::Srvrmgr::Daemon::Action::Serializable';
use Test::Most;

sub recover_me : Test(+1) {
    my $test = shift;
    $test->SUPER::recover_me();
    my $defs = $test->recover( $test->get_dump() );
    is( ref($defs), 'HASH',
        'component definitions were recovered successfuly' );
}

1;

