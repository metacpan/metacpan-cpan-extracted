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
use Test::More 1.001002;

our $ELT_NAME = 'test_elt';

my $TEST_NAME = 'ELEMENT';

sub Main() {
    if ( ($::ENV{SKIP_ALL} || $::ENV{"SKIP_$TEST_NAME"}) && !$::ENV{"TEST_$TEST_NAME"} ) {
       plan skip_all => 'skipped because of environment'
    }
    Term_CLI_Element_test->runtests();
    exit 0;
}

package Term_CLI_Element_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use FindBin 1.50;
use Term::CLI::Element;
use Term::CLI::ReadLine;

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 1) {
    my $self = shift;
    my $elt = Term::CLI::Element->new(name => $ELT_NAME);

    isa_ok( $elt, 'Term::CLI::Element', 'Term::CLI::Element->new' );
    $self->{arg} = $elt;
    return;
}

sub check_attributes: Test(1) {
    my $self = shift;
    my $elt = $self->{arg};
    is( $elt->name, $ELT_NAME, "name attribute is $ELT_NAME" );
    return;
}

sub check_term: Test(3) {
    my $self = shift;
    my $elt = $self->{arg};

    ok (! defined $elt->term, "term() returns undef initially");

    my $t = Term::CLI::ReadLine->new('elt_tester');
    isa_ok( $t, 'Term::CLI::ReadLine',
        'Term::CLI::ReadLine->new returns object' );
    is ($elt->term, $t, "term() returns consistently");

    #is( $t->ReadLine, 'Term::ReadLine::Gnu',
    #    'Term::CLI::ReadLine selects GNU ReadLine' );
    return;
}

sub check_error: Test(10) {
    my $self = shift;
    my $elt = $self->{arg};


    ok( ! defined $elt->set_error('ERROR'), 'set_error returns undef' );
    is( $elt->error, 'ERROR', "error is ERROR");

    ok( $elt->clear_error, "clear_error() returns success" );
    is( $elt->error, '', "clear_error() -> error is ''");

    $elt->set_error('ERROR');
    ok( ! defined $elt->set_error(''), "set_error('') returns undef" );
    is( $elt->error, '', "set_error('') -> error is ''");

    $elt->set_error('ERROR');
    ok( ! defined $elt->set_error(), 'set_error returns undef' );
    is( $elt->error, '', "set_error() -> error is ''");

    $elt->set_error('ERROR');
    ok( ! defined $elt->set_error(undef), 'set_error returns undef' );
    is( $elt->error, '', "set_error(undef) -> error is ''");
    return;
}

sub check_complete: Test(1) {
    my $self = shift;
    my $elt = $self->{arg};

    ok( ! defined $elt->complete('FOO'), 'no completions for "FOO"' );
    return;
}

}

Main();
