#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Dynamically;

subtest "package variable" => sub {
   our $pvar = "old";

   {
      dynamically $pvar = "new";
      is( $pvar, "new", 'new value within scope' );
   }
   is( $pvar, "old", 'value restored after block leave' );

   eval {
      dynamically $pvar = "before die";
      die "oops\n";
   };
   is( $pvar, "old", 'value restored after eval die' );
};

subtest "lexical variable" => sub {
   my $lvar = "old";

   {
      dynamically $lvar = "new";
      is( $lvar, "new", 'new value within scope' );
   }
   is( $lvar, "old", 'value restored after block leave' );

   eval {
      dynamically $lvar = "before die";
      die "oops\n";
   };
   is( $lvar, "old", 'value restored after eval die' );
};

subtest "lexical with target" => sub {
   my $lvar = 42;

   {
      dynamically $lvar = $lvar + 1;
      is( $lvar, 43, 'new value from BINOP within scope' );
   }
   is( $lvar, 42, 'value resored after block leave from BINOP' );

   {
      dynamically $lvar = sin($lvar);
      is( $lvar, sin(42), 'new value from UNOP within scope' );
   }
   is( $lvar, 42, 'value resored after block leave from UNOP' );
};

subtest "array element" => sub {
   my @arr = qw( a old c );

   {
      dynamically $arr[1] = "new";
      is( $arr[1], "new", 'new value within scope' );
   }
   is( $arr[1], "old", 'value restored after block leave' );
};

subtest "hash element" => sub {
   my %hash = ( key => "old" );

   # RT132545
   my $svref = \$hash{key};

   {
      dynamically $hash{key} = "new";
      is( $hash{key}, "new", 'new value within scope' );
      is( $$svref, "new", 'new value by SV ref' );
   }
   is( $hash{key}, "old", 'value restored after block leave' );
   is( $$svref, "old", 'old value by SV ref is restored' );

   {
      dynamically $hash{newkey} = "val";
      is( $hash{newkey}, "val", 'created key within scope' );
   }
   ok( !exists $hash{newkey}, 'key removed after block leave' );

   {
      dynamically $hash{key} = "new";
      delete $hash{key};
   }
   is( $hash{key}, "old", 'value recreated after block leave' );
};

my $value;
sub func :lvalue { $value }
subtest "lvalue function" => sub {

   func = "old";
   {
      dynamically func = "new";
      is( $value, "new", 'new value within scope' );
   }
   is( $value, "old", 'value restored after block leave' );
};

subtest "lvalue accessor" => sub {

   main->func = "old";
   {
      dynamically main->func = "new";
      is( $value, "new", 'new value within scope' );
   }
   is( $value, "old", 'value restored after block leave' );
};

done_testing;
