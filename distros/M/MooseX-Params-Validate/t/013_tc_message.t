## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use MooseX::Params::Validate qw( validated_list );
use Moose::Util::TypeConstraints;

subtype 'SpecialInt', as 'Int',
    where { $_ == 42 },
    message {"$_[0] is not a special int!"};

sub validate {
    my ( $int1, $int2 ) = validated_list(
        \@_,
        integer => { isa => 'Int' },
        special => { isa => 'SpecialInt' },
    );

    return;
}

my $e = exception { validate( integer => 42, special => 5 ) };
like(
    $e,
    qr/5 is not a special int\!/,
    'got custom message for SpecialInt type'
);

isa_ok(
    $e,
    'MooseX::Params::Validate::Exception::ValidationFailedForTypeConstraint'
);

like(
    exception { validate( integer => 'foo', special => 42 ) },
    qr/Validation failed for 'Int'/,
    'got standard message for Int type'
);

done_testing();
