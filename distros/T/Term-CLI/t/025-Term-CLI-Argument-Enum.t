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
    Term_CLI_Argument_Enum_test->SKIP_CLASS(
        ($::ENV{SKIP_ARGUMENT})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Argument_Enum_test->runtests();
}

package Term_CLI_Argument_Enum_test {

use parent qw( Test::Class );

use Test::More;
use Test::Exception;
use FindBin;
use Term::CLI::Argument::Enum;

my $ARG_NAME= 'test_enum';
my @ENUM_VALUES = qw( one two three );

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;
    my $arg = Term::CLI::Argument::Enum->new(
        name => $ARG_NAME,
        value_list => [@ENUM_VALUES]
    );

    isa_ok( $arg, 'Term::CLI::Argument::Enum', 'Term::CLI::Argument::Enum->new' );
    $self->{arg} = $arg;
}

sub check_constructor: Test(1) {
    my $self = shift;

    throws_ok
        { Term::CLI::Argument::Enum->new( name => $ARG_NAME) }
        qr/Missing required arguments: value_list/,
        'error on missing value_list';
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'Enum', "type attribute is Enum" );
}

sub check_complete: Test(3) {
    my $self = shift;
    my $arg = $self->{arg};

    my @expected = sort @ENUM_VALUES;
    is_deeply( [$arg->complete('')], \@expected,
        "complete returns (@ENUM_VALUES) for ''");

    @expected = sort qw( two three );
    is_deeply( [$arg->complete('t')], \@expected,
        "complete returns (@expected) for 't'");

    @expected = ();
    is_deeply( [$arg->complete('X')], \@expected,
        "complete returns (@expected) for 'X'");
}

sub check_validate: Test(10) {
    my $self = shift;
    my $arg = $self->{arg};

    ok( !$arg->validate(undef), "'undef' does not validate");

    is ( $arg->error, 'value cannot be empty',
        "error on 'undef' value is set correctly" );

    $arg->set_error('SOMETHING');

    ok( !$arg->validate(''), "'' does not validate");
    is ( $arg->error, 'value cannot be empty',
        "error on '' value is set correctly" );

    $arg->set_error('SOMETHING');

    ok( !$arg->validate('thing'), "'thing' does not validate");
    is ( $arg->error, 'not a valid value',
        "error on '' value is set correctly" );

    ok( !$arg->validate('t'), "'t' is ambiguous");
    like ( $arg->error, qr/^ambiguous value \(matches: .*\)$/,
        "error on ambiguous value is set correctly" );

    $arg->set_error('SOMETHING');

    my $test_value = $ENUM_VALUES[1];
    ok( $arg->validate($test_value), "'$test_value' validates");

    is ( $arg->error, '',
        "error is cleared on successful validation" );
}

}

Main();
