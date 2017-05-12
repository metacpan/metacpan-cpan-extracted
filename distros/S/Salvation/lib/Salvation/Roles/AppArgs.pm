use strict;

package Salvation::Roles::AppArgs;

use Moose::Role;

has 'args' => ( is => 'rw', isa => 'HashRef', default => sub{ {} }, lazy => 1 );

no Moose::Role;

-1;

# ABSTRACT: Application arguments definition

=pod

=head1 NAME

Salvation::Roles::AppArgs - Application arguments definition

=head1 REQUIRES

L<Moose::Role> 

=head1 ATTRIBUTES

=head2 args

 $self -> args()
 $self -> args( \%args )

An arguments HashRef.

=cut

