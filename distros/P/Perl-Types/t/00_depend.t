# [[[ HEADER ]]]
use strict;
use warnings;
our $VERSION = 0.010_000;

# [[[ INCLUDES ]]]
use Test::More tests => 60;
use Test::Exception;

# [[[ OPERATIONS ]]]

BEGIN {
    if ( $ENV{PERL_VERBOSE} ) {
        Test::More::diag("[[[ Beginning Dependency Tests ]]]");
    }
}

# DEV NOTE, CORRELATION #gt04: copy all build & normal & testing dependencies between 'cpanfile' & 't/00_depend.t';

# BUILD DEPENDENCIES
BEGIN { lives_and( sub { use_ok('Alien::GMP'); }, q{use_ok('Alien::GMP') lives} ); }
lives_and( sub { require_ok('Alien::GMP'); }, q{require_ok('Alien::GMP') lives} );

BEGIN { lives_and( sub { use_ok('Alien::GSL'); }, q{use_ok('Alien::GSL') lives} ); }
lives_and( sub { require_ok('Alien::GSL'); }, q{require_ok('Alien::GSL') lives} );

BEGIN { lives_and( sub { use_ok('ExtUtils::MakeMaker'); }, q{use_ok('ExtUtils::MakeMaker') lives} ); }
lives_and( sub { require_ok('ExtUtils::MakeMaker'); }, q{require_ok('ExtUtils::MakeMaker') lives} );

BEGIN { lives_and( sub { use_ok('Inline'); }, q{use_ok('Inline') lives} ); }
lives_and( sub { require_ok('Inline'); }, q{require_ok('Inline') lives} );

BEGIN { lives_and( sub { use_ok('Inline::Filters'); }, q{use_ok('Inline::Filters') lives} ); }
lives_and( sub { require_ok('Inline::Filters'); }, q{require_ok('Inline::Filters') lives} );

# It is invalid to use 'Inline::C' directly. Please consult the Inline documentation for more information.
lives_and( sub { require_ok('Inline::C'); }, q{require_ok('Inline::C') lives} );

# It is invalid to use 'Inline::CPP' directly. Please consult the Inline documentation for more information.
lives_and( sub { require_ok('Inline::CPP'); }, q{require_ok('Inline::CPP') lives} );

# NORMAL DEPENDENCIES
BEGIN { lives_and( sub { use_ok('Carp'); }, q{use_ok('Carp') lives} ); }
lives_and( sub { require_ok('Carp'); }, q{require_ok('Carp') lives} );

BEGIN { lives_and( sub { use_ok('Data::Dumper'); }, q{use_ok('Data::Dumper') lives} ); }
lives_and( sub { require_ok('Data::Dumper'); }, q{require_ok('Data::Dumper') lives} );

BEGIN { lives_and( sub { use_ok('English'); }, q{use_ok('English') lives} ); }
lives_and( sub { require_ok('English'); }, q{require_ok('English') lives} );

BEGIN { lives_and( sub { use_ok('Exporter'); }, q{use_ok('Exporter') lives} ); }   
lives_and( sub { require_ok('Exporter'); }, q{require_ok('Exporter') lives} );

BEGIN { lives_and( sub { use_ok('File::Basename'); }, q{use_ok('File::Basename') lives} ); }   
lives_and( sub { require_ok('File::Basename'); }, q{require_ok('File::Basename') lives} );

BEGIN { lives_and( sub { use_ok('File::Spec'); }, q{use_ok('File::Spec') lives} ); }   
lives_and( sub { require_ok('File::Spec'); }, q{require_ok('File::Spec') lives} );

BEGIN { lives_and( sub { use_ok('IPC::Cmd'); }, q{use_ok('IPC::Cmd') lives} ); }   
lives_and( sub { require_ok('IPC::Cmd'); }, q{require_ok('IPC::Cmd') lives} );

BEGIN { lives_and( sub { use_ok('IPC::Run3'); }, q{use_ok('IPC::Run3') lives} ); }   
lives_and( sub { require_ok('IPC::Run3'); }, q{require_ok('IPC::Run3') lives} );

