#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Defer;

{
   my $x = "";
   {
      defer { $x = "a" }
   }
   is($x, "a", 'defer block is invoked');

   {
      defer {
         $x = "";
         $x .= "abc";
         $x .= "123";
      }
   }
   is($x, "abc123", 'defer block can contain multiple statements');

   {
     defer {}
   }
   ok(1, 'Empty defer block parses OK');
}

{
   my $x = "";
   {
      defer { $x .= "a" }
      defer { $x .= "b" }
      defer { $x .= "c" }
   }
   is($x, "cba", 'defer blocks happen in LIFO order');
}

{
   my $x = "";

   {
      defer { $x .= "a" }
      $x .= "A";
   }

   is($x, "Aa", 'defer blocks happen after the main body');
}

{
   my $x = "";

   foreach my $i (qw( a b c )) {
      defer { $x .= $i }
   }

   is($x, "abc", 'defer block happens for every iteration of foreach');
}

{
   my $x = "";

   my $cond = 0;
   if( $cond ) {
      defer { $x .= "XXX" }
   }

   is($x, "", 'defer block does not happen inside non-taken conditional branch');
}

{
   my $x = "";

   while(1) {
      last;
      defer { $x .= "a" }
   }

   is($x, "", 'defer block does not happen if entered but unencountered');
}

{
   my $x = "";

   my $counter = 1;
   {
      defer { $x .= "A" }
      redo if $counter++ < 5;
   }

   is($x, "AAAAA", 'defer block can happen multiple times');
}

{
   my $x = "";

   {
      defer {
         $x .= "a";
         defer {
            $x .= "b";
         }
      }
   }

   is($x, "ab", 'defer block can contain another defer');
}

{
   my $x = "";
   my $value = do {
      defer { $x .= "before" }
      "value";
   };

   is($x, "before", 'defer blocks run inside do { }');
   is($value, "value", 'defer block does not disturb do { } value');
}

{
   my $x = "";
   my $sub = sub {
      defer { $x .= "a" }
   };

   $sub->();
   $sub->();
   $sub->();

   is($x, "aaa", 'defer block inside sub');
}

{
   my $x = "";
   my $sub = sub {
      return;
      defer { $x .= "a" }
   };

   $sub->();

   is($x, "", 'defer block inside sub does not happen if entered but returned early');
}

{
   my $x = "";

   sub after {
      $x .= "c";
   }

   sub before {
      $x .= "a";
      defer { $x .= "b" }
      goto \&after;
   }

   before();

   is($x, "abc", 'defer block invoked before tail-call');
}

# Sequencing with respect to variable cleanup

{
   my $var = "outer";
   my $x;
   {
      my $var = "inner";
      defer { $x = $var }
   }

   is($x, "inner", 'defer block captures live value of same-scope lexicals');
}

{
   my $var = "outer";
   my $x;
   {
      defer { $x = $var }
      my $var = "inner";
   }

   is ($x, "outer", 'defer block correctly captures outer lexical when only shadowed afterwards');
}

{
   our $var = "outer";
   {
      local $var = "inner";
      defer { $var = "finally" }
   }

   is($var, "outer", 'defer after localization still unlocalizes');
}

{
   our $var = "outer";
   {
      defer { $var = "finally" }
      local $var = "inner";
   }

   is($var, "finally", 'defer before localization overwrites');
}

{
   my $callerstr;

   sub with_caller
   {
      defer { $callerstr = join ":", (caller(0))[0,1,2], (caller(1))[0,1,2]; }
   }

   my $line = __LINE__+1;
   with_caller();
   is($callerstr, "main:$0:$line", 'caller does not see defer as __ANON__');
}

# Interactions with exceptions

{
   my $x = "";
   my $sub = sub {
      defer { $x .= "a" }
      die "Oopsie\n";
   };

   my $e = defined eval { $sub->(); 1 } ? undef : $@;

   is($x, "a", 'defer block still runs during exception unwind');
   is($e, "Oopsie\n", 'Thrown exception still occurs after defer');
}

{
   my $sub = sub {
      while(1) {
         defer { return "retval" }
         last;
      }
      return "wrong";
   };

   my $e = defined eval {
      my $ret = $sub->();
      diag("return value was $ret");
      1
   } ? undef : $@;
   like($e, qr/^Can't "return" out of a FINALLY block /,
      'Cannot return out of defer block');
}

{
   my $sub = sub {
      while(1) {
         defer { goto HERE }
      }
      HERE:
   };

   my $e = defined eval { $sub->(); 1 } ? undef : $@;
   like($e, qr/^Can't "goto" out of a FINALLY block /,
      'Cannot goto out of defer block');
}

{
   my $sub = sub {
      LOOP: while(1) {
         defer { last LOOP }
      }
   };

   my $e = defined eval { $sub->(); 1 } ? undef : $@;
   like($e, qr/^Can't "last" out of a FINALLY block /,
      'Cannot last out of defer block');
}

done_testing;
