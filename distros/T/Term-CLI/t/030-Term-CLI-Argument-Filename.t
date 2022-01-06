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
    Term_CLI_Argument_Filename_test->SKIP_CLASS(
        ($::ENV{SKIP_ARGUMENT})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_Argument_Filename_test->runtests();
    return;
}

package Term_CLI_Argument_Filename_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use Test::Exception 0.35;
use FindBin 1.50;
use Term::CLI::ReadLine;
use Term::CLI::Argument::Filename;
use File::Temp 0.22 qw( tempdir );

my $ARG_NAME  = 'test_filename';
my $PROG_NAME = 'test_filename';

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub startup : Test(startup => 2) {
    my $self = shift;
    my $arg = Term::CLI::Argument::Filename->new(
        name => $ARG_NAME,
    );


    isa_ok(
        Term::CLI::ReadLine->new($PROG_NAME), 
        'Term::CLI::ReadLine',
        'Term::CLI::ReadLine initialisation'
    );

    isa_ok( $arg, 'Term::CLI::Argument::Filename',
            'Term::CLI::Argument::Filename->new' );

    $self->{arg} = $arg;
    return;
}

sub check_constructor: Test(1) {
    my $self = shift;

    throws_ok
        { Term::CLI::Argument::Filename->new() }
        qr/Missing required arguments: name/,
        'error on missing name';
    return;
}

sub check_attributes: Test(2) {
    my $self = shift;
    my $arg = $self->{arg};
    is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
    is( $arg->type, 'Filename', "type attribute is Filename" );
    return;
}

sub check_complete: Test(4) {
    my $self = shift;
    my $arg = $self->{arg};

    my $dir = tempdir( CLEANUP => 1 );

    mkdir("$dir/testdir");

    is_deeply( [$arg->complete("$dir/")], ["$dir/testdir"],
        "complete returns ('$dir/testdir') for '$dir/'");

    is_deeply( [$arg->complete("$dir/testdir/")], [],
        "complete returns () for '$dir/testdir/'");

    my @fnames = qw( one two three );
    for my $f (@fnames) {
        my $path = "$dir/testdir/$f";
        open my $fh, ">", $path || fail("cannot create $path: $!");
        close $fh;
    }

    my @expected;
    
    @expected = map { "$dir/testdir/$_" } @fnames;
    is_deeply( [sort $arg->complete("$dir/testdir/")], [sort @expected],
        "complete returns (@expected) for '$dir/testdir/'");

    @expected = map { "$dir/testdir/$_" } qw( two three );
    is_deeply( [sort $arg->complete("$dir/testdir/t")], [sort @expected],
        "complete returns (@expected) for '$dir/testdir/t'");
    return;
}

}

Main();
