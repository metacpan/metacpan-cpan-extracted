#!/usr/bin/env perl

use lib './lib';
use lib './t';

use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 16;

use Pony::Object ':exceptions';
use Pony::Object::Throwable;
use Throw::ThisIsMyException;

  #================
  #   Exceptions
  #================
  
  # Error test
  try {
    throw Pony::Object::Throwable("Bad wolf");
    ok(0, "Life after death.");
  }
  catch {
    ok(1, "Try/Catch test");
  }
  finally {
    ok(1, "Finally test");
  };
  
  try {
    # do nothing
    1 if 1+1 == 2;
  }
  catch {
    ok(0, "Bad catch");
  }
  finally {
    ok(1, "More finally");
  };
  
  try {
    throw Pony::Object::Throwable("Bad wolf");
  }
  catch {
    ok(1, "Catch without finally");
  };
  
  try {
    if (1 == 1) {
      throw Pony::Object::Throwable('Bad wolf');
    }
  }
  catch {
    if ($_[0]->isa('Pony::Object::Throwable')) {
      ok(1, "Catch only one type of exceptions.");
    }
    else {
      die $_[0];
    }
  };
  
  # FixMe: returns from try/catch must returns.
  sub retInCatch
    {
      try {
        throw Pony::Object::Throwable('Throw in function.');
      }
      catch {
        return 1;
      }
      
      return 0;
    }
  
  #ok(retInCatch(), "Test return from catch");
  
  # Catch is optional
  eval { try { die 1; }; };
  ok (!$@, "Catch is optional 1");
  
  eval { my $a = try { die 1; }; };
  ok (!$@, "Catch is optional 2");
  
  eval { my @a = try { die 1; }; };
  ok (!$@, "Catch is optional 3");
  
  # ret from try if wantarray == undef|other
  my $a = try {
    return 1;
  };
  
  ok($a == 1, "return from try to scalar");
  
  $a = try {
    die;
  } catch {
    return 2;
  };
  
  ok($a == 2, "return from catch to scalar");
  
  $a = try {
    die;
  } catch {
    2;
  };
  
  ok($a == 2, "return from catch to scalar without return command");
  
  $a = try {
    die;
  } catch {
    return 2;
  } finally {
    return 3;
  };
  
  ok($a == 3, "return from finally to scalar");
  
  # the same for array
  my @a = try {
    return 1;
  };
  
  ok($a[0] == 1, "return from try to array");
  
  @a = try {
    die;
  } catch {
    return 1, 2;
  };
  
  ok($a[1] == 2, "return from catch to array");
  
  @a = try {
    die;
  } catch {
    return 1, 2;
  } finally {
    return 1, 2, 3;
  };
  
  ok($a[2] == 3, "return from finally to array");
  
  try {
    throw Throw::ThisIsMyException("test");
  } catch {
    if ($_[0]->isa('Throw::ThisIsMyException')) {
      ok("one" eq $_[0]->get_one, "custom exception");
    }
  };

  
  diag( "Testing exceptions for Pony::Object $Pony::Object::VERSION" );