#!/usr/bin/perl -T
#
# Copyright (c) 2022, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use warnings;

use Test::More;

my $TEST_NAME = 'ARGUMENT';

sub Main() {
    if ( ($::ENV{SKIP_ALL} || $::ENV{"SKIP_$TEST_NAME"}) && !$::ENV{"TEST_$TEST_NAME"} ) {
       plan skip_all => 'skipped because of environment'
    }
    Term_CLI_Argument_Enum_test->runtests();
    exit 0;
}

package Term_CLI_Argument_Enum_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use Test::Exception 0.35;
use Term::CLI::Argument::Enum;
use Term::CLI::L10N;

my $ARG_NAME    = 'test_enum';
my @ENUM_VALUES = qw( foo bar baz );

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

my $Call_count = 0;

sub get_value_list {
    $Call_count++;
    my @l = map { "$_-$Call_count" } @ENUM_VALUES;
    return \@l;
}

sub startup : Test(startup => 1) {
    my $self = shift;

    Term::CLI::L10N->set_language('en');

    my $arg = Term::CLI::Argument::Enum->new(
        name => $ARG_NAME,
        value_list => \&get_value_list,
    );

    isa_ok( $arg, 'Term::CLI::Argument::Enum', 'Term::CLI::Argument::Enum->new' );
    $self->{arg} = $arg;
    return;
}

sub check_uncached: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};

    $arg->cache_values(0);

    my $count = $Call_count = 0;

    my ($got, @expected);

    $got = $arg->values;
    $count++;
    @expected = sort map { "$_-$count" } @ENUM_VALUES;

    is_deeply( $got, \@expected,
        'cache=0; enum value list 1 is dynamic',
    );

    $got = $arg->values;
    $count++;
    @expected = sort map { "$_-$count" } @ENUM_VALUES;

    is_deeply( $got, \@expected,
        'cache=0; enum value list 2 is dynamic',
    );

    return;
}

sub check_cached: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};

    $arg->cache_values(1);

    my $count = $Call_count = 10;

    my ($got, @expected);

    $got = $arg->values;
    $count++;

    @expected = sort map { "$_-$count" } @ENUM_VALUES;

    is_deeply( $got, \@expected,
        'cache=1; enum value list 1 is correct',
    );

    $got = $arg->values;
    is_deeply( $got, \@expected,
        'cache=1; enum value list 2 is unchanged',
    );

    return;
}

}

Main();
