package Number::Object::Plugin::Tax::JP;

use strict;
use warnings;
use base 'Number::Object::Plugin::Tax';

use POSIX;

our $RATE = '1.08';

sub calc {
    my($self, $c) = @_;
    $self->SUPER::calc($c, $RATE);
}

1;
