#!/usr/bin/env perl

# [[[ HEADER ]]]
use strict;
use warnings;
our $VERSION = 0.005_000;

# [[[ INCLUDES ]]]
use Test::More tests => 12;
use Test::Exception;

# [[[ OPERATIONS ]]]

BEGIN {
    if ( $ENV{PERL_VERBOSE} ) {
        Test::More::diag("[[[ Beginning Dependency Tests ]]]");
    }
}

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
    lives_and( sub { use_ok('Test::CPAN::Changes'); }, q{use_ok('Test::CPAN::Changes') lives} );
}
lives_and( sub { require_ok('Test::CPAN::Changes'); }, q{require_ok('Test::CPAN::Changes') lives} );

BEGIN {
    lives_and( sub { use_ok('Test::Exception'); }, q{use_ok('Test::Exception') lives} );
}
lives_and( sub { require_ok('Test::Exception'); }, q{require_ok('Test::Exception') lives} );

BEGIN {
    lives_and( sub { use_ok('PadWalker'); }, q{use_ok('PadWalker') lives} );
}
lives_and( sub { require_ok('PadWalker'); }, q{require_ok('PadWalker') lives} );

done_testing();
