BEGIN {
    $ENV{PV_TEST_PERL} = 1;
}

use strict;
use warnings;

use Test::More;
use Params::Validate ();

my @types = qw(
    SCALAR
    ARRAYREF
    HASHREF
    CODEREF
    GLOB
    GLOBREF
    SCALARREF
    HANDLE
    BOOLEAN
    UNDEF
    OBJECT
);

my @subs = qw(
    validate
    validate_pos
    validation_options
    validate_with
);

is_deeply(
    [ sort @Params::Validate::EXPORT_OK ],
    [ sort @types, @subs, 'set_options' ],
    '@EXPORT_OK'
);

is_deeply(
    [ sort keys %Params::Validate::EXPORT_TAGS ],
    [qw( all types )],
    'keys %EXPORT_TAGS'
);

is_deeply(
    [ sort @{ $Params::Validate::EXPORT_TAGS{all} } ],
    [ sort @types, @subs ],
    '$EXPORT_TAGS{all}',
);

is_deeply(
    [ sort @{ $Params::Validate::EXPORT_TAGS{types} } ],
    [ sort @types ],
    '$EXPORT_TAGS{types}',
);

done_testing();

