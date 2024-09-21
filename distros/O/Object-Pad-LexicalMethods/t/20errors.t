#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad::LexicalMethods;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

use Object::Pad 0.814;

# test code needs to live inside an O:P class
class Tester {
   my method lexmethod { }
   method pkgmethod { }

   method run ( $code ) {
      lexmethod($self); # to capture it
      eval "sub { $code }" or die $@;
   }
}

my $tester = Tester->new;

like( dies { $tester->run( '$self->& "literal"' ) },
   qr/^Expected ->& to see a method call on RHS at /,
   'Failure from attempt to ->& on not a method' );

like( dies { $tester->run( '$self->&pkgmethod()' ) },
   qr/^Expected a lexical function call on RHS of ->& at /,
   'Failure from attempt to ->& on package method' );

like( dies { $tester->run( '$self->&lexmethod 1,2,3' ) },
   qr/^Lexical method call ->& with arguments must use parentheses at /,
   'Failure from attempt to ->& on package method' );

done_testing;
