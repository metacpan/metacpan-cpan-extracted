
use strict;
use warnings;

use Test::More;
use Path::Tiny;

my $tmpdir;
BEGIN { $tmpdir = Path::Tiny->tempdir; $ENV{HOME} = "$tmpdir"; }

use Test::File::ShareDir -share => { -dist => { 'Path-IsDev-HeuristicSet-FromConfig' => 'share' } };

use Path::IsDev::HeuristicSet::FromConfig;
use Path::IsDev::Object;

use FindBin;

my $object = Path::IsDev::Object->new( set => 'FromConfig' );
ok( ref $object, 'IsDev started with FromConfig Set' );
my $result = $object->_matches("$FindBin::Bin/..");
ok( ref $result,     'Got result for matching $PROJECTROOT' );
ok( $result->result, 'result is true' );
is( ref $result->reasons, 'ARRAY', 'reasons is ARRAY ref' );

done_testing;
