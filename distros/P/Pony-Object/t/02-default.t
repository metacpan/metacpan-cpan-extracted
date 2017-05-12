#!/usr/bin/env perl

use lib './lib';
use lib './t';

use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 4;

use Pony::Object;
use Pony::Object::Throwable;

BEGIN {
  $Pony::Object::DEFAULT->{''}->{withExceptions} = 1;
  $Pony::Object::DEFAULT->{''}->{baseClass} = [qw/Default::Base/];
  $Pony::Object::DEFAULT->{'Default::NoBase'}->{baseClass} = [];
}

use Default::RequiredException;
use Default::NoBase::Class;

  # change default 'withException' param
  my $a = new Default::RequiredException;
  ok($a->do() eq 'done', q/$Pony::Object::DEFAULT->{''}->{withExceptions} = 1/);
  
  # default base classes
  ok($a->sum(0..4) == 10, q/$Pony::Object::DEFAULT->{''}->{baseClass}/);
  
  my $b = new Default::NoBase::Class;
  
  ok($a->isa('Default::Base') && !$b->isa('Default::Base'), 'Set default params for namespace');
  ok($b->try_do == 12, 'Exception still turns on');
  
  #=========
  #   END
  #=========
  
  diag( "Testing \$Pony::Object::DEFAULT for Pony::Object $Pony::Object::VERSION" );