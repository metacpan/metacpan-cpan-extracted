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
    Term_CLI_Argument_Filename_test->runtests();
    exit 0;
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

sub check_complete: Test(10) {
    my $self = shift;
    my $arg = $self->{arg};

    my $dir = tempdir( CLEANUP => 1 );

    mkdir("$dir/testdir");

    is_deeply( [$arg->complete("$dir/")], ["$dir/testdir"],
        "complete returns ('$dir/testdir') for '$dir/'");

    is_deeply( [$arg->glob_complete("$dir/")], ["$dir/testdir/", "$dir/testdir//"],
        "glob_complete returns ('$dir/testdir/', '$dir/testdir//') for '$dir/'");

    is_deeply( [$arg->complete("$dir/testdir/")], [],
        "complete returns () for '$dir/testdir/'");

    is_deeply( [$arg->glob_complete("$dir/testdir/")], [],
        "glob_complete returns () for '$dir/testdir/'");

    my @fnames = qw( one two three );
    mkdir("$dir/testdir/dir");

    for my $f (@fnames) {
        my $path = "$dir/testdir/$f";
        open my $fh, ">", $path || fail("cannot create $path: $!");
        close $fh;
    }
    chmod(0755, "$dir/testdir/one");
    symlink('./one', "$dir/testdir/link");

    my @expected;

    @expected = map { "$dir/testdir/$_" } qw( dir one two three link );
    is_deeply( [sort $arg->complete("$dir/testdir/")], [sort @expected],
        "complete returns (@expected) for '$dir/testdir/'");

    @expected = map { "$dir/testdir/$_" } qw( dir/ one* two three link@ );
    is_deeply( [sort $arg->glob_complete("$dir/testdir/")], [sort @expected],
        "glob_complete returns (@expected) for '$dir/testdir/'");

    @expected = map { "$dir/testdir/$_" } qw( two three );
    is_deeply( [sort $arg->complete("$dir/testdir/t")], [sort @expected],
        "complete returns (@expected) for '$dir/testdir/t'");
    is_deeply( [sort $arg->glob_complete("$dir/testdir/t")], [sort @expected],
        "glob_complete returns (@expected) for '$dir/testdir/t'");

    @expected = map { "$dir/testdir/$_" } qw( link );
    is_deeply( [sort $arg->complete("$dir/testdir/l")], [sort @expected],
        "complete returns (@expected) for '$dir/testdir/l'");
    is_deeply( [sort $arg->glob_complete("$dir/testdir/l")], [sort @expected],
        "glob_complete returns (@expected) for '$dir/testdir/l'");

    return;
}

}

Main();
