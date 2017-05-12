#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::MTProto::TLSchemaParser;

my $parser = Protocol::MTProto::TLSchemaParser->new;

{
   my $combinators = $parser->from_string( "boolFalse#bc799737 = Bool;\n" );

   is( scalar @$combinators, 1, 'Yielded exactly 1 combinator' );

   my $c = shift @$combinators;

   is( $c->ident, "boolFalse", 'boolFalse ->ident' );
   is( $c->number, 0xbc799737, 'boolFalse ->number' );

   ok( !$c->args, 'boolFalse has no ->args' );

   is( $c->result_type->name, "Bool", 'boolFalse ->result_type->name' );
   ok( $c->result_type->is_boxed, 'boolFalse ->result_type->is_boxed' );
}

{
   my $combinators = $parser->from_string( "boolTrue#997275b5 = Bool;\n" );

   is( scalar @$combinators, 1, 'Yielded exactly 1 combinator' );

   my $c = shift @$combinators;

   is( $c->ident, "boolTrue", 'boolTrue ->ident' );
   is( $c->number, 0x997275b5, 'boolTrue ->number' );

   ok( !$c->args, 'boolTrue has no ->args' );

   is( $c->result_type->name, "Bool", 'boolTrue ->result_type->name' );
   ok( $c->result_type->is_boxed, 'boolTrue ->result_type->is_boxed' );
}

{
   my $c = $parser->from_string( "vector#1cb5c415 {t:Type} # [ t ] = Vector t;\n" )->[0];

   is( $c->ident, "vector", 'vector ->ident' );

   is( $c->args->[0]->name, undef, 'vector ->args[0]->name' );
   is( $c->args->[0]->type->name, "#", 'vector ->args[0]->type->name' );

   is( $c->result_type->name, "Vector", 'vector ->result_type->name' );
   ok( $c->result_type->is_polymorphic, 'vector ->result_type->is_polymorphic' );

   is( $c->result_type->subtypes->[0]->name, "t", 'polymorphic subtype [0]' );
}

{
   my $c = $parser->from_string( "error#c4b9f9bb code:int text:string = Error;\n" )->[0];

   is( $c->ident, "error", 'error ->ident' );

   is( $c->args->[0]->name, "code", 'error ->args[0]->name' );
   is( $c->args->[0]->type->name, "int", 'error ->args[0]->type->name' );

   is( $c->result_type->name, "Error", 'error ->result_type->name' );
   ok( $c->result_type->is_boxed, 'error ->result_type->is_boxed' );
}

done_testing;
