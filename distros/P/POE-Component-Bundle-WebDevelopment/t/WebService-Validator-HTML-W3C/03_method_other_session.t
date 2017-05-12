
use Test::More tests => 8;
use lib 'lib';
SKIP: {
    unless ( -f 'network_test_enabled' ) {
        skip "validation tests", 8;
    }

use strict;
use warnings;

open my $net_test, '<', 'network_test_enabled'
    or die "Failed to open 'network_test_enabled' file ($!)";

my $Validator = <$net_test>;
chomp $Validator;

use POE qw(Component::WebService::Validator::HTML::W3C);

my $Markup = '<h1>Test</h1><nonexistant>';

my $poco = POE::Component::WebService::Validator::HTML::W3C->spawn( debug => 1);

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

    $poco->validate( {
            in      => $Markup,
            event   => 'second_val',
            type    => 'markup',
            session => 'second',
            _user   => 'foo',
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

        is(
            $input->{is_valid},
            0,
            "{is_valid} key must be '0' since we know our markup is invalid",
        );

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
    } # SKIP

    is(
        $input->{validator_uri},
        $Validator,
        "{validator_uri} key should contain a URI of the validator",
    );

    is(
        $input->{in},
        $Markup,
        "{in} key must be intact with what we passed to it",
    );

    is(
        $input->{_user},
        'foo',
        "user defined key ({_user}) must be intact",
    );

    $poco->shutdown;
}

} # SKIP: