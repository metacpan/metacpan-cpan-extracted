#!/usr/bin/perl -T
#
# Copyright (C) 2018, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use strict;
use Modern::Perl;

sub Main {
    Term_CLI_Argument_Number_Float_test->SKIP_CLASS(
        ($::ENV{SKIP_ARGUMENT})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Argument_Number_Float_test->runtests();
}

package Term_CLI_Argument_Number_Float_test {

use parent qw( Test::Class );

use Test::More;
use Test::Exception;
use FindBin;
use Term::CLI::ReadLine;
use Term::CLI::Argument::Number::Float;
use Term::CLI::L10N;

my $ARG_NAME  = 'test_float';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;

    Term::CLI::L10N->set_language('en');

    my $arg = Term::CLI::Argument::Number::Float->new(
        name => $ARG_NAME,
    );

    isa_ok( $arg, 'Term::CLI::Argument::Number::Float',
            'Term::CLI::Argument::Number::Float->new' );

    $self->{arg} = $arg;
}

sub check_constructor: Test(1) {
    my $self = shift;

    throws_ok
        { Term::CLI::Argument::Number::Float->new() }
        qr/Missing required arguments: name/,
        'error on missing name';
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'Number::Float', "type attribute is Number::Float" );
}

sub check_validate: Test(17) {
    my $self = shift;
    my $arg = $self->{arg};

    my $test_value = '1.2e3';
    my $expected   = 1200;
    my $value      = $arg->validate($test_value);
    ok( defined $value, "'$test_value' validates OK" );
    is( $value, $expected, "'$test_value' => $value (equal to $expected)" );

    $test_value = '1.23e-4';
    $expected   = 1.23e-4;
    $value      = $arg->validate($test_value);
    ok( defined $value, "'$test_value' validates OK" );
    is( $value, $expected, "'$test_value' => $value (equal to $expected)" );

    $test_value = '0.Ol2';
    $value      = $arg->validate($test_value);
    ok( ! defined $value, "'$test_value' should not validate" );
    is( $arg->error, 'not a valid number',
        'error message on validate -> "not a valid number"' );

    my $min = 9;
    my $max = 11;
    $test_value = sprintf("%0.2f", ($max + $min) / 2);
    $arg->min($min);
    $arg->max($max);
    $arg->inclusive(1);

    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $min <= $test_value <= $max" )
    or diag("validation error: ".$arg->error);

    $test_value = $min;
    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $min <= $test_value <= $max" )
    or diag("validation error: ".$arg->error);

    $test_value = $max;
    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $min <= $test_value <= $max" )
    or diag("validation error: ".$arg->error);

    $arg->inclusive(0);

    $test_value = $min;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min < $test_value < $max" );
    is( $arg->error, 'too small', 'error is set correctly on too small number' );

    $test_value = $max;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min < $test_value < $max" );
    is( $arg->error, 'too large', 'error is set correctly on too large number' );

    $arg->inclusive(1);

    $test_value = $min-0.1;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min <= $test_value <= $max" );
    is( $arg->error, 'too small', 'error is set correctly on too small number' );

    $test_value = $max+0.1;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min <= $test_value <= $max" );
    is( $arg->error, 'too large', 'error is set correctly on too large number' );
}

}

Main();
