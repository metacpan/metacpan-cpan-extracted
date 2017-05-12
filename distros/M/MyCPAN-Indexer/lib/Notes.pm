package MyCPAN::Indexer::Notes;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.28';

=head1 NAME

MyCPAN::Indexer::Notes - Tiny class for MyCPAN component note passing

=head1 SYNOPSIS	

Use in the coordinator object. This isn't really for the public.

=head1 DESCRIPTION

This is a scratchpad for the C<MyCPAN::Indexer> components. As a component
does part of its job, it can leave notes that other components can inspect
and use.

This is a low-level implementation, so it's stupid about the keys and
values that the components might use. It doesn't attempt to validate or
constrain the notes in any way. It can, however, act as a base class for
a custom notes class.

=cut

=head2 Methods

=over 4

=item new

Create a new notes object. This is really just a fancy hash. You probably
shouldn't call this yourself unless you are working in the coordinator
object.

=cut

sub new
	{
	my( $class ) = @_;
	
	my $self = bless {}, $class;
		
	$self;
	}

=item get_note( NOTE )

Get the note named C<NOTE>. This could be anything that was set: a
string, reference, and so on.

=cut

sub get_note { $_[0]->{$_[1]}         }

=item set_note( NOTE )

Set the note named C<NOTE>. This could be anything you like: a string,
reference, and so on.

=cut

sub set_note { $_[0]->{$_[1]} = $_[2] }

=back

=head2 Convenience methods

This saves you the hassle of getting the value with C<get_note>,
changing it, and saving the new value with C<set_note>.

=over 4

=item increment_note( NOTE )

Increase the value of NOTE by one. Returns the previous value of NOTE.

=cut

sub increment_note
	{
	my $value = $_[0]->get_note( $_[1] );
	$_[0]->set_note( $_[1], $value + 1 );
	$value;
	}

=item decrement_note( NOTE )

Decrease the value of NOTE by one. Returns the previous value of NOTE.

=cut

sub decrement_note
	{
	my $value = $_[0]->get_note( $_[1] );
	$_[0]->set_note( $_[1], $value - 1 );
	$value;
	}

=item push_onto_note( NOTE, LIST )

Add a value onto the end of the array reference value for NOTE.

=cut

sub push_onto_note
	{
	my( $self, $key, @list ) = @_;
	
	my $ref = $self->get_note( $key );
	croak( "Value for note [$key] is not an array reference" )
		unless ref $ref eq ref [];
	push @$ref, @list;
	}

=item unshift_onto_note( NOTE, LIST )

Add a value onto the front of the array reference value for NOTE.

=cut

sub unshift_onto_note
	{
	my( $self, $key, @list ) = @_;
	
	my $ref = $self->get_note( $key );
	croak( "Value for note [$key] is not an array reference" )
		unless ref $ref eq ref [];
	unshift @$ref, @list;
	}
	
=item get_note_list_element( NOTE, INDEX )

Return the list element at INDEX for the array reference stored in NOTE.

=cut

sub get_note_list_element
	{
	$_[0]->get_note( $_[1] )->[ $_[2] ]
	}

=item set_note_unless_defined( NOTE, VALUE )

Set the VALUE for NOTE unless NOTE already has a defined value. Returns
the current value if it is already defined.

=cut

sub set_note_unless_defined
	{
	my $value = $_[0]->get_note( $_[1] );
	return $value if defined $value;
	
	$_[0]->set_note( $_[1], $_[2] );
	}
	
=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
