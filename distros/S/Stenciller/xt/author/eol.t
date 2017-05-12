use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Stenciller.pm',
    'lib/Stenciller/Plugin/ToHtmlPreBlock.pm',
    'lib/Stenciller/Plugin/ToUnparsedText.pm',
    'lib/Stenciller/Stencil.pm',
    'lib/Stenciller/Transformer.pm',
    'lib/Stenciller/Utils.pm',
    'lib/Types/Stenciller.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-structure.t',
    't/02-unparsed_text.t',
    't/03-unparsed_text_filtered.t',
    't/04-htmlpre.t',
    't/05-htmlpre_filtered.t',
    't/06-unparsed-text-as-html-pod.t',
    't/07-htmlpre-also-as-html.t',
    't/corpus/test-1.stencil',
    't/corpus/test-2.stencil',
    't/corpus/test-3.stencil',
    't/corpus/test-4.stencil',
    't/corpus/test-5.stencil',
    't/corpus/test-6.stencil',
    't/corpus/test-7.stencil'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
