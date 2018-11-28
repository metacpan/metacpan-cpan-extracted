use strict;
use warnings;

use Test::More tests => 5;

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
    [ ], 
    "trailing ** returns a glorious nothing";