BEGIN { lives_and( sub { use_ok('Math::BigInt'); }, q{use_ok('Math::BigInt') lives} ); }   
lives_and( sub { require_ok('Math::BigInt'); }, q{require_ok('Math::BigIntarp') lives} );

BEGIN { lives_and( sub { use_ok('Math::GSL::BLAS'); }, q{use_ok('Math::GSL::BLAS') lives} ); }   
lives_and( sub { require_ok('Math::GSL::BLAS'); }, q{require_ok('Math::GSL::BLAS') lives} );

BEGIN { lives_and( sub { use_ok('Math::GSL::CBLAS'); }, q{use_ok('Math::GSL::CBLAS') lives} ); }   
lives_and( sub { require_ok('Math::GSL::CBLAS'); }, q{require_ok('Math::GSL::CBLAS') lives} );

BEGIN { lives_and( sub { use_ok('Math::GSL::Matrix'); }, q{use_ok('Math::GSL::Matrix') lives} ); }   
lives_and( sub { require_ok('Math::GSL::Matrix'); }, q{require_ok('Math::GSL::Matrix') lives} );

BEGIN { lives_and( sub { use_ok('overload'); }, q{use_ok('overload') lives} ); }
lives_and( sub { require_ok('overload'); }, q{require_ok('overload') lives} );

BEGIN { lives_and( sub { use_ok('PadWalker'); }, q{use_ok('PadWalker') lives} ); }
lives_and( sub { require_ok('PadWalker'); }, q{require_ok('PadWalker') lives} );

BEGIN { lives_and( sub { use_ok('parent'); }, q{use_ok('parent') lives} ); }   
lives_and( sub { require_ok('parent'); }, q{require_ok('parent') lives} );

BEGIN { lives_and( sub { use_ok('POSIX'); }, q{use_ok('POSIX') lives} ); }   
lives_and( sub { require_ok('POSIX'); }, q{require_ok('POSIX') lives} );

BEGIN { lives_and( sub { use_ok('Scalar::Util'); }, q{use_ok('Scalar::Util') lives} ); }   
lives_and( sub { require_ok('Scalar::Util'); }, q{require_ok('Scalar::Util') lives} );

BEGIN { lives_and( sub { use_ok('Term::ReadLine'); }, q{use_ok('Term::ReadLine') lives} ); }   
lives_and( sub { require_ok('Term::ReadLine'); }, q{require_ok('Term::ReadLine') lives} );

# TEST REQUIRES
BEGIN { lives_and( sub { use_ok('Test2::V0'); }, q{use_ok('Test2::V0') lives} ); }
lives_and( sub { require_ok('Test2::V0'); }, q{require_ok('Test2::V0') lives} );

BEGIN { lives_and( sub { use_ok('Test::More'); }, q{use_ok('Test::More') lives} ); }
lives_and( sub { require_ok('Test::More'); }, q{require_ok('Test::More') lives} );

BEGIN { lives_and( sub { use_ok('Test::Exception'); }, q{use_ok('Test::Exception') lives} ); }
lives_and( sub { require_ok('Test::Exception'); }, q{require_ok('Test::Exception') lives} );

BEGIN { lives_and( sub { use_ok('Test::Number::Delta'); }, q{use_ok('Test::Number::Delta') lives} ); }
lives_and( sub { require_ok('Test::Number::Delta'); }, q{require_ok('Test::Number::Delta') lives} );

BEGIN { lives_and( sub { use_ok('Cwd'); }, q{use_ok('Cwd') lives} ); }
lives_and( sub { require_ok('Cwd'); }, q{require_ok('Cwd') lives} );

# DEV NOTE, CORRELATION #gt05: deps of both author & normal tests must be in 'cpanfile' in both "develop" & "test"
BEGIN { lives_and( sub { use_ok('File::Find'); }, q{use_ok('File::Find') lives} ); }
lives_and( sub { require_ok('File::Find'); }, q{require_ok('File::Find') lives} );

done_testing();
