#!/usr/bin/perl -T
#
# Copyright (C) 2018, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use warnings;

sub Main {
    Term_CLI_Argument_Bool_test->SKIP_CLASS(
        ($::ENV{SKIP_ARGUMENT})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Argument_Bool_test->runtests();
}

package Term_CLI_Argument_Bool_test {

use parent 0.228 qw( Test::Class );

use Test::More 1.001002;
use Test::Exception 0.35;
use FindBin 1.50;
use Term::CLI::Argument::Bool;
use Term::CLI::L10N;

my $ARG_NAME= 'test_bool';
my @TRUE  = qw( 1 true  on  yes ok    );
my @FALSE = qw( 0 false off no  never );

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;

    Term::CLI::L10N->set_language('en');

    my $arg = Term::CLI::Argument::Bool->new(
        name => $ARG_NAME,
        true_values => [@TRUE],
        false_values => [@FALSE],
    );

    isa_ok( $arg, 'Term::CLI::Argument::Bool', 'Term::CLI::Argument::Bool->new' );
    $self->{arg} = $arg;
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'Bool', "type attribute is Bool" );
}

sub check_complete: Test(6) {
    my $self = shift;
    my $arg = $self->{arg};

    my $partial;
    my @expected;

    $arg->ignore_case(1);

    $partial = '';
    @expected = sort (@TRUE, @FALSE);
    is_deeply( [$arg->complete($partial)], \@expected,
        "complete returns (@expected) for '$partial'");

    $partial = 'F';
    @expected = sort qw( False );
    is_deeply( [$arg->complete($partial)], \@expected,
        "complete returns (@expected) for '$partial'");

    $partial = 'O';
    @expected = sort qw( On Ok Off );
    is_deeply( [$arg->complete($partial)], \@expected,
        "complete returns (@expected) for '$partial'");

    $partial = 'X';
    @expected = ();
    is_deeply( [$arg->complete($partial)], \@expected,
        "complete returns (@expected) for '$partial'");

    $arg->ignore_case(0);

    $partial = 'F';
    @expected = sort qw( );
    is_deeply( [$arg->complete($partial)], \@expected,
        "case-sensitive complete returns (@expected) for '$partial'");

    $partial = 'o';
    @expected = sort qw( on ok off );
    is_deeply( [$arg->complete($partial)], \@expected,
        "case-sensitive complete returns (@expected) for '$partial'");
}

sub check_validate: Test(15) {
    my $self = shift;
    my $arg = $self->{arg};

    $arg->ignore_case(1);

    ok( !$arg->validate(undef), "'undef' does not validate");
    is ( $arg->error, 'value cannot be empty',
        "error on 'undef' value is set correctly" );

    $arg->set_error('SOMETHING');

    ok( !defined $arg->validate(''), "'' does not validate");
    is ( $arg->error, 'value cannot be empty',
        "error on '' value is set correctly" );

    $arg->set_error('SOMETHING');

    ok( !defined $arg->validate('O'), "'O' does not validate");
    like ( $arg->error, qr/ambiguous/,
        "error on ambiguous value is set correctly" );

    $arg->set_error('SOMETHING');

    ok( !defined $arg->validate('WHAT'), "'WHAT' does not validate");
    like ( $arg->error, qr/invalid/,
        "error on invalid value is set correctly" );

    $arg->set_error('SOMETHING');

    my $b = $arg->validate('N');
    is( $b, 0, "'N' validates as '0'");

    $arg->set_error('SOMETHING');

    my $test_value = $TRUE[1];
    ok( defined $arg->validate($test_value), "'$test_value' validates");

    is ( $arg->error, '',
        "error is cleared on successful validation" );

    $arg->ignore_case(0);

    ok( !defined $arg->validate('o'), "'o' does not validate");
    like ( $arg->error, qr/ambiguous/,
        "error on ambiguous value is set correctly" );

    ok( !defined $arg->validate('FALSE'),
        "'FALSE' does not validate in case-sensitive mode");
    like ( $arg->error, qr/invalid/,
        "error on invalid value is set correctly" );
}

}

Main();
