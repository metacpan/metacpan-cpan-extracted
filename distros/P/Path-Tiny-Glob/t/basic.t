use strict;
use warnings;

use Test2::V0;

plan tests => 7;

use Cwd;
use Path::Tiny::Glob;

is [ pathglob( 't/corpus/foo/bar/baz/*.x' )->all ],
   [ 't/corpus/foo/bar/baz/a.x' ],
   "simple case";

is [ pathglob( './t/corpus/foo/bar/baz/*.x' )->all ],
   [ 't/corpus/foo/bar/baz/a.x' ],
   "simple case with leading ./";

my $dir = getcwd;
is [ pathglob( $dir . '/t/corpus/foo/bar/baz/*.x' )->all ],
   [ $dir . '/t/corpus/foo/bar/baz/a.x' ],
   "simple case with leading /";


is [ pathglob( 't/corpus/**/*.x' )->all ],
   [ 't/corpus/foo/bar/baz/a.x' ],
   "simple case, **";

is [ pathglob( 't/corpus/**' )->all ],
   [   't/corpus/foo/a.y',
       't/corpus/foo/bar/baz/a.x'
   ],
   "trailing ** returns files";

is [ pathglob( [ 't/corpus/**', qr/a\.([xy])$/ ] )->all ],
   [   't/corpus/foo/a.y',
       't/corpus/foo/bar/baz/a.x'
   ],
   "regex segment";

subtest "it's all Path::Tiny objects", sub {
    isa_ok $_, 'Path::Tiny' for pathglob( 't/corpus/**' )->all;
};
