
use Test::More tests => 7;

SKIP: {
    unless ( -f 'network_test_enabled' ) {
        skip "validation tests", 7;
    }
use strict;
use warnings;

use POE qw(Component::WebService::Validator::HTML::W3C);


POE::Component::WebService::Validator::HTML::W3C->spawn( alias => 'val',  debug => 1 );

POE::Session->create(
    package_states => [
        main => [ qw( _start validated ) ],
    ],
);

$poe_kernel->run;

sub _start {

    $poe_kernel->post( val => validate => {
            in      => 'http://google.ca',
            event   => 'validated',
            _123   => '222',
            options => {
                http_timeout  => 2,
                validator_uri => 'http://non.existant.uri',
            }
        }
    );
}
sub validated {
    my ( $kernel, $input ) = @_[ KERNEL, ARG0 ];

    if ( $ENV{AUTOMATED_TESTING} ) {
        use Data::Dumper;

        print "Auto-smoker detected. Going to dump `\$input` just in case\n";
        print Dumper( $input );
    }

    ok(
        length $input->{validator_error},
        "Got validator error, it should be non-empty",
    );

    ok(
        !exists $input->{is_valid},
        "{is_valid} key must be missing",
    );

    ok(
        !exists $input->{num_errors},
        "{num_errors} key must be missing",
    );

    ok(
        !exists $input->{errors},
        "{errors} key must be missing",
    );

    is(
        $input->{validator_uri},
        'http://non.existant.uri',
        "{validator_uri} key should contain a URI of the validator",
    );

    is(
        $input->{in},
        'http://google.ca',
        "{in} key must be intact with what we passed to it",
    );

    is(
        $input->{_123},
        '222',
        "user defined key ({_123}) must be intact",
    );

    $poe_kernel->post( val => 'shutdown' );
}


} # SKIP: