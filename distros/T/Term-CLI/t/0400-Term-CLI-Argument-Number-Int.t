#!/usr/bin/perl -T
#
# Copyright (c) 2018-2022, Steven Bakker.
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
    Term_CLI_Argument_Number_Int_test->runtests();
    exit(0);
}

package Term_CLI_Argument_Number_Int_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use Test::Exception 0.35;
use FindBin 1.50;
use Term::CLI::ReadLine;
use Term::CLI::Argument::Number::Int;
use Term::CLI::L10N;

my $ARG_NAME  = 'test_int';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;

    Term::CLI::L10N->set_language('en');

    my $arg = Term::CLI::Argument::Number::Int->new(
        name => $ARG_NAME,
    );

    isa_ok( $arg, 'Term::CLI::Argument::Number::Int',
            'Term::CLI::Argument::Number::Int->new' );

    $self->{arg} = $arg;
    return;
}

sub check_constructor: Test(1) {
    my $self = shift;

    throws_ok
        { Term::CLI::Argument::Number::Int->new() }
        qr/Missing required arguments: name/,
        'error on missing name';
    return;
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'Number::Int', "type attribute is Number::Int" );
    return;
}

sub check_validate: Test(29) {
    my $self = shift;
    my $arg = $self->{arg};

    my $test_value = '+1200';
    my $expected   = 1200;
    my $value      = $arg->validate($test_value);
    ok( defined $value, "'$test_value' validates OK" );
    is( $value, $expected, "'$test_value' => $value (equal to $expected)" );

    $test_value = '-2';
    $expected   = -2;
    $value      = $arg->validate($test_value);
    ok( defined $value, "'$test_value' validates OK" );
    is( $value, $expected, "'$test_value' => $value (equal to $expected)" );

    $test_value = '2.5';
    $value      = $arg->validate($test_value);
    ok( ! defined $value, "'$test_value' should not validate" );
    is( $arg->error, 'not a valid number',
        'error message on validate -> "not a valid number"' );

    my ($min, $max);

  # --- with min only
    $min = 1;
    $max = undef;
    $arg->min($min);
    $arg->clear_max;
    $arg->inclusive(1);

    $test_value = '4';
    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $min <= $test_value" )
    or diag("validation error: ".$arg->error);
 
    $test_value = '0';
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min <= $test_value" );
    is( $arg->error, 'too small', 'error is set correctly on too small number' );

  # --- with max only
    $min = undef;
    $max = 10;
    $arg->max($max);
    $arg->clear_min;
    $arg->inclusive(1);

    $test_value = '4';
    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $test_value <= $max" )
    or diag("validation error: ".$arg->error);
 
    $test_value = '11';
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $test_value <= $max" );
    is( $arg->error, 'too large', 'error is set correctly on too large number' );

  # --- exclusive, with min only
    $min = 1;
    $max = undef;
    $arg->min($min);
    $arg->clear_max;
    $arg->inclusive(0);

    $test_value = '4';
    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $min <= $test_value" )
    or diag("validation error: ".$arg->error);
 
    $test_value = '0';
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min <= $test_value" );
    is( $arg->error, 'too small', 'error is set correctly on too small number' );

  # --- exclusive, with max only
    $min = undef;
    $max = 10;
    $arg->max($max);
    $arg->clear_min;
    $arg->inclusive(0);

    $test_value = '4';
    $value = $arg->validate($test_value);
    ok( defined $value,
        "'$test_value' passes $test_value <= $max" )
    or diag("validation error: ".$arg->error);
 
    $test_value = '11';
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $test_value <= $max" );
    is( $arg->error, 'too large', 'error is set correctly on too large number' );

  # --- inclusive with min *and* max
    $min = -10;
    $max = 10;
    $test_value = '4';
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

    $test_value = $min-1;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min <= $test_value <= $max" );
    is( $arg->error, 'too small', 'error is set correctly on too small number' );

    $test_value = $max+1;
    $value = $arg->validate($test_value);
    ok( !defined $value,
        "'$test_value' does not pass $min <= $test_value <= $max" );
    is( $arg->error, 'too large', 'error is set correctly on too large number' );

  # --- exclusive with min *and* max
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
    return;
}

}

Main();
