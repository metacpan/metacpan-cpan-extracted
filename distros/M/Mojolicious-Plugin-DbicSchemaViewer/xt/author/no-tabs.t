use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
