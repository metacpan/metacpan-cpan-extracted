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
      bbbb.txt
      cccc/dddd.txt
      cccc/eeee/ffff.txt
      gggg.txt
    );

    my @depth_pre = qw(
      aaaa.txt
      bbbb.txt
      cccc/dddd.txt
      cccc/eeee/ffff.txt
      gggg.txt
    );

    my @depth_post = qw(
      aaaa.txt
      bbbb.txt
      cccc/dddd.txt
      cccc/eeee/ffff.txt
      gggg.txt
    );

    my $td = make_tree(@tree);

    my ( $iter, @files );
    my $rule = Path::Tiny::Rule->new->file;

    @files = map { unixify( $_, $td ) } $rule->all( { depthfirst => -1 }, $td );
    cmp_deeply( \@files, \@depth_pre, "Depth first iteration (pre)" )
      or diag explain \@files;

    @files = map { unixify( $_, $td ) } $rule->all( { depthfirst => 1 }, $td );
    cmp_deeply( \@files, \@depth_post, "Depth first iteration (post)" )
      or diag explain \@files;

}

done_testing;
# COPYRIGHT
