use strict;

package Salvation::Service::View::Stack::Parser;

use Carp::Assert 'assert';

use Scalar::Util 'blessed';

sub parse
{
	my ( $self, $stack, $args ) = @_;

	$args ||= {};

	assert( blessed $stack );
	assert( $stack -> isa( 'Salvation::Service::View::Stack' ) );
	assert( $stack -> is_list() );

	$self -> __trigger( 'before_stack', $args, $stack );

	foreach my $node ( @{ $stack -> frames() } )
	{
		$self -> __parse_node( $node, $args );
	}

	$self -> __trigger( 'after_stack', $args, $stack );

	return 1;
}

sub __parse_node
{
	my ( $self, $node, $args ) = @_;

	$args ||= {};

	$self -> __trigger( 'before_node', $args, $node );

	if( blessed $node )
	{
		assert( $node -> isa( 'Salvation::Service::View::Stack::Frame' ) );

		$self -> __trigger( 'before_frame', $args, $node );

		if( $node -> is_list() )
		{
			$self -> __trigger( 'before_frame_list', $args, $node );

			foreach my $node ( @{ $node -> data() } )
			{
				$self -> __parse_node( $node, $args );
			}

			$self -> __trigger( 'after_frame_list', $args, $node );
		} else
		{
			$self -> __trigger( 'before_frame_single', $args, $node );

			$self -> __parse_node( $node -> data(), $args );

			$self -> __trigger( 'after_frame_single', $args, $node );
		}

		$self -> __trigger( 'after_frame', $args, $node );
	} else
	{
		$self -> __trigger( 'raw', $args, $node );
	}

	$self -> __trigger( 'after_node', $args, $node );

	return 1;
}

sub __trigger
{
	my ( undef, $event, $args, $node ) = @_;

	$args ||= {};

	if( ref( my $code = $args -> { 'events' } -> { $event } ) eq 'CODE' )
	{
		$code -> ( $node );
	}

	return 1;
}

-1;

# ABSTRACT: Salvation::Service::View::Stack parser

=pod

=head1 NAME

Salvation::Service::View::Stack::Parser - L<Salvation::Service::View::Stack> parser

=head1 SYNOPSIS

 my %args = (
 	events => {
 		before_stack => sub{ ... },
 		after_stack  => sub{ ... },

 		before_node => sub{ ... },
 		after_node  => sub{ ... },

 		before_frame => sub{ ... },
 		after_frame  => sub{ ... },

 		before_frame_list => sub{ ... },
 		after_frame_list  => sub{ ... },

 		before_frame_single => sub{ ... },
 		after_frame_single  => sub{ ... },

 		raw => sub{ ... }
 	}
 );

 Salvation::Service::View::Stack
 	-> parse(
		$stack,
		\%args
	)
 ;

=head1 REQUIRES

L<Scalar::Util> 

L<Carp::Assert> 

=head1 METHODS

=head2 parse

 Salvation::Service::View::Stack -> parse( $stack, \%args );

Parses a C<$stack> which should be a L<Salvation::Service::View::Stack> object instance and produces an output you want it to produce.

C<%args> can contain event handlers, as shown at SYNOPSIS.

Event handler should be CodeRef.
The only argument to event handler is C<$node> which is the object which is the subject of current event.

Events are:

=over

=item before_stack

Occurs when the parser is about to dive into L<Salvation::Service::View::Stack> object instance.

=item after_stack

Occurs when the parser is about to leave L<Salvation::Service::View::Stack> object instance.

=item before_node

Occurs when the parser has already dove into L<Salvation::Service::View::Stack> object instance and just met an object to be parsed.

=item after_node

Occurs when the parser has already dove into L<Salvation::Service::View::Stack> object instance and finished parsing an object.

=item before_frame

Occurs when the parser has already dove into L<Salvation::Service::View::Stack> object instance and just met a L<Salvation::Service::View::Stack::Frame>-derived object instance.

=item after_frame

Occurs when the parser has already dove into L<Salvation::Service::View::Stack> object instance and finished parsing a L<Salvation::Service::View::Stack::Frame>-derived object instance.

=item before_frame_list

Occurs when the parser has already dove into L<Salvation::Service::View::Stack> object instance and just met a L<Salvation::Service::View::Stack::Frame>-derived object instance which C<is_list> call returns true.

=item after_frame_list

Occurs when the parser has already dove into L<Salvation::Service::View::Stack> object instance and finished parsing a L<Salvation::Service::View::Stack::Frame>-derived object instance which C<is_list> call returns true.

=item before_frame_single

Occurs when the parser has already dove into L<Salvation::Service::View::Stack> object instance and just met a L<Salvation::Service::View::Stack::Frame>-derived object instance which C<is_list> call returns false.

=item after_frame_single

Occurs when the parser has already dove into L<Salvation::Service::View::Stack> object instance and finished parsing a L<Salvation::Service::View::Stack::Frame>-derived object instance which C<is_list> call returns false.

=item raw

Occurs when the parser has already dove into L<Salvation::Service::View::Stack> object instance and just met a raw frame content.

=back

Each C<%args> key and each event handler is optional.

=cut

