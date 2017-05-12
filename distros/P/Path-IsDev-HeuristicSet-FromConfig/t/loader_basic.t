
use strict;
use warnings;

use Test::More;
use Path::Tiny;

my $tmpdir;
BEGIN { $tmpdir = Path::Tiny->tempdir; $ENV{HOME} = "$tmpdir"; }

use Test::File::ShareDir -share => { -dist => { 'Path-IsDev-HeuristicSet-FromConfig' => 'share' } };

use Path::IsDev::HeuristicSet::FromConfig::Loader;

is( ref Path::IsDev::HeuristicSet::FromConfig::Loader->new()->heuristics, 'ARRAY', 'loads and gives back an array ok' );

my $hash = {};
$hash->{$_} = 1 for @{ Path::IsDev::HeuristicSet::FromConfig::Loader->new()->negative_heuristics };

ok( exists $hash->{PerlINC}, 'PerlINC is in negatives' );

done_testing;
