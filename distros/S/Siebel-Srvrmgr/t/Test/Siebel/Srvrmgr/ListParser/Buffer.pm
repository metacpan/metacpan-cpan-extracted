package Test::Siebel::Srvrmgr::ListParser::Buffer;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use parent 'Test::Siebel::Srvrmgr';

# forcing to be the first method to be tested
# this predates the usage of setup and startup, but the first is expensive and the second cannot be used due parent class
sub _constructor : Tests(1) {

    my $test = shift;

    ok(
        $test->{buffer} =
          $test->class()->new( { type => 'output', cmd_line => '' } ),
        'the constructor should succeed'
    );

}

sub class_attributes : Tests(3) {

    my $test = shift;

    has_attribute_ok( $test->{buffer}, 'type' );
    has_attribute_ok( $test->{buffer}, 'cmd_line' );
    has_attribute_ok( $test->{buffer}, 'content' );

}

sub class_methods : Tests(2) {

    my $test = shift;

    can_ok( $test->{buffer}, qw(new get_cmd_line get_content set_content) );

    ok( $test->{buffer}->set_content( $test->get_my_data()->[0] ),
        'is ok to add lines to it' );

}

1;

