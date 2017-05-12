#!perl -T

use strict;
use warnings;

use Test::More tests => 41 + 30 + 4 * 7;

use Scope::Upper qw<reap UP HERE>;

our ($x, $y);

sub check { ++$y }

{
 local $x = 1;
 {
  local $x = 2;
  {
   reap \&check => UP;
  }
  is $x, 2,     'goto 1 [not yet - x]';
  is $y, undef, 'goto 1 [not yet - y]';
  {
   local $x = 3;
   goto OVER1;
  }
 }
 $y = 0;
OVER1:
 is $x, 1, 'goto 1 [ok - x]';
 is $y, 1, 'goto 1 [ok - y]';
}

$y = undef;
{
 local $x = 1;
 {
  local $x = 2;
  {
   local $x = 3;
   {
    reap \&check => UP UP;
   }
   is $x, 3,     'goto 2 [not yet - x]';
   is $y, undef, 'goto 2 [not yet - y]';
   {
    local $x = 4;
    goto OVER2;
   }
  }
 }
 $y = 0;
OVER2:
 is $x, 1, 'goto 2 [ok - x]';
 is $y, 1, 'goto 2 [ok - y]';
}

$y = undef;
{
 local $x = 1;
 {
  eval {
   local $x = 2;
   {
    {
     local $x = 3;
     reap \&check => UP UP UP;
     is $x, 3,     'die - reap outside eval [not yet 1 - x]';
     is $y, undef, 'die - reap outside eval [not yet 1 - y]';
    }
    is $x, 2,     'die - reap outside eval [not yet 2 - x]';
    is $y, undef, 'die - reap outside eval [not yet 2 - y]';
    die;
   }
  };
  is $x, 1,     'die - reap outside eval [not yet 3 - x]';
  is $y, undef, 'die - reap outside eval [not yet 3 - y]';
 } # should trigger here
 is $x, 1, 'die - reap outside eval [ok - x]';
 is $y, 1, 'die - reap outside eval [ok - y]';
}

$y = undef;
{
 local $x = 1;
 eval {
  local $x = 2;
  {
   {
    local $x = 3;
    reap \&check => UP UP;
    is $x, 3,     'die - reap at eval [not yet 1 - x]';
    is $y, undef, 'die - reap at eval [not yet 1 - y]';
   }
   is $x, 2,     'die - reap at eval [not yet 2 - x]';
   is $y, undef, 'die - reap at eval [not yet 2 - y]';
   die;
  }
 }; # should trigger here
 is $x, 1, 'die - reap at eval [ok - x]';
 is $y, 1, 'die - reap at eval [ok - y]';
}

$y = undef;
{
 local $x = 1;
 eval {
  local $x = 2;
  {
   {
    local $x = 3;
    reap \&check => UP;
    is $x, 3,     'die - reap inside eval [not yet 1 - x]';
    is $y, undef, 'die - reap inside eval [not yet 1 - y]';
   }
   is $x, 2,     'die - reap inside eval [not yet 2 - x]';
   is $y, undef, 'die - reap inside eval [not yet 2 - y]';
   die;
  } # should trigger here
 };
 is $x, 1, 'die - reap inside eval [ok - x]';
 is $y, 1, 'die - reap inside eval [ok - y]';
}

{
 my $z      = 0;
 my $reaped = 0;
 eval {
  reap { $reaped = 1 };
  is $reaped, 0, 'died of natural death - not reaped yet';
  my $res = 1 / $z;
 };
 my $err = $@;
 is   $reaped, 1,                    'died of natural death - reaped';
 like $err,    qr/division by zero/, 'died of natural death - divided by zero';
}

