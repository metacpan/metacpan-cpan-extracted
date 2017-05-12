use strict;

package Salvation::Service::Controller;

use Moose;

with 'Salvation::Roles::ServiceReference';

sub init
{
}

sub main
{
}

sub before_view_processing
{
}

sub after_view_processing
{
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Base class for controller

=pod

=head1 NAME

Salvation::Service::Controller - Base class for controller

=head1 REQUIRES

L<Moose> 

=head1 DESCRIPTION

=head2 Applied roles

L<Salvation::Roles::ServiceReference>

=head1 METHODS

=head2 To be redefined

=head3 init

=head3 main

Two methods with the same semantics as the similarly named ones of L<Salvation::Service>. Put C<init> and C<main> inside your controller if you think these do not deserve to be inside your service.

=head3 before_view_processing

Special hook. Will be called when the service is about to begin view processing.
The only argument is C<$self> which is current view's instance.

=head3 after_view_processing

Special hook. Will be called when the service has just finished view processing.
The only argument is C<$self> which is current view's instance.

=cut

