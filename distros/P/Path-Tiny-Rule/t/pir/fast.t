use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use File::Temp;
use Test::Deep qw/cmp_deeply/;
use File::pushd qw/pushd/;

use lib 't/pir/lib';
use PCNTest;

use Path::Tiny::Rule;

#--------------------------------------------------------------------------#

{
    my @tree = qw(
      aaaa.txt
      gggg.txt
      cccc.txt
      dddd.txt
      bbbb.txt
      eeee.txt
    );

    my $td = make_tree(@tree);

    opendir( my $dh, "$td" );
    my @expected = ( grep { $_ ne "." && $_ ne ".." } readdir $dh );
    closedir $dh;

    my ( $iter, @files );
    my $rule = Path::Tiny::Rule->new->file;

    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, [ sort @expected ], "all() gives sorted order" )
      or diag explain \@files;

    @files = map { unixify( $_, $td ) } $rule->all_fast($td);
    cmp_deeply( \@files, \@expected, "all_fast() gives disk order" )
      or diag explain \@files;

}

done_testing;
# COPYRIGHT
