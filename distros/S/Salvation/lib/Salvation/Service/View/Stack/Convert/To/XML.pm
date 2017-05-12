use strict;

package Salvation::Service::View::Stack::Convert::To::XML;

use Salvation::Service::View::Stack::Parser ();

use IO::String ();

use XML::Writer ();

sub parse
{
	my ( undef, $stack, $args ) = @_;

	$args ||= {};

	my $writer = ( $args -> { 'writer' } or XML::Writer -> new(
		OUTPUT =>
			my $io = IO::String -> new(
				my $xml
			)
	) );

	my $charset        = ( $args -> { 'charset' } or 'UTF-8' );
	my $stack_tag_name = ( $args -> { 'tags' } -> { 'stack' } or 'stack' );
	my $list_tag_name  = ( $args -> { 'tags' } -> { 'list' }  or 'list' );
	my $frame_tag_name = ( $args -> { 'tags' } -> { 'frame' } or 'frame' );

	$writer -> xmlDecl( $charset ) unless $args -> { 'nocharset' };

	my %default_events = (
		before_stack => sub{ $writer -> startTag( $stack_tag_name ) },
		after_stack  => sub{ $writer -> endTag( $stack_tag_name ) },

		before_frame_list => sub{ $writer -> startTag( $list_tag_name, name => shift -> fname() ) },
		after_frame_list  => sub{ $writer -> endTag( $list_tag_name ) },

		before_frame_single => sub{
			my $frame = shift;

			$writer -> startTag( $frame_tag_name,
					     title => $frame -> cap(),
					     name  => $frame -> fname(),
					     type  => $frame -> ftype() );
		},
		after_frame_single  => sub{ $writer -> endTag( $frame_tag_name ) },

		raw => sub{ $writer -> cdata( shift or '' ) }
	);

	foreach my $event ( keys %default_events )
	{
		unless( exists $args -> { 'events' } -> { $event } )
		{
			$args -> { 'events' } -> { $event } = $default_events{ $event };
		}
	}

	{
		my %filter = (
			tags      => 1,
			charset   => 1,
			writer    => 1,
			nocharset => 1
		);

		Salvation::Service::View::Stack::Parser -> parse( $stack, { map{ $_ => $args -> { $_ } } grep{ not $filter{ $_ } } keys %$args } );
	}

	$io -> close() if $io;

	return $xml;
}

-1;

# ABSTRACT: Salvation::Service::View::Stack to XML converter

=pod

=head1 NAME

Salvation::Service::View::Stack::Convert::To::XML - L<Salvation::Service::View::Stack> to XML converter

=head1 SYNOPSIS

 my $writer = XML::Writer -> new( ... );

 my %args = (
 	writer => $writer,
	charset => 'UTF-8',
	nocharset => 0,
	tags => {
		stack => 'stack_xml_tag',
		list => 'list_xml_tag',
		frame => 'frame_xml_tag'
	},
	events => {
		...
	}
 );

 Salvation::Service::View::Stack::Convert::To::XML
 	-> parse(
		$stack,
		\%args
	)
 ;

=head1 REQUIRES

L<XML::Writer> 

L<IO::String> 

=head1 DESCRIPTION

=head2 Wraps over

L<Salvation::Service::View::Stack::Parser>

=head1 METHODS

=head2 parse

 Salvation::Service::View::Stack::Convert::To::XML -> parse( $stack, \%args );

Is just a wrapped C<Salvation::Service::View::Stack::Parser::parse> call.

Returns generated XML as plain text.

C<%args> can hold following additional keys:

=over 4

=item writer

An L<XML::Writer> object instance.

=item charset

XML charset. String. An argument to C<XML::Writer::xmlDecl>.
Default is C<UTF-8>.

=item nocharset

Boolean. Indicates whether L<Salvation::Service::View::Stack::Convert::To::XML> should set XML charset and produce xml declaration, or not.
Default is true.

=item tags

A HashRef. Tells parser which XML tags to use.

It can contain:

=over 8

=item stack

A tag representing a stack itself.
Default is C<stack> which produces following XML:

 <stack>...</stack>

=item list

A tag representing a frame list.
Default is C<list> which produces following XML:

 <list name="fname">...</list>

=item frame

A tag representing a single frame.
Default is C<frame> which produces following XML:

 <frame title="cap" name="fname" type="ftype">...</frame>

=back

=back

This module uses following event handlers:

=over

=item * before_stack

=item * after_stack

=item * before_frame_list

=item * after_frame_list

=item * before_frame_single

=item * after_frame_single

=item * raw

=back

Each C<%args> key is optional.

You can set other event handlers and redefine the ones set by the parser itself.

=cut

