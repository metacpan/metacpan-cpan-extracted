
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
    'lib/Dist/Zilla/Plugin/Test/Pod/Coverage/More.pm',
    'lib/Pod/Coverage/More.pm',
    'lib/Pod/Coverage/More/Analyzer.pm',
    'lib/Pod/Coverage/More/Analyzer/Perl5_36.pm',
    'lib/Pod/Coverage/More/Analyzer/Perl5_38.pm',
    'lib/Pod/Coverage/More/Analyzer/Perl5_44.pm',
    'lib/Pod/Coverage/More/Blurb.pm',
    'lib/Pod/Coverage/More/Declared.pm',
    'lib/Pod/Coverage/More/Declared/ClassTiny.pm',
    'lib/Pod/Coverage/More/Declared/FunctionParameters.pm',
    'lib/Pod/Coverage/More/Declared/Kavorka.pm',
    'lib/Pod/Coverage/More/Declared/MOP.pm',
    'lib/Pod/Coverage/More/Declared/ObjectPad.pm',
    'lib/Pod/Coverage/More/Declared/TypeParams.pm',
    'lib/Pod/Coverage/More/Documentation.pm',
    'lib/Pod/Coverage/More/Generator.pm',
    'lib/Pod/Coverage/More/Types.pm',
    'lib/Pod/Weaver/Section/Blurbs.pm',
    'lib/Test/Pod/Coverage/More.pm',
    't/00-compile.t',
    't/Dist-Zilla-Plugin-Test-Pod-Coverage-More.t',
    't/Pod-Coverage-More-Analyzer.t',
    't/Pod-Coverage-More-Blurb.t',
    't/Pod-Coverage-More-Declared.t',
    't/Pod-Coverage-More-Documentation.t',
    't/Pod-Coverage-More-Generator.t',
    't/Pod-Coverage-More-Types.t',
    't/Pod-Coverage-More.t',
    't/Pod-Weaver-Section-Blurbs.t',
    't/Test-Pod-Coverage-More.t',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage-more.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-synopsis.t',
    't/author-test-version.t',
    't/elsewhere/CommentedParent.pm',
    't/lib/Analyzed.pm',
    't/lib/Ancestor.pm',
    't/lib/Big.pm',
    't/lib/Blurbed.pm',
    't/lib/BlurbedChild.pm',
    't/lib/CommentedChild.pm',
    't/lib/CoreClass.pm',
    't/lib/Declared/WithFP.pm',
    't/lib/Declared/WithKavorka.pm',
    't/lib/Declared/WithMS.pm',
    't/lib/Declared/WithMoo.pm',
    't/lib/Declared/WithMoose.pm',
    't/lib/Declared/WithMouse.pm',
    't/lib/Declared/WithPad.pm',
    't/lib/Declared/WithTiny.pm',
    't/lib/Declared/WithTypeParams.pm',
    't/lib/Descendant.pm',
    't/lib/Documented.pm',
    't/lib/FullyDocumented.pm',
    't/lib/Guarded.pm',
    't/lib/Installed.pm',
    't/lib/Installer.pm',
    't/lib/Mistyped.pm',
    't/lib/Quux.pm',
    't/lib/Ret.pm',
    't/lib/Signed.pm',
    't/lib/Signed538.pm',
    't/lib/Trusted.pm',
    't/lib/Unfolded.pm',
    't/lib/Xenu.pm',
    't/pod.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-unused-vars.t',
    't/script/scripted'
);

notabs_ok($_) foreach @files;
done_testing;
