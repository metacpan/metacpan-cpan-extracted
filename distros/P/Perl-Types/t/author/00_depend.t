# [[[ HEADER ]]]
use strict;
use warnings;
our $VERSION = 0.007_000;

# [[[ INCLUDES ]]]
use Test::More tests => 8;
use Test::Exception;

# [[[ OPERATIONS ]]]

BEGIN {
    if ( $ENV{PERL_VERBOSE} ) {
        Test::More::diag("[[[ Beginning Author Dependency Tests ]]]");
    }
}

# AUTHOR TEST DEPENDENCIES

# DEV NOTE, CORRELATION #gt03: copy all author dependencies between 'cpanfile' & 't/author/00_depend.t';
# t/author/01_changes_lint.t
BEGIN { lives_and( sub { use_ok('CPAN::Changes'); }, q{use_ok('CPAN::Changes') lives} ); }
lives_and( sub { require_ok('CPAN::Changes'); }, q{require_ok('CPAN::Changes') lives} );

BEGIN { lives_and( sub { use_ok('version'); }, q{use_ok('version') lives} ); }
lives_and( sub { require_ok('version'); }, q{require_ok('version') lives} );

# t/author/02_markdown_lint.t
BEGIN { lives_and( sub { use_ok('IPC::Run3'); }, q{use_ok('IPC::Run3') lives} ); }
lives_and( sub { require_ok('IPC::Run3'); }, q{require_ok('IPC::Run3') lives} );

# DEV NOTE, CORRELATION #gt05: deps of both author & normal tests must be in 'cpanfile' in both "develop" & "test"
BEGIN { lives_and( sub { use_ok('File::Find'); }, q{use_ok('File::Find') lives} ); }
lives_and( sub { require_ok('File::Find'); }, q{require_ok('File::Find') lives} );

done_testing();
