package Pipe::Tube::Say;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube::Print';

our $VERSION = '0.06';


sub run {
  my ($self, @input) = @_;
  my @unchomped =  map { "$_\n" } @input;
  $self->SUPER::run(@unchomped);
}


1;



