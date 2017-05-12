use strict;
use warnings;

# simulate what a Test::NoWarnings invocation looks like
use Test::More tests => 1;
END { fail("this failed") }

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use ExtUtils::MakeMaker ();
use lib 'examples/lib';
use Foo;
eval { require SyntaxErr };


