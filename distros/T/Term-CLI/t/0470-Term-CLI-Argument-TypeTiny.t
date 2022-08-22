#!/usr/bin/perl -T
#
# Copyright (c) 2018-2022, Steven Bakker.
# Copyright (c) 2022, Diab Jerius, Smithsonian Astrophysical Observatory.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use warnings;

use Test::More;
use Data::Dumper;

my $TEST_NAME = 'ARGUMENT';

sub Main() {
    if ( ($::ENV{SKIP_ALL} || $::ENV{"SKIP_$TEST_NAME"}) && !$::ENV{"TEST_$TEST_NAME"} ) {
       plan skip_all => 'skipped because of environment'
    }
    Term_CLI_Argument_TypeTiny_test->runtests();
    exit(0);
}

package Term_CLI_Argument_TypeTiny_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use Test::Exception 0.35;
use FindBin 1.50;
use Types::Standard qw( ArrayRef Split );
use Types::Common::String qw( NonEmptyStr );
use Term::CLI::ReadLine;
use Term::CLI::Argument::TypeTiny;
use Term::CLI::L10N;

my $ARG_NAME  = 'test_typetiny';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;

    Term::CLI::L10N->set_language('en');

    my $arg = Term::CLI::Argument::TypeTiny->new(
        name => $ARG_NAME,
        typetiny => ArrayRef->of(NonEmptyStr)->plus_coercions(Split[qr/,/]),
        coerce => 1,
    );

    isa_ok( $arg, 'Term::CLI::Argument::TypeTiny',
            'Term::CLI::Argument::TypeTiny->new' );

    $self->{arg} = $arg;
    return;
}

sub check_constructor: Test(1) {
    my $self = shift;

    throws_ok
        { Term::CLI::Argument::TypeTiny->new() }
        qr/Missing required arguments: name, typetiny/,
        'error on missing name';
    return;
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'TypeTiny', "type attribute is TypeTiny" );
    return;
}

sub check_validate: Test(4) {
    my $self = shift;
    my $arg = $self->{arg};

    my $test_value = 'a';
    my $expected   = [ 'a' ];
    my $value      = $arg->validate($test_value);
    ok( defined $value, "'$test_value' validates OK" );
    is_deeply( $value, $expected, "'$test_value' coerced OK" )
      or diag ( "got: ", Dumper( $value ) );

    $test_value = 'a,b';
    $expected   = [ 'a', 'b' ];
    $value      = $arg->validate($test_value);
    ok( defined $value, "'$test_value' validates OK" );
    is_deeply( $value, $expected, "'$test_value' coerced OK" )
      or diag ( "got: ", Dumper( $value ) );
    return;
}

}

Main();
