use strict;

package Salvation::Service::Model;

use Moose;

with 'Salvation::Roles::ServiceReference';

sub main
{
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Base class for a model

=pod

=head1 NAME

Salvation::Service::Model - Base class for a model

=head1 SYNOPSIS

 package YourSystem::Services::SomeService::Defaults::M;

 use Moose;

 extends 'Salvation::Service::Model';

 no Moose;

=head1 REQUIRES

L<Moose> 

=head1 DESCRIPTION

A place for you to define how to process each column of each row returned by DataSet. Read more at L<Salvation::Service::View>.

=head2 Applied roles

L<Salvation::Roles::ServiceReference>

=head1 METHODS

=head2 main


=cut

