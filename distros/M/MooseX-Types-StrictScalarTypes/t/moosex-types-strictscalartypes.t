use Scalar::Type qw(bool_supported);

if(bool_supported) {
    eval q{
        package MooseX::Types::StrictScalarTypes::Test::Bool;
        use Moose;
        use MooseX::Types::StrictScalarTypes qw(StrictBool);
        has 'param' => (is => 'rw', isa => StrictBool);
    }
}

package MooseX::Types::StrictScalarTypes::Test::Int;
use Moose;
use MooseX::Types::StrictScalarTypes qw(StrictInt);
has 'param' => (is => 'rw', isa => StrictInt);

package MooseX::Types::StrictScalarTypes::Test::Number;
use Moose;
use MooseX::Types::StrictScalarTypes qw(StrictNumber);
has 'param' => (is => 'rw', isa => StrictNumber);

package main;

use Test2::V0;

subtest StrictInt => sub {
    like(
        dies { MooseX::Types::StrictScalarTypes::Test::Int->new(param => "3") },
        qr/value is not an integer/,
        "StrictInt type barfs correctly"
    );
    ok(
        lives{ MooseX::Types::StrictScalarTypes::Test::Int->new(param => 3) },
        "StrictInt type succeeds correctly"
    );
};

subtest StrictNumber => sub {
    like(
        dies { MooseX::Types::StrictScalarTypes::Test::Number->new(param => "3.0") },
        qr/value is not a number/,
        "StrictNumber type barfs correctly"
    );
    ok(
        lives{ MooseX::Types::StrictScalarTypes::Test::Number->new(param => 3.0) },
        "StrictNumber type succeeds correctly"
    );
};

if(bool_supported) {
    subtest StrictBool => sub {
        like(
            dies { MooseX::Types::StrictScalarTypes::Test::Bool->new(param => 1) },
            qr/value is not a Boolean/,
            "StrictBool type barfs correctly"
        );
        ok(
            lives{ MooseX::Types::StrictScalarTypes::Test::Bool->new(param => 1 == 1) },
            "StrictBool type succeeds correctly"
        );
    };
}

done_testing;

