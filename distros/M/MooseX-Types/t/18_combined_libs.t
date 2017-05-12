use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::Fatal;
use lib 't/lib';

BEGIN { use_ok 'Combined', qw/Foo2Alias MTFNPY NonEmptyStr/ }

# test that a type from TestLibrary was exported
ok Foo2Alias;

# test that a type from TestLibrary2 was exported
ok MTFNPY;

is NonEmptyStr->name, 'TestLibrary2::NonEmptyStr',
    'precedence for conflicting types is correct';

like exception { Combined->import('NonExistentType') },
qr/\Qmain asked for a type (NonExistentType) which is not found in any of the type libraries (TestLibrary TestLibrary2) combined by Combined/,
'asking for a non-existent type from a combined type library gives a useful error';

{
    package BadCombined;

    use base 'MooseX::Types::Combine';

    ::like ::exception { __PACKAGE__->provide_types_from('Empty') },
    qr/Cannot use Empty in a combined type library, it does not provide any types/,
    'cannot combine types from a package which is not a type library';

    ::like ::exception { __PACKAGE__->provide_types_from('DoesNotExist') },
    qr/Can't locate DoesNotExist\.pm/,
    'cannot combine types from a package which does not exist';
}

is exception { 'Combined'->import(':all') }, undef, ':all syntax works';

done_testing();
