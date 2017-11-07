use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use Test::Filename 0.03;
use Path::Tiny;
use File::Temp;
use File::pushd qw/pushd/;

use lib 't/pir/lib';
use PCNTest;

use Path::Tiny::Rule;

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

    $rule = Path::Tiny::Rule->new->file;

    @files = ();
    @files = $rule->all($td);
    is( scalar @files, 2, "Any file" ) or diag explain \@files;

    $rule  = Path::Tiny::Rule->new->file->size(">0k");
    @files = ();
    @files = $rule->all($td);
    filename_is( $files[0], $changes, "size > 0" ) or diag explain \@files;

}

done_testing;
# COPYRIGHT
