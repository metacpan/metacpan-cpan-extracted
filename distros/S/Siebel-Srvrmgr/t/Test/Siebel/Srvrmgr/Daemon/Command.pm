package Test::Siebel::Srvrmgr::Daemon::Command;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use base 'Test::Siebel::Srvrmgr';

sub _constructor : Tests(2) {

    my $test = shift;

    ok(
        $test->{command} = Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list comps',
                action  => 'Siebel::Srvrmgr::Daemon::Action',
                params  => [ 'parameter1', 'parameter2' ]
            }
        )
    );

    isa_ok( $test->{command}, $test->class(), '... and the object it returns' );

}

sub class_methods : Test() {

    my $test = shift;

    can_ok( $test->{command}, qw(get_command get_action get_params) );

}

sub class_attributes : Tests() {

    my $test = shift;

    foreach my $attrib_name (qw(command action params)) {

        has_attribute_ok( $test->{command}, $attrib_name );

    }

}

1;
