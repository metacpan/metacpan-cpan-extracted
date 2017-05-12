use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use Test::Filename 0.03;
use Path::Tiny;
use File::Temp;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;

use Path::Iterator::Rule;

#--------------------------------------------------------------------------#

{
    my ( $rule, @files );

    my $td = make_tree(
        qw(
          data/file1.txt
          )
    );

    my $changes = path( $td, 'data', 'Changes' );

    path('Changes')->copy($changes);

    $rule = Path::Iterator::Rule->new->file;

    @files = ();
    @files = $rule->all($td);
    is( scalar @files, 2, "Any file" ) or diag explain \@files;

    $rule  = Path::Iterator::Rule->new->file->size(">0k");
    @files = ();
    @files = $rule->all($td);
    filename_is( $files[0], $changes, "size > 0" ) or diag explain \@files;

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
