package OIS::InputManager;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);


sub createInputSystem {
    my ($self, @args) = @_;

    # passed in 1 arg, a window handle (i.e. a number)
    if (@args == 1) {
        if (looks_like_number($args[0])) {
            return $self->createInputSystemPtr(int($args[0]));
        }
        else {
            require Carp;
            Carp::confess(__PACKAGE__ . '::createInputSystem: ',
                          'single arg must be a number (window handle)' . $/);
        }
    }
    # passed in 2 args, a ParamList (hash)
    elsif (@args == 2) {
        return $self->createInputSystemPL(@args);
    }
    else {
        require Carp;
        Carp::confess(__PACKAGE__ . '::createInputSystem: ',
                      'missing required 1 or 2 args' . $/);
    }
}


1;
