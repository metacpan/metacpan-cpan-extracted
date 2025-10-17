# [[[ HEADER ]]]
use strict;
use warnings;
our $VERSION = 0.008_000;

# [[[ INCLUDES ]]]
use Test2::V0;
use Test2::Tools::LoadModule qw(use_ok require_ok);
use English qw( -no_match_vars );

# [[[ OPERATIONS ]]]

BEGIN {
    if ( $ENV{PERL_VERBOSE} ) {
        diag("[[[ Beginning Author Dependency Tests ]]]");
    }

    # this is an authors-only test, skip if not explicitly enabled by AUTHOR_TESTING or RELEASE_TESTING
    if (not ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING})) {
        plan skip_all => 'author test; `export AUTHOR_TESTING=1` to run';  # skip all tests if env vars are not set
    }
    else {
        plan 8;  # 4 modules * (use_ok() + require_ok())
    }
}

# AUTHOR TEST DEPENDENCIES

# DEV NOTE, CORRELATION #gt03: copy all author dependencies between 'cpanfile' & 'xt/author/00_depend.t';
# xt/author/01_changes_lint.t
BEGIN { use_ok('CPAN::Changes'); }  require_ok('CPAN::Changes');
BEGIN { use_ok('version'); }  require_ok('version');

# xt/author/02_markdown_lint.t
# DEV NOTE, CORRELATION #gt05: deps of both author & normal tests must be in 'cpanfile' in both "develop" & "test"
BEGIN { use_ok('File::Find'); }  require_ok('File::Find');
BEGIN { use_ok('IPC::Run3'); }  require_ok('IPC::Run3');

done_testing();