SKIP:
{
 skip 'Perl 5.10 required to test given/when' => 30 if "$]" < 5.010;

 eval <<' GIVEN_TEST_1';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  local $y;
  {
   local $x = 1;
   given (1) {
    local $x = 2;
    when (1) {
     local $x = 3;
     reap \&check => UP;
     is $x, 3,     'given/when - reap at given [not yet - x]';
     is $y, undef, 'given/when - reap at given [not yet - y]';
    }
    fail 'not reached';
   }
   is $x, 1, 'given/when - reap at given [ok - x]';
   is $y, 1, 'given/when - reap at given [ok - y]';
  }
 GIVEN_TEST_1
 fail $@ if $@;

 eval <<' GIVEN_TEST_2';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  local $y;
  {
   local $x = 1;
   given (1) {
    local $x = 2;
    when (1) {
     local $x = 3;
     reap \&check => UP;
     is $x, 3,     'given/when/continue - reap at given [not yet 1 - x]';
     is $y, undef, 'given/when/continue - reap at given [not yet 1 - y]';
     continue;
    }
    is $x, 2,     'given/when/continue - reap at given [not yet 2 - x]';
    is $y, undef, 'given/when/continue - reap at given [not yet 2 - y]';
   }
   is $x, 1, 'given/when/continue - reap at given [ok - x]';
   is $y, 1, 'given/when/continue - reap at given [ok - y]';
  }
 GIVEN_TEST_2
 fail $@ if $@;

 eval <<' GIVEN_TEST_3';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  local $y;
  {
   local $x = 1;
   given (1) {
    local $x = 2;
    default {
     local $x = 3;
     reap \&check => UP;
     is $x, 3,     'given/default - reap at given [not yet - x]';
     is $y, undef, 'given/default - reap at given [not yet - y]';
    }
    fail 'not reached';
   }
   is $x, 1, 'given/default - reap at given [ok - x]';
   is $y, 1, 'given/default - reap at given [ok - y]';
  }
 GIVEN_TEST_3
 fail $@ if $@;

 eval <<' GIVEN_TEST_4';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  local $y;
  {
   local $x = 1;
   given (1) {
    local $x = 2;
    default {
     local $x = 3;
     reap \&check => UP;
     is $x, 3,     'given/default/continue - reap at given [not yet 1 - x]';
     is $y, undef, 'given/default/continue - reap at given [not yet 1 - y]';
     continue;
    }
    is $x, 2,     'given/default/continue - reap at given [not yet 2 - x]';
    is $y, undef, 'given/default/continue - reap at given [not yet 2 - y]';
   }
   is $x, 1, 'given/default/continue - reap at given [ok - x]';
   is $y, 1, 'given/default/continue - reap at given [ok - y]';
  }
 GIVEN_TEST_4
 fail $@ if $@;

 eval <<' GIVEN_TEST_5';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  local $y;
  {
   local $x = 1;
   given (1) {
    local $x = 2;
    default {
     local $x = 3;
     given (2) {
      local $x = 4;
      when (2) {
       local $x = 5;
       reap \&check => UP UP;
       is $x, 5,     'given/default/given/when - reap at default [not yet 1 - x]';
       is $y, undef, 'given/default/given/when - reap at default [not yet 1 - y]';
       continue;
      }
      is $x, 4,     'given/default/given/when - reap at default [not yet 2 - x]';
      is $y, undef, 'given/default/given/when - reap at default [not yet 2 - y]';
     }
     is $x, 3,     'given/default/given/when - reap at default [not yet 3 - x]';
     is $y, undef, 'given/default/given/when - reap at default [not yet 3 - y]';
     continue;
    }
    is $x, 2, 'given/default/given/when - reap at default [ok 1 - x]';
    is $y, 1, 'given/default/given/when - reap at default [ok 1 - y]';
   }
   is $x, 1, 'given/default/given/when - reap at default [ok 2 - x]';
   is $y, 1, 'given/default/given/when - reap at default [ok 2 - y]';
  }
 GIVEN_TEST_5
 fail $@ if $@;
}

$y = undef;
{
 local $x = 1;
 eval {
  local $x = 2;
  eval {
   local $x = 3;
   reap { ++$y; die "reaped\n" } => HERE;
   is $x, 3,     'die in reap at eval [not yet - x]';
   is $y, undef, 'die in reap at eval [not yet - y]';
  }; # should trigger here, but the die isn't catched by this eval in
     # ealier perls
  die "inner\n";
 };
 is $@, ($] >= 5.023008 ? "inner\n" : "reaped\n"),
        'die in reap at eval [ok - $@]';
 is $x, 1, 'die in reap at eval [ok - x]';
 is $y, 1, 'die in reap at eval [ok - y]';
}

$y = undef;
{
 local $x = 1;
 eval {
  local $x = 2;
  {
   local $x = 3;
   reap { ++$y; die "reaped\n" } => HERE;
   is $x, 3,     'die in reap inside eval [not yet - x]';
   is $y, undef, 'die in reap inside eval [not yet - y]';
  } # should trigger here
  die "failed\n";
 };
 is $@, "reaped\n", 'die in reap inside eval [ok - $@]';
 is $x, 1, 'die in reap inside eval [ok - x]';
 is $y, 1, 'die in reap inside eval [ok - y]';
}

sub hijacked {
 my ($cb, $desc) = @_;
 local $x = 2;
 sub {
  local $x = 3;
  &reap($cb => UP);
  is $x, 3,     "$desc [not yet 1 - x]";
  is $y, undef, "$desc [not yet 1 - y]";
 }->();
 is $x, 2,     "$desc [not yet 2 - x]";
 is $y, undef, "$desc [not yet 2 - y]";
 11, 12;
}

for ([ sub { ++$y; 15, 16, 17, 18 },        'implicit ' ],
     [ sub { ++$y; return 15, 16, 17, 18 }, ''          ]) {
 my ($cb, $imp) = @$_;
 $imp = "RT #44204 - ${imp}return from reap";
 my $desc;
 $y = undef;
 {
  $desc = "$imp in list context";
  local $x = 1;
  my @l = hijacked($cb, $desc);
  is $x,         1,          "$desc [ok - x]";
  is $y,         1,          "$desc [ok - y]";
  is_deeply \@l, [ 11, 12 ], "$desc [ok - l]";
 }
 $y = undef;
 {
  $desc = "$imp in list context";
  local $x = 1;
  my $s = hijacked($cb, $desc);
  is $x, 1,  "$desc [ok - x]";
  is $y, 1,  "$desc [ok - y]";
  is $s, 12, "$desc [ok - s]";
 }
}
