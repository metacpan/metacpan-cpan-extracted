package SetSubClass;
use strict;
use warnings;

use base qw(Set::Object);

sub set {
    if (eval { $_[0]->isa(__PACKAGE__) }) {
    	shift;
    }
    __PACKAGE__->new(@_);
}



1; # Magic true value required at end of module