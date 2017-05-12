package ClosureLenientEnv;
# ABSTRACT: closure that is equal to another closure if it only differs by undefined environment or srcrefs

use 5.010;

use Scalar::Util qw(blessed);

use Class::Tiny::Antlers qw(-default around);
use namespace::clean;

extends 'Statistics::R::REXP::Closure';

## Loosen the equality check to accept another closure if it only
## differs by having an undefined environment
around _eq => sub {
    my $orig = shift;

    my ($self, $obj) = (shift, shift);

    ## if the other closure doesn't have attributes, compare
    ## only the class
    ( defined($obj->attributes) ?
      Statistics::R::REXP::_eq($self, $obj) :
      (blessed $obj && $obj->isa('Statistics::R::REXP::Closure')) ) &&

      ## compare arguments and their default values exactly
      _compare_deeply($self->args, $obj->args) &&
      ((scalar(grep {$_} @{$self->defaults}) == scalar(grep {$_} @{$obj->defaults})) ||
       _compare_deeply($self->defaults, $obj->defaults)) &&
       
       ## if the body is not a null and other closure doesn't have
       ## body attributes, compare only the body elements
       ( $self->body->is_null || defined($obj->body->attributes) ?
         _compare_deeply($self->body, $obj->body) :
         _compare_deeply($self->body->elements, $obj->body->elements)) &&
         
         ## if the other closure has undefined environment, accept that as OK
         (defined($obj->environment) ?
          _compare_deeply($self->environment, $obj->environment) : 1)
};


## we have to REXPs `_compare_deeply` this way because private methods
## aren't available in the subclass
sub _compare_deeply {
    Statistics::R::REXP::_compare_deeply(@_)
}

sub _type { 'shortdouble'; }

1; # End of ClosureLenientEnv
