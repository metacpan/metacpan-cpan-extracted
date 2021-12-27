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

our $ELT_NAME = 'test_elt';

sub Main() {
    Term_CLI_Element_test->SKIP_CLASS(
        ($::ENV{SKIP_ELEMENT})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Element_test->runtests();
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
}

sub check_attributes: Test(1) {
    my $self = shift;
    my $elt = $self->{arg};
    is( $elt->name, $ELT_NAME, "name attribute is $ELT_NAME" );
}

sub check_term: Test(3) {
    my $self = shift;
    my $elt = $self->{arg};

    ok (! defined $elt->term, "term() returns undef initially");

    my $t = Term::CLI::ReadLine->new('elt_tester');
    isa_ok( $t, 'Term::CLI::ReadLine',
        'M6::CLI::ReadLine->new returns object' );
    is ($elt->term, $t, "term() returns consistently");

    #is( $t->ReadLine, 'Term::ReadLine::Gnu',
    #    'M6::CLI::ReadLine selects GNU ReadLine' );
}

sub check_error: Test(8) {
    my $self = shift;
    my $elt = $self->{arg};

    ok( ! defined $elt->set_error('ERROR'), 'set_error returns undef' );
    is( $elt->error, 'ERROR', "error is ERROR");

    ok( ! defined $elt->set_error(''), "set_error('') returns undef" );
    is( $elt->error, '', "set_error('') -> error is ''");

    ok( ! defined $elt->set_error(), 'set_error returns undef' );
    is( $elt->error, '', "set_error() -> error is ''");

    ok( ! defined $elt->set_error(undef), 'set_error returns undef' );
    is( $elt->error, '', "set_error(undef) -> error is ''");
}

sub check_complete: Test(1) {
    my $self = shift;
    my $elt = $self->{arg};

    ok( ! defined $elt->complete('FOO'), 'no completions for "FOO"' );
}

}

Main();
