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
    Term_CLI_Argument_String_test->SKIP_CLASS(
        ($::ENV{SKIP_ARGUMENT})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Argument_String_test->runtests();
}

package Term_CLI_Argument_String_test {

use parent qw( Test::Class );

use Test::More;
use Test::Exception;
use FindBin;
use Term::CLI::Argument::String;

my $ARG_NAME= 'test_enum';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;
    my $arg = Term::CLI::Argument::String->new(
        name => $ARG_NAME,
    );

    isa_ok( $arg, 'Term::CLI::Argument::String',
            'Term::CLI::Argument::String->new' );
    $self->{arg} = $arg;
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'String', "type attribute is String" );
}

sub check_complete: Test(1) {
    my $self = shift;
    my $arg = $self->{arg};

    my @expected = ();
    is_deeply( [$arg->complete('')], \@expected,
        "complete returns (@expected) for ''");
}

sub check_validate: Test(6) {
    my $self = shift;
    my $arg = $self->{arg};

    ok( !defined $arg->validate(undef), "'undef' does not validate");
    is ( $arg->error, 'value must be defined',
        "error on 'undef' value is set correctly" );

    $arg->set_error('SOMETHING');

    my $test_value = '';
    ok( defined $arg->validate($test_value), "'$test_value' validates")
        or diag("error is: ", $arg->error);
    is ( $arg->error, '',
        "error is cleared on successful validation" );

    $arg->set_error('SOMETHING');

    $test_value = 'a string';
    ok( defined $arg->validate($test_value), "'$test_value' validates");
    is ( $arg->error, '',
        "error is cleared on successful validation" );
}

}

Main();
