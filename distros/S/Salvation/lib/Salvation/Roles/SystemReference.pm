use strict;

package Salvation::Roles::SystemReference;

use Moose::Role;

has 'system' => ( is => 'ro', isa => 'Salvation::System', default => undef, lazy => 1, required => 1 );

no Moose::Role;

-1;

# ABSTRACT: System reference definition

=pod

=head1 NAME

Salvation::Roles::SystemReference - System reference definition

=head1 REQUIRES

L<Moose::Role> 

=head1 METHODS

=head2 system

 $self -> system();

Return appropriate L<Salvation::System>-derived object instance.

=cut

