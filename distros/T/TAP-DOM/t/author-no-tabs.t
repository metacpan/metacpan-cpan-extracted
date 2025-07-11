
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/TAP/DOM.pm',
    'lib/TAP/DOM/Archive.pm',
    'lib/TAP/DOM/Config.pm',
    'lib/TAP/DOM/DocumentData.pm',
    'lib/TAP/DOM/Entry.pm',
    'lib/TAP/DOM/Summary.pm',
    't/00-compile.t',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/dom2tap.t',
    't/empty_tap.tap',
    't/empty_tap_archive.tgz',
    't/expected_normalized.tap',
    't/no_tap_lines.tap',
    't/some_tap.dom',
    't/some_tap.txt',
    't/some_tap2.txt',
    't/some_tap3.txt',
    't/some_tap5_usebitsets.txt',
    't/some_tap6_autotapversion.txt',
    't/some_tap7_taplevel.txt',
    't/some_tap7_taplevel_skipall.txt',
    't/some_tap8_pragma.txt',
    't/some_tap8_sparse.txt',
    't/some_tap_document_data.tap',
    't/some_tap_doublecomments.txt',
    't/some_tap_with_key_values.tap',
    't/some_tap_with_key_values_insensitive.tap',
    't/tap-archive-2-with-empty.tgz',
    't/tap_archive.t',
    't/tap_archive_with_empty.t',
    't/tap_dom.t',
    't/tap_dom2.t',
    't/tap_dom3.t',
    't/tap_dom4.t',
    't/tap_dom5_usebitsets.t',
    't/tap_dom6_autotapversion.t',
    't/tap_dom7_taplevel.t',
    't/tap_dom8_sparse.t',
    't/tap_dom_document_data.t',
    't/tap_dom_dontignore_lines.t',
    't/tap_dom_empty.t',
    't/tap_dom_ignore_lines.t',
    't/tap_dom_ignore_unknown.t',
    't/tap_dom_key_values.t',
    't/tap_dom_key_values_case_insensitive.t',
    't/tap_dom_normalize.t',
    't/tap_dom_pragma.t',
    't/tap_dom_unicode.t',
    't/tap_dom_whitespace.t',
    't/to_be_normalized.tap'
);

notabs_ok($_) foreach @files;
done_testing;
