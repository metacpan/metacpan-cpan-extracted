
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/Params.pm',
    'lib/MooseX/Params/Magic/Base.pm',
    'lib/MooseX/Params/Magic/Data.pm',
    'lib/MooseX/Params/Magic/Wizard.pm',
    'lib/MooseX/Params/Meta/Method.pm',
    'lib/MooseX/Params/Meta/Parameter.pm',
    'lib/MooseX/Params/Meta/TypeConstraint/Listable.pm',
    'lib/MooseX/Params/TypeConstraints.pm',
    'lib/MooseX/Params/Util.pm',
    't/00-compile.t',
    't/01-parse.t',
    't/02-params.t',
    't/03-lazy.t',
    't/04-named.t',
    't/05-buildargs.t',
    't/06-inheritance.t',
    't/07-procedural.t',
    't/08-synopsis.t',
    't/09-anon.t',
    't/10-returns.t',
    't/11-returns_scalar.t',
    't/12-listables.t',
    't/13-readonly.t',
    't/99-bugs.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
