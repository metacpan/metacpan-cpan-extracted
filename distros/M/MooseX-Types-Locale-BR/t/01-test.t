#!perl 
use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

{
  package MyClass;
  use Moose;
  use MooseX::Types::Locale::BR;
  use namespace::autoclean;
  
  has state => ( is => 'rw', isa => 'MooseX::Types::Locale::BR::State' );
  has code  => ( is => 'rw', isa => 'MooseX::Types::Locale::BR::Code'  );
  
}

my $test = MyClass->new();
ok ( $test->state("Bahia"), "State Ok");
ok ( $test->code("MT"), "Code Ok");

throws_ok { $test->state("Porto Alegre") }
    qr/Must be a valid state/, 'Throws as "Porto Alegre" is not a valid state';

throws_ok { $test->code("PF") }
    qr/Must be a valid state's code/, 'Throws as "PF" is not a valid code';
