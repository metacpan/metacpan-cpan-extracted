#!/usr/bin/perl

package Point;	
use Moose;

use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(x y));

sub clear {
    my $self = shift;
    $self->{x} = 0;
    $self->y(0);    
}

__PACKAGE__

__END__
