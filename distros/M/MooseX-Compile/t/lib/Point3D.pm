#!/usr/bin/perl

package Point3D;
use Moose;

extends 'Point';

has 'z' => (isa => 'Int');

sub clear {
    my $self = shift;
    $self->SUPER::clear(@_);
    $self->{z} = 0;
};

__PACKAGE__->meta->make_immutable();

__PACKAGE__;

__END__
