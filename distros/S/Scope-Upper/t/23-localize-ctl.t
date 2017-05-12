#!perl -T

use strict;
use warnings;

use Test::More tests => 44 + 30;

use Scope::Upper qw<localize UP HERE>;

our ($x, $y);

{
 local $x = 1;
 {
  local $x = 2;
  localize '$y' => 1 => HERE;
  is $x, 2, 'last 0 [ok - x]';
  is $y, 1, 'last 0 [ok - y]';
  last;
  $y = 2;
 }
 is $x, 1,     'last 0 [end - x]';
 is $y, undef, 'last 0 [end - y]';
}

{
 local $x = 1;
LOOP:
 {
  local $x = 2;
  local $y = 0;
  {
   local $x = 3;
   localize '$y' => 1 => UP;
   is $x, 3, 'last 1 [ok - x]';
   is $y, 0, 'last 1 [ok - y]';
   last LOOP;
   $y = 3;
  }
  $y = 2;
 }
 is $x, 1,     'last 1 [end - x]';
 is $y, undef, 'last 1 [end - y]';
}

{
 local $x = 1;
 {
  local $x = 2;
  localize '$y' => 1 => HERE;
  is $x, 2, 'next 0 [ok - x]';
  is $y, 1, 'next 0 [ok - y]';
  next;
  $y = 2;
 }
 is $x, 1,     'next 0 [end - x]';
 is $y, undef, 'next 0 [end - y]';
}

{
 local $x = 1;
LOOP:
 {
  local $x = 2;
  local $y = 0;
  {
   local $x = 3;
   localize '$y' => 1 => UP;
   is $x, 3, 'next 1 [ok - x]';
   is $y, 0, 'next 1 [ok - y]';
   next LOOP;
   $y = 3;
  }
  $y = 2;
 }
 is $x, 1,     'next 1 [end - x]';
 is $y, undef, 'next 1 [end - y]';
}

{
 local $x = 1;
 {
  local $x = 2;
  {
   localize '$y' => 1 => UP UP;
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
    localize '$y' => 1 => UP UP UP;
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
     localize '$y' => 1 => UP UP UP UP;
     is $x, 3,     'die - localize outside eval [not yet 1 - x]';
     is $y, undef, 'die - localize outside eval [not yet 1 - y]';
    }
    is $x, 2,     'die - localize outside eval [not yet 2 - x]';
    is $y, undef, 'die - localize outside eval [not yet 2 - y]';
    die;
   }
  };
  is $x, 1,     'die - localize outside eval [not yet 3 - x]';
  is $y, undef, 'die - localize outside eval [not yet 3 - y]';
 } # should trigger here
 is $x, 1, 'die - localize outside eval [ok - x]';
 is $y, 1, 'die - localize outside eval [ok - y]';
}

$y = undef;
{
 local $x = 1;
 eval {
  local $x = 2;
  {
   {
    local $x = 3;
    localize '$y' => 1 => UP UP UP;
    is $x, 3,     'die - localize at eval [not yet 1 - x]';
    is $y, undef, 'die - localize at eval [not yet 1 - y]';
   }
   is $x, 2,     'die - localize at eval [not yet 2 - x]';
   is $y, undef, 'die - localize at eval [not yet 2 - y]';
   die;
  }
 }; # should trigger here
 is $x, 1, 'die - localize at eval [ok - x]';
 is $y, 1, 'die - localize at eval [ok - y]';
}

$y = undef;
{
 local $x = 1;
 eval {
  local $x = 2;
  {
   {
    local $x = 3;
    localize '$y' => 1 => UP UP;
    is $x, 3,     'die - localize inside eval [not yet 1 - x]';
    is $y, undef, 'die - localize inside eval [not yet 1 - y]';
   }
   is $x, 2,     'die - localize inside eval [not yet 2 - x]';
   is $y, undef, 'die - localize inside eval [not yet 2 - y]';
   die;
  } # should trigger here
 };
 is $x, 1,     'die - localize inside eval [ok - x]';
 is $y, undef, 'die - localize inside eval [ok - y]';
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
     localize '$y' => 1 => UP UP;
     is $x, 3,     'given/when - localize at given [not yet - x]';
     is $y, undef, 'given/when - localize at given [not yet - y]';
    }
    fail 'not reached';
   }
   is $x, 1, 'given/when - localize at given [ok - x]';
   is $y, 1, 'given/when - localize at given [ok - y]';
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
     localize '$y' => 1 => UP UP;
     is $x, 3,     'given/when/continue - localize at given [not yet 1 - x]';
     is $y, undef, 'given/when/continue - localize at given [not yet 1 - y]';
     continue;
    }
    is $x, 2,     'given/when/continue - localize at given [not yet 2 - x]';
    is $y, undef, 'given/when/continue - localize at given [not yet 2 - y]';
   }
   is $x, 1, 'given/when/continue - localize at given [ok - x]';
   is $y, 1, 'given/when/continue - localize at given [ok - y]';
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
     localize '$y' => 1 => UP UP;
     is $x, 3,     'given/default - localize at given [not yet - x]';
     is $y, undef, 'given/default - localize at given [not yet - y]';
    }
    fail 'not reached';
   }
   is $x, 1, 'given/default - localize at given [ok - x]';
   is $y, 1, 'given/default - localize at given [ok - y]';
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
     localize '$y' => 1 => UP UP;
     is $x, 3,     'given/default/continue - localize at given [not yet 1 - x]';
     is $y, undef, 'given/default/continue - localize at given [not yet 1 - y]';
     continue;
    }
    is $x, 2,     'given/default/continue - localize at given [not yet 2 - x]';
    is $y, undef, 'given/default/continue - localize at given [not yet 2 - y]';
   }
   is $x, 1, 'given/default/continue - localize at given [ok - x]';
   is $y, 1, 'given/default/continue - localize at given [ok - y]';
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
       localize '$y' => 1 => UP UP UP;
       is $x, 5,     'given/default/given/when - localize at default [not yet 1 - x]';
       is $y, undef, 'given/default/given/when - localize at default [not yet 1 - y]';
       continue;
      }
      is $x, 4,     'given/default/given/when - localize at default [not yet 2 - x]';
      is $y, undef, 'given/default/given/when - localize at default [not yet 2 - y]';
     }
     is $x, 3,     'given/default/given/when - localize at default [not yet 3 - x]';
     is $y, undef, 'given/default/given/when - localize at default [not yet 3 - y]';
     continue;
    }
    is $x, 2, 'given/default/given/when - localize at default [ok 1 - x]';
    is $y, 1, 'given/default/given/when - localize at default [ok 1 - y]';
   }
   is $x, 1,     'given/default/given/when - localize at default [ok 2 - x]';
   is $y, undef, 'given/default/given/when - localize at default [ok 2 - y]';
  }
 GIVEN_TEST_5
 fail $@ if $@;
}
