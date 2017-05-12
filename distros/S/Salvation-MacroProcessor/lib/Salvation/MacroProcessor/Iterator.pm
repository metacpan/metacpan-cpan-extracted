use strict;

package Salvation::MacroProcessor::Iterator;

use Moose;

use Moose::Util::TypeConstraints;

subtype 'Salvation::MacroProcessor::Iterator::iterator_instance',
        as 'Object',
	where { $_ -> does( 'Salvation::MacroProcessor::Iterator::Compliance' ) };

no Moose::Util::TypeConstraints;


has '__iterator'	=> ( is => 'ro', isa => 'Salvation::MacroProcessor::Iterator::iterator_instance', required => 1, handles => { ( map{ ( $_ )x2 } ( 'to_start', 'to_end' ) ) }, init_arg => 'iterator' );

has '__postfilter'	=> ( is => 'ro', isa => 'CodeRef', required => 1, init_arg => 'postfilter' );


sub seek  { die 'improssible here' }
sub count { die 'improssible here' }

sub first
{
	my $self = shift;
	my $it   = $self -> __iterator();

	my $position = $it -> __position();

	$it -> to_start();

	my $node = $self -> next();

	$it -> seek( $position );

	return $node;
}

sub last
{
	my $self = shift;
	my $it   = $self -> __iterator();

	my $position = $it -> __position();

	$it -> to_end();

	my $node = $self -> prev();

	$it -> seek( $position );

	return $node;
}

sub next
{
	my $self = shift;
	my $it   = $self -> __iterator();

	while( my $node = $it -> next() )
	{
		if( $self -> __postfilter() -> ( $node ) )
		{
			return $node;
		}
	}

	return undef;
}

sub prev
{
	my $self = shift;
	my $it   = $self -> __iterator();

	while( my $node = $it -> prev() )
	{
		if( $self -> __postfilter() -> ( $node ) )
		{
			return $node;
		}
	}

	return undef;
}


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1

__END__

# ABSTRACT: An iterator for reading query results

=pod

=head1 NAME

Salvation::MacroProcessor::Iterator - An iterator for reading query results

=head1 DESCRIPTION

=head2 What is it?

B<Salvation::MacroProcessor::Iterator> is an iterator class. It should be wrapped around your custom iterator and supplied some C<postfilter>ing function which will execute L<Salvation::MacroProcessor::MethodDescription>C<::postfitler> routine.

=head2 Example usage

 my $it = Salvation::MacroProcessor::Iterator -> new(
 	postfilter => $CodeRef,
	iterator => $it
 );

=head1 REQUIRES

L<Moose> 

=head1 METHODS

=head2 new

 Salvation::MacroProcessor::Iterator -> new(
 	postfilter => $CodeRef,
	iterator => $it
 )

Constructor.

Returns B<Salvation::MacroProcessor::Iterator> instance.

Arguments:

=over

=item postfilter

A CodeRef matching following signature:

 ( Any $object )

. C<$object> is an object representing a single row of data returned by the query.

C<$CodeRef> function will be executed for each row to check if this row is suitable as a result for caller, or not.

Boolean value should be returned, C<false> means "skip this object" and C<true> means "yes, this object is what we want".

It is common to make C<$CodeRef> look like that:

 sub
 {
 	$spec -> __postfilter_each( shift )
 }

, where C<$spec> is a L<Salvation::MacroProcessor::Spec> instance.

=item iterator

An Object that does L<Salvation::MacroProcessor::Iterator::Compliance> role.

B<Salvation::MacroProcessor::Iterator> will be wrapped around this object.

=back

=head2 first

 $object -> first()

Returns first element of a list.

=head2 last

 $object -> last()

Returns last element of a list.

=head2 next

 $object -> next()

Returns element at current position, then increases position by one.

=head2 prev

 $object -> prev()

Returns element at current position, then decreases position by one.

=cut

