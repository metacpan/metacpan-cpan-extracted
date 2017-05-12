use strict;

package Salvation::Service::View;

use Moose;

with 'Salvation::Roles::ServiceReference';

use Salvation::Service::View::SimpleCache;

use Salvation::Service::View::Stack ();
use Salvation::Service::View::Stack::Frame ();
use Salvation::Service::View::Stack::Frame::List ();

sub MULTINODE { 0 }

sub main
{
	return [];
}

sub process
{
	my $self   = shift;
	my @output = ();

	$self -> service() -> dataset() -> seek( 0 );

	while( my $node = $self -> service() -> dataset() -> fetch() )
	{
		push @output, $self -> process_node( $node );
	}

	$self -> service() -> dataset() -> seek( 0 );

	return $self -> service() -> state() -> view_output( ( $self -> MULTINODE() ? \@output : $output[ 0 ] ) );
}

sub process_node
{
	my ( $self, $obj, $order ) = @_;

	my $args  = $self -> service() -> args();

	my $type  = undef;
	my $stack = Salvation::Service::View::Stack -> new();

	foreach my $node ( @{ $order or $self -> main() } )
	{
		if( ref( $node ) eq 'ARRAY' )
		{
			my $list = Salvation::Service::View::Stack::Frame::List -> new( fname => $type );

			foreach my $subnode ( @$node )
			{
				if( $subnode )
				{
					my $flags = {};

					if( ref( $subnode ) eq 'HASH' )
					{
						( $subnode, $flags ) = %$subnode;
					}

					if( ref( $flags -> { 'constraint' } ) eq 'CODE' )
					{
						unless( $flags -> { 'constraint' } -> ( $self, $obj, $args ) )
						{
							next;
						}
					}

					my ( $val, $cap ) = ( undef, undef );

					{
						my $default_value_getter  = sprintf( '__%s', $type );
						my $specific_value_getter = sprintf( '%s_%s', $type, $subnode );

						# Both following arrays actually can contain one more element
						# that is a HashRef, and it's already used sometimes
						# so don't think you can just add another element here
						my $default_value_getter_args  = [ $obj, $subnode ];
						my $specific_value_getter_args = [ $obj ];

						my $rendered = undef;
						my $cacheid  = undef;
						my $cached   = undef;

						unless( $flags -> { 'nocache' } )
						{
							eval
							{
								if( $self -> service() -> model() -> can( $default_value_getter ) )
								{
									my ( $dry ) = ( $self -> service() -> model() -> $default_value_getter( @$default_value_getter_args, { raw => 1 } ) );

									if( defined $dry )
									{
										$cacheid = $self -> service() -> __cacheid( $subnode, $dry );
									}
								}
							};
						}

						if( $cacheid and &rsc_exists( $type, $cacheid ) )
						{
								( $val, $cap ) = @{ &rsc_retrieve( $type, $cacheid ) };
								$rendered = 1;
								$cached   = 1;
						}

ACTUAL_RENDERING_OF_EACH_NODE:
						foreach my $spec ( (
							{ name => $specific_value_getter, args => $specific_value_getter_args },
							{ name => $default_value_getter,  args => $default_value_getter_args }
						) )
						{
							my $name = $spec -> { 'name' };

							if( not $rendered and $self -> service() -> model() -> can( $name ) )
							{
								( $val, $cap ) = eval{ $self -> service() -> model() -> $name( @{ $spec -> { 'args' } } ) };

								if( my $err = $@ )
								{
									$self -> service() -> system() -> on_node_rendering_error( {
										'$@'     => $err,
										view     => ( ref( $self ) or $self ),
										instance => $self,
										spec     => $spec
									} );
								} else
								{
									$rendered = 1;
									last ACTUAL_RENDERING_OF_EACH_NODE;
								}
							}
						}

						if( $rendered and $cacheid and not $cached )
						{
							&rsc_store( $type, $cacheid, [ $val, $cap ] );
						}
					}

					if( not( $val ) and ( $args -> { 'skip_false' } or $flags -> { 'skip_false' } ) and not exists $flags -> { 'sticky' } )
					{
						next;
					}

					unless( defined $cap )
					{
						$cap = sprintf( '[FIELD_%s]',
								uc( $subnode ) );
					}

					my $frame = Salvation::Service::View::Stack::Frame -> new( ftype => $type,
											  fname => $subnode,
											  cap   => $cap,
											  data  => $val );

					$list -> add( $frame );
				}
			}

			if( scalar @{ $list -> data() or [] } )
			{
				$stack -> add( $list );
			}

		} elsif( ref( $node ) eq 'CODE' )
		{
			my $results = $node -> ( $self, $obj, $args );

			if( ref( $results ) eq 'HASH' )
			{
				my $frame = Salvation::Service::View::Stack::Frame -> new( %$results );

				$stack -> add( $frame );
			}

		} elsif( not ref $node )
		{
			$type = $node;
		}
	}

	return $stack;
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Base class for a view

=pod

=head1 NAME

Salvation::Service::View - Base class for a view

=head1 SYNOPSIS

 package YourSystem::Services::SomeService::Defaults::V;

 use Moose;

 extends 'Salvation::Service::View';

 no Moose;

=head1 DESCRIPTION

=head2 Applied roles

L<Salvation::Roles::ServiceReference>

=head1 REQUIRES

L<Moose> 

=head1 METHODS

=head2 To be called

=head3 process

 $view_instance -> process();

Processes service's DataSet with C<$view_instance> and sets a L<Salvation::Service::View::Stack> instance, or an ArrayRef of those instances (depending on C<MULTINODE> result), to C<view_output> attribute of appropriate L<Salvation::Service::State> instance, returning the value being set.

=head3 process_node

 $view_instance -> process_node( $object );
 $view_instance -> process_node( $object, \@template );

Processes C<$object> with C<$view_instance> using C<\@template> and returns L<Salvation::Service::View::Stack> instance.
C<@template> could containt anything C<main>'s returning value could containt.
Default C<@template> contents are C<main>'s returning value' contents.

=head2 To be redefined

You can redefine following methods to achieve your own goals.

=head3 MULTINODE

Should return boolean value.
Tells the view if it needs to process and return many rows returned by DataSet, or just one.
The only argument is C<$self> which is current view's instance.
Default value is false.

=head3 main

Should return an ArrayRef containing template data which will be used to process objects.

Each element of an ArrayRef could be either of the following:

=over 4

=item Non-reference scalar

A text which is interpreted as the type of each column listed in an ArrayRef which follows this text, if any.
Example usage:

 regular_database_column => [
 	'id',
	'name'
 ]

Having this, the view knows which methods of the model it needs to call in order to process each column.

=item ArrayRef

A list of column specs. Each element of such ArrayRef will be translated to model's method call.
Each element of an ArrayRef could be either of the following:

=over 8

=item Non-reference scalar

A text which is interpreted as the name of the column. Here an appropriate model's method call is happening.

In example, having an element named C<id> and column type already set to C<regular_database_column>, the view will generate model's method name like this:

 my $type   = 'regular_database_column';
 my $column = 'id';

 my $model_method = sprintf(
 	'%s_%s',
	$type,
	$column
 );

Then the view will check if the model C<can( $model_method )> and, if it is true, will call this method with an C<$object> argument where the C<$object> is the object being processed right now.

However, if the check returned false, the view will try to generate another method name like this:

 my $another_model_method = sprintf(
 	'__%s',
	$type
 );

Then the view will check if the model C<can( $another_model_method )> and, if it is true, will call this method with two arguments: C<$object> and C<$column> where the C<$object> is the object being processed right now and the C<$column> is the name of current column.

=item HashRef

Advanced column spec. Should contain one key and one value where key is the plain column name and the value is the HashRef which will be interpreted as column modifiers.

Example:

 some_type => [
 	'id',
	{ column => \%modifiers }
 ]

Column modifiers could be:

=over 12

=item constraint

A CodeRef which will be called in order to check whether the column needs to be processed, or needs to be skipped. Should return boolean value.

 constraint => sub
 {
	my ( $view_instance, $object_being_processed, $service_args ) = @_;

 	return ( int( rand( 2 ) ) == 1 );
 }

C<$service_args> is the returning value of view's service's C<args> method.

=item nocache

A boolean value.

By default, the view will try to calculate a value for current column using probably light model's method which name is generated like this:

 sprintf(
 	'__%s',
	$type
 )

Then the view will use this value in couple with the column's name and a few other parameters to produce some unique key.

Then the view will check its cache using L<Salvation::Service::View::SimpleCache> and if there is a value - this value will be used immediately as the column's value, skipping all the calculations described above.

But if the cache has no value for the key - this value will appear in the cache after all further calculations will be done, and will be reused if there will be a request to do the same calculations.

So yes, if the C<nocache> modifier is set to true - there will be no cache usage for such column.

=item skip_false

A boolean value.
If set to true, the column will not be included in the output if it has the value equivalent to PERL's false.
Default value is false.

=item sticky

As the opposite of C<skip_false>, C<sticky> guarantees that the column will be included in the output even if it's value is equivalent to PERL's false and C<skip_false> is set to true.

If the key C<sticky> exists in column modifiers list - it is true, otherwise it is false.

=back

=back

=item CodeRef

It will be executed for every object which is being processed with following arguments:

=over 8

=item $self

Current view's instance.

=item $object

An object being processed.

=item $args

Returning value of view's service's C<args> method.

=back

Returning value should be a HashRef containing arguments to the C<new> method of L<Salvation::Service::View::Stack::Frame>.

=back

=cut

