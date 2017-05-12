package Puzzle::Utility;

our $VERSION = '0.02';
              
use Exporter; 
use strict;   

our @ISA = qw(Exporter);
our @EXPORT = qw(&isIn);

sub isIn {
  my $key = shift;
  $_ eq $key and return 1 for @_;
  return 0; 
} 

1;
