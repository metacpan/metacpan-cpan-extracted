#!/usr/bin/env perl

use lib './lib';
use lib './t';

use strict;
use warnings;
use feature ':5.10';

my @params;

BEGIN {
  if ($] >= 5.014) {
    @params = (tests => 2);
  }
  else {
    @params = (skip_all => 'Only in perl 5.14 and higher');
  }
}

use Test::More @params;


use Pony::Object ':exceptions';
use Pony::Object::Throwable;
use Throw::ThisIsMyException;

  
  # Throw in catch/finally
  
  my $result = try {
    try {
      die;
    } catch {
      throw Pony::Object::Throwable("This try isn't good enought");
    };
    
    return "bad";
  } catch {
    my $e = shift;
    return "good" if "This try isn't good enought" eq $e->{message};
  };
  
  ok("good" eq $result, "Throw in catch. It's nice to be good");
  
  $result = try {
    try {
      die;
    } catch {
    } finally {
      throw Pony::Object::Throwable("This try isn't good enought too");
    };
    
    return "bad";
  } catch {
    my $e = shift;
    return "good" if "This try isn't good enought too" eq $e->{message};
  };
  
  ok("good" eq $result, "Throw in finally. It's bad to be bad");
  
  
  #=========
  #   END
  #=========
  
  diag( "Testing exceptions 5.14 for Pony::Object $Pony::Object::VERSION" );