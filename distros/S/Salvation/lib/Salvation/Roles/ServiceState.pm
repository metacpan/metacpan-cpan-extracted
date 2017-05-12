use strict;

package Salvation::Roles::ServiceState;

use Moose::Role;

has 'state'	=> ( is => 'ro', isa => 'Salvation::Service::State', lazy => 1, default => sub{ require Salvation::Service::State; return Salvation::Service::State -> new(); } );

no Moose::Role;

-1;

# ABSTRACT: Service reference definition

=pod

=head1 NAME

Salvation::Roles::ServiceState - Service state reference definition

=head1 REQUIRES

L<Moose::Role> 

=head1 METHODS

=head2 state

 $self -> state();

Return appropriate L<Salvation::Service::State> object instance.

=cut

