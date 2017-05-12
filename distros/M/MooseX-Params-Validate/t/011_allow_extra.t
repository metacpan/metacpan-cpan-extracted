## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use MooseX::Params::Validate qw( validated_hash );

sub foo {
    my %params = validated_hash(
        \@_,
        x => { isa => 'Int' },
        y => { isa => 'Int' },
    );
    \%params;
}

sub bar {
    my %params = validated_hash(
        \@_,
        x                              => { isa => 'Int' },
        y                              => { isa => 'Int' },
        MX_PARAMS_VALIDATE_ALLOW_EXTRA => 1,
    );
    \%params;
}

is_deeply(
    bar( x => 42, y => 1 ),
    { x => 42, y => 1 },
    'bar returns expected values with no extra params'
);

is_deeply(
    bar( x => 42, y => 1, z => 'whatever' ),
    { x => 42, y => 1, z => 'whatever' },
    'bar returns expected values with extra params'
);

like(
    exception { foo( x => 42, y => 1, z => 'whatever' ) },
    qr/The following parameter .+ listed in the validation options: z/,
    'foo rejects extra params'
);

done_testing();
