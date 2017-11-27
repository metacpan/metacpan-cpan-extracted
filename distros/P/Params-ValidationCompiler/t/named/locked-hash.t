use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;
use Test2::Require::Module 'Hash::Util';

use Hash::Util qw( lock_hash );
use Params::ValidationCompiler qw( validation_for );
use Specio::Library::Builtins;

{
    my %spec = (
        foo => 1,
        bar => {
            type     => t('Int'),
            optional => 1,
        },
    );
    lock_hash(%spec);

    my $sub = validation_for( params => \%spec );

    my %params1 = ( foo => 42 );
    lock_hash(%params1);

    is(
        dies { $sub->(%params1) },
        undef,
        'lives when given foo param but no bar'
    );

    my %params2 = ( foo => 42, bar => 42 );
    lock_hash(%params2);

    is(
        dies { $sub->(%params2) },
        undef,
        'lives when given foo and bar params'
    );
}

{
    my %spec = (
        foo => 1,
        bar => {
            optional => 1,
        },
    );
    lock_hash(%spec);

    is(
        dies { validation_for( params => \%spec ) },
        undef,
        'can pass locked hashref as spec to validation_for'
    );
}

{
    my %spec = (
        foo => {},
        bar => {
            optional => 1,
        },
    );
    lock_hash(%spec);

    is(
        dies { validation_for( params => \%spec ) },
        undef,
        'can pass locked hash as spec to validation_for'
    );
}

done_testing();
