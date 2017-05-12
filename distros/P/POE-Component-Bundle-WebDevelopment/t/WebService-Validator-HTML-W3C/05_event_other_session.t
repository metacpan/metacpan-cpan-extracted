
use Test::More tests => 8;

SKIP: {
    unless ( -f 'network_test_enabled' ) {
        skip "validation tests", 8;
    }

use strict;
use warnings;

use POE qw(Component::WebService::Validator::HTML::W3C);

open my $net_test, '<', 'network_test_enabled'
    or die "Failed to open 'network_test_enabled' file ($!)";

my $Validator = <$net_test>;
chomp $Validator;

POE::Component::WebService::Validator::HTML::W3C->spawn( alias => 'val',  debug => 1 );

POE::Session->create(
    package_states => [
        main => [ qw( _start ) ],
    ],
);

POE::Session->create(
    inline_states => {
        _start => sub { $_[KERNEL]->alias_set('second'); },
        second_val => \&second_val,
    }
);

$poe_kernel->run;

sub _start {

    $poe_kernel->post( val => validate => {
            in      => 'http://google.ca',
            event   => 'second_val',
            session => 'second',
            _beer   => 'bar',
            options => {
                validator_uri => $Validator,
                timeout       => 10,
            }
        }
    );
}
sub second_val {
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
                . " skipping input tests for this run", 4;
        }

        like(
            $input->{is_valid},
            qr/^[01]$/,
            "{is_valid} key ",
        );

        if ( $input->{is_valid} ) {
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

            ok( 1, "dummy to match things up");
        }
        else {
            like(
                $input->{num_errors},
                qr/^ (?: [1-9] | \d{2,} )$/x,
                "{num_errors} must be a number but NOT a zero",
            );

            ok(
                exists $input->{errors},
                "{errors} key must be present",
            );

            is(
                ref $input->{errors},
                'ARRAY',
                "{errors} key must have an arrayref of errors",
            );

            my $fine = 0;
            foreach my $error ( @{ $input->{errors} } ) {
                $fine++
                    if exists $error->{line}
                        and exists $error->{col}
                        and exists $error->{msg};
            }
            my $err_num = @{ $input->{errors} };
            is(
                $fine,
                $err_num,
                "all elements of {errors} ($err_num in total) must be hashrefs"
                    . " each having qw(line col msg) keys",
            );
        }
    } # SKIP

    is(
        $input->{validator_uri},
        $Validator,
        "{validator_uri} key should contain a URI of the validator",
    );

    is(
        $input->{in},
        'http://google.ca',
        "{in} key must be intact with what we passed to it",
    );

    is(
        $input->{_beer},
        'bar',
        "user defined key ({_beer}) must be intact",
    );

    $poe_kernel->post( val => 'shutdown' );
}

} # SKIP: