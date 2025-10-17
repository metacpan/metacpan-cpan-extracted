# [[[ HEADER ]]]
use strict;
use warnings;
our $VERSION = 0.011_000;

# [[[ INCLUDES ]]]
use Test2::V0;
use Test2::Tools::LoadModule qw(use_ok require_ok);
use English qw( -no_match_vars );

# [[[ OPERATIONS ]]]

BEGIN {
    if ( $ENV{PERL_VERBOSE} ) {
        diag("[[[ Beginning Dependency Tests ]]]");
    }

    plan 50;  # (24 modules * (use_ok() + require_ok())) + (2 modules * require_ok())
}

# DEV NOTE, CORRELATION #gt04: copy all build & normal & testing dependencies between 'cpanfile' & 't/00_depend.t';

# BUILD DEPENDENCIES
BEGIN { use_ok('Alien::GMP'); }  require_ok('Alien::GMP');
BEGIN { use_ok('Alien::GSL'); }  require_ok('Alien::GSL');
BEGIN { use_ok('Inline'); }  require_ok('Inline');
BEGIN { use_ok('Inline::Filters'); }  require_ok('Inline::Filters');
require_ok('Inline::C');    # don't call use_ok() directly on Inline::FOO, see Inline docs for more info
require_ok('Inline::CPP');  # don't call use_ok() directly on Inline::FOO, see Inline docs for more info

# NORMAL DEPENDENCIES
BEGIN { use_ok('Carp'); }  require_ok('Carp');
BEGIN { use_ok('Data::Dumper'); }  require_ok('Data::Dumper');
BEGIN { use_ok('English'); }  require_ok('English');
BEGIN { use_ok('Exporter'); }  require_ok('Exporter');
BEGIN { use_ok('File::Basename'); }  require_ok('File::Basename');
BEGIN { use_ok('File::Spec'); }  require_ok('File::Spec');
BEGIN { use_ok('IPC::Cmd'); }  require_ok('IPC::Cmd');
BEGIN { use_ok('IPC::Run3'); }  require_ok('IPC::Run3');
BEGIN { use_ok('Math::BigInt'); }  require_ok('Math::BigInt');
BEGIN { use_ok('Math::GSL::BLAS'); }  require_ok('Math::GSL::BLAS');
BEGIN { use_ok('Math::GSL::CBLAS'); }  require_ok('Math::GSL::CBLAS');
BEGIN { use_ok('Math::GSL::Matrix'); }  require_ok('Math::GSL::Matrix');
BEGIN { use_ok('overload'); }  require_ok('overload');
BEGIN { use_ok('PadWalker'); }  require_ok('PadWalker');
BEGIN { use_ok('parent'); }  require_ok('parent');
BEGIN { use_ok('POSIX'); }  require_ok('POSIX');
BEGIN { use_ok('Scalar::Util'); }  require_ok('Scalar::Util');
BEGIN { use_ok('Term::ReadLine'); }  require_ok('Term::ReadLine');

# TEST REQUIRES
#BEGIN { use_ok('Test2::V0'); }  require_ok('Test2::V0');                                # already loaded, don't re-test
#BEGIN { use_ok('Test2::Tools::LoadModule'); }  require_ok('Test2::Tools::LoadModule');  # already loaded, don't re-test
BEGIN { use_ok('Cwd'); }  require_ok('Cwd');
# DEV NOTE, CORRELATION #gt05: deps of both author & normal tests must be in 'cpanfile' in both "develop" & "test"
BEGIN { use_ok('File::Find'); }  require_ok('File::Find');

done_testing();
