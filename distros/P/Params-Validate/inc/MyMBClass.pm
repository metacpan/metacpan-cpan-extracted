package MyMBClass;

use strict;
use warnings;

use base 'Module::Build';

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    if ( defined( my $pp = $self->args('pp') ) ) {
        $self->pureperl_only($pp);
    }

    return $self;
}

1;

