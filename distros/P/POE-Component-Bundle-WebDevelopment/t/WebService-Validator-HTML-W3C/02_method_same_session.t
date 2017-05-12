
use Test::More tests => 9;

use strict;
use warnings;

use POE qw(Component::WebService::Validator::HTML::W3C);


my $poco = POE::Component::WebService::Validator::HTML::W3C->spawn(
    debug => 1,
);

isa_ok( $poco, 'POE::Component::WebService::Validator::HTML::W3C' );
can_ok( $poco, qw( validate shutdown session_id ) );

POE::Session->create(
    package_states => [
        main => [ qw( _start validated ) ],
    ],
);

my $Validator;

$poe_kernel->run;

sub _start {

    SKIP: {
        if ( -f 'network_test_enabled' ) {

            open my $net_test, '<', 'network_test_enabled'
                or die "Failed to open 'network_test_enabled' file ($!)";

            $Validator = <$net_test>;
            chomp $Validator;
            $poco->validate( {
                    in => 't/test1.html',
                    event => 'validated',
                    type  => 'file',
                    _random => 'bar',
                    options => {
                        validator_uri => $Validator,
                        timeout       => 10,
                    }
                }
            );
        }
        else {
            $poco->shutdown;
            skip "validation tests", 7;
        }
    }
}

sub validated {
    my ( $kernel, $input ) = @_[ KERNEL, ARG0 ];

    if ( $ENV{AUTOMATED_TESTING} ) {
        use Data::Dumper;

        print "Auto-smoker detected. Going to dump `\$input` just in case\n";
        print Dumper( $input );
    }

    SKIP: {
        if ( $input->{validator_error} ) {
            ok(
                length $input->{validator_error},
                "Got validator error, it should be non-empty",
            );

            skip "Got validator error ($input->{validator_error})"
                . " skipping input tests for this run", 3;
        }

        is(
            $input->{is_valid},
            1,
            "{is_valid} key must be '1' since our document is valid",
        );

        is(
            $input->{num_errors},
            0,
            "{num_errors} key must be 0 since URI is valid",
        );

        ok(
            exists $input->{errors},
            "{errors} key must exists even if we are valid",
        );

        ok(
            !defined $input->{errors},
            "{errors} key must be undef since URI is valid",
        );
    } # SKIP

    is(
        $input->{validator_uri},
        $Validator,
        "{validator_uri} key should contain a URI of the validator",
    );

    is(
        $input->{in},
        't/test1.html',
        "{in} key must be intact with what we passed to it",
    );

    is(
        $input->{_random},
        'bar',
        "user defined key ({_random}) must be intact",
    );

    $poco->shutdown;
}
