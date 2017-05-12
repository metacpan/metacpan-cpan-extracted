package Peco::Container::Abstract;

use strict;

use Carp ();
use base qw/Peco::Container/;

sub state { Carp::croak( 'abstract' ) }

1;
