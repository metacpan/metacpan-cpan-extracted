#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::MTProto::TLSchemaParser;

my $parser = Protocol::MTProto::TLSchemaParser->new;

{
   my $c = $parser->from_string( "group users:Vector<User> = Group;\n" )->[0];

   is( $c->ident, "group", 'group ->ident' );

   my @args = @{ $c->args };

   is( $args[0]->name, "users", 'group args[0]->name' );
   is( $args[0]->type->name, "Vector", 'group args[0]->type->name' );

   ok( $args[0]->type->is_polymorphic, 'group args[0]->type->is_polymorphic' );
   is( $args[0]->type->subtypes->[0]->name, "User", 'group args[0]->type->subtypes[0]->name' );

   is( $c->result_type->name, "Group", 'group ->result_type->name' );
   ok( $c->result_type->is_boxed, 'group ->result_type->is_boxed' );
}

done_testing;
