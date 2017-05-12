package Test::Siebel::Srvrmgr::Daemon::Light;

use Test::Most 0.35;
use Test::Moose 2.1806 qw(has_attribute_ok does_ok);
use base 'Test::Siebel::Srvrmgr::Daemon';

sub _constructor : Test(+1) {
    my $test = shift;
    $test->SUPER::_constructor;
    does_ok( $test->{daemon}, 'Siebel::Srvrmgr::Daemon::Connection' );
}

sub class_methods : Test(+2) {
    my $test = shift;
    $test->SUPER::class_methods();
    can_ok(
        $test->{daemon},
        (
            qw(_del_file _del_input_file _del_output_file _check_system _manual_check)
        )
    );
    does_ok( $test->{daemon}, 'Siebel::Srvrmgr::Daemon::Cleanup' );
}

sub class_attributes : Tests {
    my $test    = shift;
    my @attribs = (qw(output_file input_file));
    $test->SUPER::class_attributes( \@attribs );
}

1;
