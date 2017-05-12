use strict;

package Salvation::Service::View::Stack::Frame::List;

use Moose;

extends 'Salvation::Service::View::Stack::Frame';

has 'cap'       => ( is => 'rw', isa => 'Maybe[Str]' );

has 'ftype'	=> ( is => 'rw', isa => 'Maybe[Str]' );

has 'is_list'	=> ( is => 'ro', isa => 'Bool', default => 1, init_arg => undef );

has 'data'	=> ( is => 'ro', isa => 'Undef', init_arg => undef );

has '_frames'   => ( is  	=> 'rw',
		     isa 	=> 'ArrayRef[Salvation::Service::View::Stack::Frame]',
		     init_arg 	=> 'data',
		     default 	=> sub{ [] },
		     predicate 	=> '_has_frames',
		     clearer 	=> '_clear_frames',
		     lazy 	=> 1
		   );

has '_index'    => ( is 	=> 'rw',
		     isa 	=> 'Int',
		     default 	=> 0,
		     init_arg 	=> undef,
		     clearer 	=> '_clear_index',
		     lazy 	=> 1
		   );

has '_byname'	=> ( is 	=> 'rw',
		     isa 	=> 'HashRef',
		     init_arg 	=> undef,
		     default 	=> sub{ {} },
		     clearer 	=> '_clear_byname',
		     lazy 	=> 1
		   );

has '_bytype'	=> ( is 	=> 'rw',
		     isa 	=> 'HashRef',
		     init_arg 	=> undef,
		     default 	=> sub{ {} },
		     clearer 	=> '_clear_bytype',
		     lazy 	=> 1
		   );

sub BUILD
{
        my $self = shift;

	if( $self -> _has_frames() )
	{
		my @frames = @{ $self -> _frames() };

		$self -> wipe_data();

		$self -> add( @frames );
	}
}

sub wipe_data
{
	my $self = shift;

	$self -> _clear_frames();
	$self -> _clear_index();
	$self -> _clear_byname();
	$self -> _clear_bytype();

	return undef;
}

sub add
{
        my $self = shift;

        my $idx = $self -> _index();

	my $byname = $self -> _byname();
	my $bytype = $self -> _bytype();

        foreach my $frame ( @_ )
        {
                ++$idx;

                $frame -> id( $idx );

		if( $frame -> fname() )
		{
			push @{ $byname -> { $frame -> fname() } }, $frame -> id();
		}

		if( $frame -> ftype() )
		{
			push @{ $bytype -> { $frame -> ftype() } }, $frame -> id();
		}

                push @{ $self -> _frames() }, $frame;
        }

        $self -> _index( $idx );

	$self -> _byname( $byname );
	$self -> _bytype( $bytype );

        return $idx;
}

around 'data' => sub
{
	shift;
	return shift -> _frames();
};

sub data_by_type
{
	my $self = shift;
	my $type = shift;

	return $self -> data_by_id( $self -> _bytype() -> { $type } );
}

sub data_by_name
{
	my $self = shift;
	my $name = shift;

	return $self -> data_by_id( $self -> _byname() -> { $name } );
}

sub data_by_id
{
	my $self = shift;
	my $id   = shift;

	my @ids  = ( ( ref( $id ) eq 'ARRAY' ) ? @$id : ( $id ) );

	my @output = map{ $self -> data() -> [ $_ - 1 ] } grep{ sprintf( '%d', $_ ) eq $_ } @ids;

	return ( wantarray ? @output
			   : \@output );
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: A list of a frames

=pod

=head1 NAME

Salvation::Service::View::Stack::Frame::List - A list of a frames

=head1 REQUIRES

L<Moose> 

=head1 DESCRIPTION

In example, if a view's template has this:

 some_type => [
 	'some_column'
 ]

then the view will generate L<Salvation::Service::View::Stack::Frame::List> object instance with C<fname> equal to C<some_type> containing an array of one element which is C<Salvation::Service::View::Stack::Frame> object instance with C<fname> equal to C<some_column> and C<ftype> equal to C<some_type>.

=head2 Subclass of

L<Salvation::Service::View::Stack::Frame>

=head1 METHODS

=head2 is_list

Boolean. Returns true.

=head2 cap

Is not set, so is C<undef>.

=head2 ftype

Is not set, so is C<undef>.

=head2 data

 $list -> data()

Returns an ArrrayRef of L<Salvation::Service::View::Stack::Frame>-derived object instances.

=head2 add

 $list -> add( @list );

Adds frames to the list. Each element of the C<@list> should be a L<Salvation::Service::View::Stack::Frame>-derived object instance.

Changes IDs of the frames being added.

=head2 data_by_id

 $list -> data_by_id( $integer );
 $list -> data_by_id( \@integers );

Find frames by IDs.

In scalar context returns an ArrayRef of L<Salvation::Service::View::Stack::Frame>-derived object instances.

In list context returns an array of L<Salvation::Service::View::Stack::Frame>-derived object instances.

=head2 data_by_name

 $list -> data_by_name( $fname );

Find frames which C<fname> matches C<$fname>.

In scalar context returns an ArrayRef of L<Salvation::Service::View::Stack::Frame>-derived object instances.

In list context returns an array of L<Salvation::Service::View::Stack::Frame>-derived object instances.

=head2 data_by_type

 $list -> data_by_type( $ftype );

Find frames which C<ftype> matches C<$ftype>.

In scalar context returns an ArrayRef of L<Salvation::Service::View::Stack::Frame>-derived object instances.

In list context returns an array of L<Salvation::Service::View::Stack::Frame>-derived object instances.

=head2 wipe_data

 $list -> wipe_data();

Clears current frame list.

=cut

