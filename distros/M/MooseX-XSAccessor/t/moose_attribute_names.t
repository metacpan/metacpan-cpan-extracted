use lib "t/lib";
use lib "moose/lib";
use lib "lib";

## skip Test::Tabs

use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $exception_regex = qr/You must provide a name for the attribute/;
{
    package My::Role;
    use MyMoose::Role;

    ::like( ::exception {
        has;
    }, $exception_regex, 'has; fails' );

    ::like( ::exception {
        has undef;
    }, $exception_regex, 'has undef; fails' );

    ::is( ::exception {
        has "" => (
            is => 'bare',
        );
    }, undef, 'has ""; works now' );

    ::is( ::exception {
        has 0 => (
            is => 'bare',
        );
    }, undef, 'has 0; works now' );
}

{
    package My::Class;
    use MyMoose;

    ::like( ::exception {
        has;
    }, $exception_regex, 'has; fails' );

    ::like( ::exception {
        has undef;
    }, $exception_regex, 'has undef; fails' );

    ::is( ::exception {
        has "" => (
            is => 'bare',
        );
    }, undef, 'has ""; works now' );

    ::is( ::exception {
        has 0 => (
            is => 'bare',
        );
    }, undef, 'has 0; works now' );
}

done_testing;
