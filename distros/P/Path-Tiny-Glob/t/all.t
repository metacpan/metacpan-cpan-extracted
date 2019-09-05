use Test2::V0;

use Path::Tiny::Glob pathglob => { all => 1 }, 'is_globby';

is [ pathglob( 't/corpus/foo/bar/baz/*.x' ) ],
    [ 't/corpus/foo/bar/baz/a.x' ];

done_testing();
