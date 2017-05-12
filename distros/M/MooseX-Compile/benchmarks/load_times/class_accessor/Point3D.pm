#!/usr/bin/perl

package Point3D;
use Moose;

use base qw(Point);

__PACKAGE__->mk_accessors(qw(z));

sub clear {
    my $self = shift;
    $self->SUPER::clear(@_);
    $self->{z} = 0;
};

__PACKAGE__

__END__
