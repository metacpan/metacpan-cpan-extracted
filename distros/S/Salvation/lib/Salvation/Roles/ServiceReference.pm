use strict;

package Salvation::Roles::ServiceReference;

use Moose::Role;

has 'service' => ( is => 'ro', isa => 'Salvation::Service', default => undef, lazy => 1, weak_ref => 1, required => 1 );

no Moose::Role;

-1;

# ABSTRACT: Service reference definition

=pod

=head1 NAME

Salvation::Roles::ServiceReference - Service reference definition

=head1 REQUIRES

L<Moose::Role> 

=head1 METHODS

=head2 service

 $self -> service();

Return appropriate L<Salvation::Service>-derived object instance.

=cut

