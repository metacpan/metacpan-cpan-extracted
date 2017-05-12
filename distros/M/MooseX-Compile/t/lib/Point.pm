#!/usr/bin/perl

package Point;	
use Moose;

has 'x' => (isa => 'Int', is => 'ro');
has 'y' => (isa => 'Int', is => 'rw');

sub clear {
    my $self = shift;
    $self->{x} = 0;
    $self->y(0);    
}

__PACKAGE__->meta->make_immutable();

__PACKAGE__;

__END__
