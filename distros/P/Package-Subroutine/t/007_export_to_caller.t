use Test::More tests => 2;

use strict; use warnings;
use Package::Subroutine;

package Exp::From;

sub import { &import2 }

sub import2 {
  export_to_caller Package::Subroutine(2)->('_' => qw/one two/)
}

sub one { 1 }
sub two { 2 }

package Exp::To;
Exp::From->import;

package main;

is(&Exp::To::one,1);
is(&Exp::To::two,2);