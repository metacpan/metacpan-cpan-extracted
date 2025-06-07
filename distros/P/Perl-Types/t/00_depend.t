#!/usr/bin/env perl

# [[[ HEADER ]]]
use strict;
use warnings;
our $VERSION = 0.006_000;

# [[[ INCLUDES ]]]
use Test::More tests => 28;
use Test::Exception;

# [[[ OPERATIONS ]]]

BEGIN {
    if ( $ENV{PERL_VERBOSE} ) {
        Test::More::diag("[[[ Beginning Dependency Tests ]]]");
    }
}

# BUILD REQUIRES

BEGIN {
    lives_and( sub { use_ok('Inline'); }, q{use_ok('Inline') lives} );
}
lives_and( sub { require_ok('Inline'); }, q{require_ok('Inline') lives} );

BEGIN {
    lives_and( sub { use_ok('Inline::Filters'); }, q{use_ok('Inline::Filters') lives} );
}
lives_and( sub { require_ok('Inline::Filters'); }, q{require_ok('Inline::Filters') lives} );

# It is invalid to use 'Inline::C' directly. Please consult the Inline documentation for more information.
lives_and( sub { require_ok('Inline::C'); }, q{require_ok('Inline::C') lives} );

# It is invalid to use 'Inline::CPP' directly. Please consult the Inline documentation for more information.
lives_and( sub { require_ok('Inline::CPP'); }, q{require_ok('Inline::CPP') lives} );

BEGIN {
    lives_and( sub { use_ok('Alien::GMP'); }, q{use_ok('Alien::GMP') lives} );
}
lives_and( sub { require_ok('Alien::GMP'); }, q{require_ok('Alien::GMP') lives} );

BEGIN {
    lives_and( sub { use_ok('Alien::GSL'); }, q{use_ok('Alien::GSL') lives} );
}
lives_and( sub { require_ok('Alien::GSL'); }, q{require_ok('Alien::GSL') lives} );

# TEST REQUIRES

BEGIN {
    lives_and( sub { use_ok('Test::More'); }, q{use_ok('Test::More') lives} );
}
lives_and( sub { require_ok('Test::More'); }, q{require_ok('Test::More') lives} );

BEGIN {
    lives_and( sub { use_ok('Test::CPAN::Changes'); }, q{use_ok('Test::CPAN::Changes') lives} );
}
lives_and( sub { require_ok('Test::CPAN::Changes'); }, q{require_ok('Test::CPAN::Changes') lives} );

BEGIN {
    lives_and( sub { use_ok('Test::Exception'); }, q{use_ok('Test::Exception') lives} );
}
lives_and( sub { require_ok('Test::Exception'); }, q{require_ok('Test::Exception') lives} );

BEGIN {
    lives_and( sub { use_ok('Test::Number::Delta'); }, q{use_ok('Test::Number::Delta') lives} );
}
lives_and( sub { require_ok('Test::Number::Delta'); }, q{require_ok('Test::Number::Delta') lives} );

BEGIN {
    lives_and( sub { use_ok('IPC::Run3'); }, q{use_ok('IPC::Run3') lives} );
}
lives_and( sub { require_ok('IPC::Run3'); }, q{require_ok('IPC::Run3') lives} );

BEGIN {
    lives_and( sub { use_ok('Cwd'); }, q{use_ok('Cwd') lives} );
}
lives_and( sub { require_ok('Cwd'); }, q{require_ok('Cwd') lives} );

BEGIN {
    lives_and( sub { use_ok('File::Spec'); }, q{use_ok('File::Spec') lives} );
}
lives_and( sub { require_ok('File::Spec'); }, q{require_ok('File::Spec') lives} );

BEGIN {
    lives_and( sub { use_ok('File::Find'); }, q{use_ok('File::Find') lives} );
}
lives_and( sub { require_ok('File::Find'); }, q{require_ok('File::Find') lives} );

# NORMAL REQUIRES

BEGIN {
    lives_and( sub { use_ok('PadWalker'); }, q{use_ok('PadWalker') lives} );
}
lives_and( sub { require_ok('PadWalker'); }, q{require_ok('PadWalker') lives} );

done_testing();
