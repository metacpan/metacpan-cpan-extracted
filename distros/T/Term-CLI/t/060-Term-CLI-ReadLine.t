#!/usr/bin/perl -T
#
# Copyright (C) 2018, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use Modern::Perl;

sub Main() {
    Term_CLI_ReadLine_test->SKIP_CLASS(
        ($::ENV{SKIP_READLINE})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_ReadLine_test->runtests();
}

package Term_CLI_ReadLine_test {

use parent qw( Test::Class );

use Test::More;
use FindBin;
use Term::CLI::ReadLine;

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 2) {
    my $self = shift;
    my $term = Term::CLI::ReadLine->new('TEST');

    isa_ok( $term, 'Term::CLI::ReadLine', 'Term::CLI::ReadLine->new' );
    isa_ok( $term, 'Term::ReadLine', 'Term::CLI::ReadLine->new' );
    $self->{term} = $term;
}

sub check_term: Test(1) {
    my $self = shift;
    my $term = $self->{term};
    is( $term->term, $term, "term() is idempotent" );
}

sub check_size: Test(2) {
    my $self = shift;
    my $term = $self->{term};

    my $width = $term->term_width;
    my $height = $term->term_height;

    ok( $width > 0, "terminal width $width > 0");
    ok( $height > 0, "terminal height $height > 0");
}


}

Main();
