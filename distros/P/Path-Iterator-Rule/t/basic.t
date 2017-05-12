use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use File::Temp;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;

require_ok('Path::Iterator::Rule');

#--------------------------------------------------------------------------#

{
    my $td = make_tree(
        qw(
          atroot.txt
          empty/
          data/file1.txt
          more/file2.txt
          )
    );

    my ( $iter, @files );
    my $rule = Path::Iterator::Rule->new;
    # or via object
    $rule = $rule->new->file;

    $iter = $rule->iter($td);

    @files = ();
    while ( my $f = $iter->() ) {
        push @files, $f;
    }

    is( scalar @files, 3, "Iterator files" ) or diag explain \@files;
    is( ref $files[0], '', "Iterator returns string, not object" );

    @files = ();
    @files = $rule->all($td);
    my $count = $rule->all($td);

    is( scalar @files, 3, "All files" ) or diag explain \@files;
    is( $count, 3, "All files (scalar context)" ) or diag explain \@files;

    $rule  = Path::Iterator::Rule->new->dir;
    @files = ();
    @files = map { "$_" } $rule->all($td);

    is( scalar @files, 4, "All files and dirs" ) or diag explain \@files;

    my $wd = pushd($td);

    @files = ();
    @files = map { "$_" } $rule->all();
    is( scalar @files, 4, "All files and dirs w/ cwd" ) or diag explain \@files;

    $rule->skip_dirs(qw/data/);
    @files = ();
    @files = map { "$_" } $rule->all();
    is( scalar @files, 3, "All w/ prune dir" ) or diag explain \@files;

    $rule  = Path::Iterator::Rule->new->skip_dirs(qr/./)->file;
    @files = ();
    @files = map { "$_" } $rule->all();
    is( scalar @files, 0, "All w/ prune top directory" ) or diag explain \@files;

    $rule  = Path::Iterator::Rule->new->skip_subdirs(qr/./)->file;
    @files = ();
    @files = map { "$_" } $rule->all();
    is( scalar @files, 1, "All w/ prune subdirs" ) or diag explain \@files;
}

done_testing;
#
# This file is part of Path-Iterator-Rule
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
