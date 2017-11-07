use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use Test::Filename 0.03;
use File::Temp;
use File::pushd qw/pushd/;

use lib 't/pir/lib';
use PCNTest;
use Path::Tiny;

use Path::Tiny::Rule;

#--------------------------------------------------------------------------#

Path::Tiny::Rule->add_helper(
    txt => sub {
        return sub { return /\.txt$/ }
    }
);
can_ok( 'Path::Tiny::Rule', 'txt' );

# check we can do this via object, too
my $rule = Path::Tiny::Rule->new;

eval {
    $rule->add_helper( txt => sub { 1 } );
};
like( $@, qr/Can't add rule 'txt'/, "exception if helper exists" );

{
    my $td = make_tree(
        qw(
          atroot
          empty/
          data/file1.txt
          )
    );

    my ( $iter, @files );
    my $rule = Path::Tiny::Rule->new->file->txt;
    @files = $rule->all( $td, { relative => 1 } );
    is( scalar @files, 1, "All: one file" ) or diag explain \@files;
    filename_is( $files[0], "data/file1.txt", "got expected file" )
}

done_testing;
# COPYRIGHT
