use strict;

package Salvation::Service::DataSet;

use Moose;

with 'Salvation::Roles::ServiceReference';

has '__data'	=> ( is => 'rw', isa => 'ArrayRef[Defined]', lazy => 1, builder => 'main' );

has '__iterator'	=> ( is => 'rw', isa => 'Int', default => 0 );

sub main
{
	return [];
}

sub first
{
	return shift -> __data() -> [ 0 ];
}

sub last
{
	my $data = shift -> __data();

	return $data -> [ $#$data ];
}

sub get
{
	my ( $self, $index ) = @_;

	return $self -> __data() -> [ ( defined( $index ) ? $index : $self -> __iterator() ) ];
}

sub seek
{
	return shift -> __iterator( shift );
}

sub fetch
{
	my $self = shift;

	my $index = $self -> __iterator();
	my $data  = $self -> __data();

	return undef if $index > $#$data;

	my $result = $data -> [ $index ];

	$self -> __iterator( $index + 1 );

	return $result;
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Base class for DataSet

=pod

=head1 NAME

Salvation::Service::DataSet - Base class for DataSet

=head1 SYNOPSIS

 package YourSystem::Services::SomeService::DataSet;

 use Moose;

 extends 'Salvation::Service::DataSet';

 no Moose;

=head1 REQUIRES

L<Moose> 

=head1 DESCRIPTION

=head2 Applied roles

L<Salvation::Roles::ServiceReference>

=head1 METHODS

=head2 To be called

=head3 fetch

 $dataset -> fetch();

Returns next row from the DataSet moving current position of internal iterator one step forward.

=head3 first

 $dataset -> first();

Returns first row from the DataSet.

=head3 get

 $dataset -> get();
 $dataset -> get( $index );

Returns a row from the DataSet. C<$index> is an integer starting from zero. If C<$index> is omitted - current position of internal iterator is used.

=head3 last

 $dataset -> last();

Returns last row from the DataSet.

=head3 seek

 $dataset -> seek( $index );

Sets position of internal iterator. C<$index> is an integer starting from zero.

=head2 To be redefined

You can redefine following methods to achieve your own goals.

=head3 main

Should return an ArrayRef.
One element - one row. Each element is an abstract object that will be processed by a view, or somehow else if you want to.
The only argument is C<$self> which is current view's instance.

=cut

