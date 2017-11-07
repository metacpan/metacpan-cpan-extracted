use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use File::Temp;
use Path::Tiny;
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
      .
      aaaa.txt
      bbbb.txt
      cccc
      cccc/dddd.txt
      cccc/eeee
      cccc/eeee/ffff.txt
      gggg.txt
    );

    my @depth_post = qw(
      aaaa.txt
      bbbb.txt
      cccc/dddd.txt
      cccc/eeee/ffff.txt
      cccc/eeee
      cccc
      gggg.txt
      .
    );

    my $td = make_tree(@tree);

    my ( $iter, @files );
    my $rule = Path::Tiny::Rule->new;

    @files =
      map { path($_)->stringify } $rule->all( { depthfirst => -1, relative => 1 }, $td );
    cmp_deeply( \@files, \@depth_pre, "Depth first iteration (pre)" )
      or diag explain \@files;

    @files =
      map { path($_)->stringify } $rule->all( { depthfirst => 1, relative => 1 }, $td );
    cmp_deeply( \@files, \@depth_post, "Depth first iteration (post)" )
      or diag explain \@files;

}

done_testing;
# COPYRIGHT
