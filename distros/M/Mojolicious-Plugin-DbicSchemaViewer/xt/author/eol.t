use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/dbic-schema-viewer',
    'lib/Mojolicious/Plugin/DbicSchemaViewer.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-run.t',
    't/lib/TestFor/DbicVisualizer/Schema.pm',
    't/lib/TestFor/DbicVisualizer/Schema/Result/Author.pm',
    't/lib/TestFor/DbicVisualizer/Schema/Result/AuthorThing.pm',
    't/lib/TestFor/DbicVisualizer/Schema/Result/Book.pm',
    't/lib/TestFor/DbicVisualizer/Schema/Result/BookAuthor.pm',
    't/lib/TestFor/DbicVisualizer/Schema/Result/ResultSourceWithMissingRelation.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
