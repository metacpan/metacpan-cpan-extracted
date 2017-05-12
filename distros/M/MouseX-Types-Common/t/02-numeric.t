#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;

{
  package FooTest;
  use Mouse;
  use MouseX::Types::Common::Numeric (
    qw(PositiveNum PositiveInt NegativeInt NegativeNum SingleDigit)
  );

  has digit => ( is => 'rw', isa => SingleDigit);
  has posnum => ( is => 'rw', isa => PositiveNum);
  has posint => ( is => 'rw', isa => PositiveInt);
  has negnum => ( is => 'rw', isa => NegativeNum);
  has negint => ( is => 'rw', isa => NegativeInt);
}

my $ins = FooTest->new;

dies_ok { $ins->digit(100); } 'SingleDigit';
lives_ok { $ins->digit(1); } 'SingleDigit 2';

dies_ok { $ins->posint(-100); } 'PositiveInt';
dies_ok { $ins->posint(100.885); } 'PositiveInt 2';
lives_ok { $ins->posint(100); } 'PositiveInt 3';
lives_ok { $ins->posnum(100.885); } 'PositiveNum';
dies_ok { $ins->posnum(-100.885); } 'PositiveNum 2';

dies_ok { $ins->negint(100); } 'NegativeInt';
dies_ok { $ins->negint(-100.885); } 'NegativeInt 2';
lives_ok { $ins->negint(-100); } 'NegativeInt 3';
lives_ok { $ins->negnum(-100.885); } 'NegativeNum';
dies_ok { $ins->negnum(100.885); } 'NegativeNum 2';
