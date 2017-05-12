#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;

{
    package Starch::Test::Role::MethodProxy;
    use Moo;
    with 'Starch::Role::MethodProxy';
    around BUILDARGS => sub{
        my $orig = shift;
        my $class = shift;
        my $args = $class->$orig( @_ );
        return { build_args => $args };
    };
    has build_args => ( is=>'ro' );
}

{
    package Starch::Test::CallMethodProxy;
    use Moo;
    sub foo { shift; return @_ }
}

my $class = 'Starch::Test::Role::MethodProxy';
my $package = 'Starch::Test::CallMethodProxy';
my $method = 'foo';

my $complex_data_in = {
    foo => 'FOO',
    bar => [ '&proxy', $package, $method, 'BAR' ],
    ary => [
        'one',
        [ '&proxy', $package, $method, 'two' ],
        'three',
    ],
    hsh => {
        this => 'that',
        those => [ '&proxy', $package, $method, 'these' ],
    },
};

my $complex_data_out = {
    foo => 'FOO',
    bar => 'BAR',
    ary => ['one', 'two', 'three'],
    hsh => { this=>'that', those=>'these' },
};

is_deeply(
    $class->new( $complex_data_in )->build_args(),
    $complex_data_out,
    'worked',
);

done_testing;
