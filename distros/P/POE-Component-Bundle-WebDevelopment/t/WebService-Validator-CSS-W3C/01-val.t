
use Test::More tests => 16;

use POE qw(Component::WebService::Validator::CSS::W3C);
use LWP::UserAgent;

my $poco = POE::Component::WebService::Validator::CSS::W3C->spawn(
    debug => 1,
    ua  => LWP::UserAgent->new( timeout => 10 ),
);

isa_ok( $poco, 'POE::Component::WebService::Validator::CSS::W3C' );
can_ok( $poco, qw(spawn session_id shutdown validate) );

POE::Session->create(
    package_states => [
        main => [ qw(_start validated) ],
    ],
);

$poe_kernel->run;

sub _start {
    $poco->validate( {
            event => 'validated',
            string => '#foo { color: foosandbars; }',
            _foo   => 'bar',
        }
    );
}

sub validated {
    my $in = $_[ARG0];
    ok( exists $in->{result}, '{result} must exist' );
    SKIP: {
        if ( $in->{result} ) {
            ok(
                !exists $in->{request_error},
                '{request_error} must not exist when {result} is true'
            );
            is( $in->{is_valid}, 0, "{is_valid}" );
            is( $in->{num_errors}, 1, '{num_errors}' );
            is(
                scalar @{ $in->{errors} },
                1,
                '{errors} must contain one error',
            );
            is(
                ref $in->{errors}[0],
                'HASH',
                '{errors}[0] must be a hashref'
            );
            is(
                $in->{string},
                '#foo { color: foosandbars; }',
                '{string} must contain code passed to validate()',
            );
            isa_ok( $in->{request_uri}, 'URI' );
            isa_ok( $in->{refer_to_uri}, 'URI' );
            isa_ok( $in->{http_response}, 'HTTP::Response' );
            is(
                $in->{val_uri},
                'http://jigsaw.w3.org/css-validator/validator',
                '{val_uri} must contain default validator URI',
            );
            isa_ok( $in->{som}, 'SOAP::SOM' );
            is(
                ref $in->{warnings},
                'ARRAY',
                '{warnings} must contain an arrayref',
            );
            is(
                $in->{_foo},
                'bar',
                'user defined arguments',
            );
        }
        else {
            ok( exists $in->{request_error}, '{request_error} must exist' );
            skip "Failed to access the validator: $in->{request_error}", 12;
        }
    } # SKIP

    $poco->shutdown;
}





