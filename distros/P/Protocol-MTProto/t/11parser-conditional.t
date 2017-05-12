#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::MTProto::TLSchemaParser;

my $parser = Protocol::MTProto::TLSchemaParser->new;

{
   my $c = $parser->from_string( "user {flags:#} id:flags.0?string first_name:flags.1?string last_name:flags.2?string = User flags;\n" )->[0];

   is( $c->ident, "user", 'user ->ident' );

   is( $c->optargs->[0]->name, "flags", 'user ->optargs[0]->name' );
   #is( $c->optargs->[0]->type->name, "#", 'user ->optargs[0]->type->name' );

   my @args = @{ $c->args };
   is( $args[0]->name, "id", 'user args[0]->name' );
   is( $args[0]->type->name, "string", 'user args[0]->type->name' );

   ok( $args[0]->conditional_on, 'user args[0] is conditional' );
   is( $args[0]->conditional_on, "flags", 'conditional on' );
   is( $args[0]->condition_mask, 0x01, 'condition mask' );

   is( $c->result_type->name, "User", 'user ->result_type->name' );
   ok( $c->result_type->is_boxed, 'user ->result_type->is_boxed' );
}

done_testing;
