#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::MTProto::TLSchemaParser;

my $parser = Protocol::MTProto::TLSchemaParser->new;

{
   my $decls = $parser->from_string( <<'EOF' );
user id:int first_name:string last_name:string = User;

---functions---

getUser id:int = User;
EOF

   is( scalar @$decls, 2, 'Got 2 declarators from file' );

   is( $decls->[0]->kind, "constructor", 'First declarator is a constructor' );
   is( $decls->[1]->kind, "function",    'Second declarator is a function' );
}

done_testing;
