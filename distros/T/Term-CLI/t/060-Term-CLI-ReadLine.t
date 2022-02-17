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

my $TEST_NAME = 'READLINE';

sub Main() {
    if ( ($::ENV{SKIP_ALL} || $::ENV{"SKIP_$TEST_NAME"}) && !$::ENV{"TEST_$TEST_NAME"} ) {
       plan skip_all => 'skipped because of environment'
    }
    Term_CLI_ReadLine_test->runtests();
    exit(0);
}

package Term_CLI_ReadLine_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use FindBin 1.50;
use Term::CLI::ReadLine;

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 2) {
    my $self = shift;
    my $term = Term::CLI::ReadLine->new('TEST');

    isa_ok( $term, 'Term::CLI::ReadLine', 'Term::CLI::ReadLine->new' );
    isa_ok( $term, 'Term::ReadLine', 'Term::CLI::ReadLine->new' );
    $self->{term} = $term;
    return;
}

sub check_term: Test(1) {
    my $self = shift;
    my $term = $self->{term};
    is( $term->term, $term, "term() is idempotent" );
    return;
}

sub check_size: Test(2) {
    my $self = shift;
    my $term = $self->{term};

    my $width = $term->term_width;
    my $height = $term->term_height;

    ok( $width > 0, "terminal width $width > 0");
    ok( $height > 0, "terminal height $height > 0");
    return;
}

sub test_ignore_keyboard_signals: Test(0) {
    my $self = shift;
    my $term = $self->{term};

    $term->ignore_keyboard_signals('HUP', 'INT');
    $term->no_ignore_keyboard_signals('HUP', 'INT');
    return;
}


}

Main();
