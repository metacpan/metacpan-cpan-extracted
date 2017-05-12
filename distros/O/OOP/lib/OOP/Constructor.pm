package OOP::Constructor;

use strict;
use Carp;
use OOP::_getArgs;

sub set_args {

 my ($self, $ARGS) = @_;

 my $arguments = $ARGS->{ARGS} || croak "No arguments were passed to the prototype!";
 my $prototype = $ARGS->{PROTOTYPE} || croak "No prototype was passed to the prototype!";
 
 my %test;

 tie(%test, 'OOP::_getArgs', {
                             ARGS => $arguments,
                             PROTOTYPE => $prototype
               	            });

 return \%test;
 
}

1;
