use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use File::pushd qw/tempd/;
use Path::Tiny;

use Test::DZil;

my $corpus = path('corpus/DZ1')->absolute;

my $wd = tempd;

my $tzil = Builder->from_config( { dist_root => "$corpus" }, );

ok( $tzil->build, "build dist with \@DAGOLDEN" );

done_testing;
# COPYRIGHT
