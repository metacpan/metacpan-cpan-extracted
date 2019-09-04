use strict;
use warnings;

use Test::More tests => 6;

use Cwd;
use Path::Tiny::Glob;

is_deeply
    [ pathglob( 't/corpus/foo/bar/baz/*.x' )->all ],
    [ 't/corpus/foo/bar/baz/a.x' ],
    "simple case";

is_deeply
    [ pathglob( './t/corpus/foo/bar/baz/*.x' )->all ],
    [ 't/corpus/foo/bar/baz/a.x' ],
    "simple case with leading ./";

my $dir = getcwd;
is_deeply
    [ pathglob( $dir . '/t/corpus/foo/bar/baz/*.x' )->all ],
    [ $dir . '/t/corpus/foo/bar/baz/a.x' ],
    "simple case with leading /";


is_deeply
    [ pathglob( 't/corpus/**/*.x' )->all ],
    [ 't/corpus/foo/bar/baz/a.x' ],
    "simple case, **";

is_deeply
    [ pathglob( 't/corpus/**' )->all ],
    [   't/corpus/foo/a.y',
        't/corpus/foo/bar/baz/a.x'
    ],
    "trailing ** returns files";

is_deeply
    [ pathglob( [ 't/corpus/**', qr/a\.([xy])$/ ] )->all ],
    [   't/corpus/foo/a.y',
        't/corpus/foo/bar/baz/a.x'
    ],
    "regex segment";
