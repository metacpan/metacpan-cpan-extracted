use strict;

package Salvation::MacroProcessor::Spec;

use Moose;

use Moose::Util::TypeConstraints;

subtype 'Salvation::MacroProcessor::Spec::_moose_class_name',
	as 'Str',
	where { $_ -> isa( 'Moose::Object' ) };

coerce 'Salvation::MacroProcessor::Spec::_moose_class_name',
	from 'Object',
	via { ref $_ };

no Moose::Util::TypeConstraints;

use Salvation::MacroProcessor::Field ();
use Salvation::MacroProcessor::Iterator ();

use Carp::Assert 'assert';

use Scalar::Util 'blessed';


has 'fields'	=> ( is => 'ro', isa => 'ArrayRef[Salvation::MacroProcessor::Field]', traits => [ 'Array' ], required => 1, handles => {
	add_field  => 'push',
	all_fields => 'elements'
} );

has 'class'	=> ( is => 'ro', isa => 'Salvation::MacroProcessor::Spec::_moose_class_name', required => 1, coerce => 1 );

has 'query'	=> ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '__build_query', init_arg => undef );

has '__shares'	=> ( is => 'rw', isa => 'HashRef', default => sub{ {} } );


sub parse_and_new
{
	my ( $self, $class, $spec ) = @_;

	assert( ref( $spec ) eq 'ARRAY' );

	$self = $self -> new( class => $class, fields => [] );

	my $meta = ( $class = $self -> class() ) -> meta();

	foreach my $field_spec ( @$spec )
	{
		assert( ref( $field_spec ) eq 'ARRAY' );

		my ( $name, $value ) = @$field_spec;

		assert( ( my $description = $meta -> smp_find_description_by_name( $name ) ), sprintf( 'Class "%s" has no MacroProcessor description for method "%s"', $class, $name ) );

		$self -> add_field( Salvation::MacroProcessor::Field -> new(
			description => $description,
			value       => $value
		) );
	}

	return $self;
}

sub check
{
	my ( $self, $object ) = @_;

	if( blessed $object )
	{
		my $meta = $self -> class() -> meta();

		assert( ( my $hook = $meta -> smp_hook() ), sprintf( 'Cannot check instance of class "%s": no hook specified', $meta -> name() ) );

		return $hook -> check( $self, $object );
	}

	assert( 0, 'Dunno what to do' );
}

sub select
{
	my ( $self, $moar_query, $additional_args ) = @_;

	$moar_query        ||= [];
	$additional_args ||= [];

	my $meta = $self -> class() -> meta();

	assert( ( my $hook = $meta -> smp_hook() ), sprintf( 'Cannot select objects of class "%s": no hook specified', $meta -> name() ) );

	return $hook -> select( $self, $moar_query, $additional_args );
}

sub __postfilter
{
	my ( $self, @objects ) = @_;

	return grep{ $self -> __postfilter_each( $_ ) } @objects;
}

sub __postfilter_each
{
	my ( $self, $object ) = @_;

	foreach my $field ( $self -> all_fields() )
	{
		unless( $field -> postfilter( $object ) )
		{
			return 0;
		}
	}

	return 1;
}

sub __build_query
{
	my $self = shift;
	my @query  = ();

	my %present    = ();
	my %required   = ();
	my %excludes   = ();
	my %connectors = ();
	my @connectors = ();

	foreach my $field ( $self -> all_fields() )
	{
		if( ( my $connector_chain = $field -> connector_chain() ) -> [ 0 ] )
		{
			my $chain_hash = join( "\0", map{ @$_ } @$connector_chain );

			push @{ $connectors{ $chain_hash } -> { 'query' } }, @{ $self -> __get_field_query( $field ) };

			unless( exists $connectors{ $chain_hash } -> { 'connector_chain' } )
			{
				$connectors{ $chain_hash } -> { 'connector_chain' } = $connector_chain;

				push @connectors, $chain_hash;
			}

		} else
		{
			push @query, @{ $self -> __get_field_query( $field ) };
		}

		$present{ $field -> name() } = 1;

		foreach my $filter ( @{ $field -> required_filters() } )
		{
			$required{ $filter } -> { $field -> name() } = 1;
		}

		foreach my $filter ( @{ $field -> excludes_filters() } )
		{
			$excludes{ $filter } -> { $field -> name() } = 1;
		}
	}

	foreach my $filter ( keys %required )
	{
		assert( exists( $present{ $filter } ), sprintf( 'Filter "%s" is not present, but required by following filter(s) of class "%s": "%s"', $filter, $self -> class(), join( ', ', keys %{ $required{ $filter } } ) ) );
	}

	foreach my $filter ( keys %excludes )
	{
		assert( not( exists( $present{ $filter } ) ), sprintf( 'Filter "%s" conflicts with following filter(s) of class "%s": "%s"', $filter, $self -> class(), join( ', ', keys %{ $excludes{ $filter } } ) ) );
	}

	my %connectors_present = ();

	while( my $chain_hash = shift @connectors )
	{
		my $data = delete $connectors{ $chain_hash };

		my ( $chain_query, $connector_chain ) = delete @$data{ 'query', 'connector_chain' };

		foreach my $connector_spec ( @$connector_chain )
		{
			my ( $class, $connector_name ) = @$connector_spec;

			if( my $connector = $class -> meta() -> smp_find_connector_by_name( $connector_name ) )
			{
				my %shares     = ();
				my $has_shares = 0;

				foreach my $share ( @{ $connector -> required_shares() } )
				{
					$shares{ $share } = $self -> __get_shared_value( $share, $class );

					$has_shares ||= 1;
				}

				$chain_query = $connector -> code() -> ( ( $has_shares ? \%shares : () ), $chain_query );

				{
					my $rref = ref( $chain_query );

					assert( ( $rref eq 'ARRAY' ), sprintf( 'Connector "%s" of class "%s" should return ArrayRef instead of "%s"', $connector_name, $class, ( $rref or 'plain scalar' ) ) );
				}
			} else
			{
				assert( 0, sprintf( 'Class "%s" has no connector with name "%s"', $class, $connector_name ) );
			}
		}

		my $last_connector_hash = join( "\0", @{ $connector_chain -> [ $#$connector_chain ] } );

		unless( exists $connectors_present{ $last_connector_hash } )
		{
			$connectors_present{ $last_connector_hash } = 1;

			push @query, @$chain_query;
		}
	}

	return \@query;
}

sub __get_shared_value
{
	my ( $self, $name, $foreign_class ) = @_;

	my $class      = ( $foreign_class or $self -> class() );
	my $share_hash = join( "\0", ( $class, $name ) );

	if( exists $self -> __shares() -> { $share_hash } )
	{
		return $self -> __shares() -> { $share_hash };
	}

	if( ref( my $code = $class -> meta() -> smp_find_share_by_name( $name ) ) eq 'CODE' )
	{
		return $self -> __shares() -> { $share_hash } = [ $code -> () ];
	}

	assert( 0, sprintf( 'Class "%s" has no share with name "%s"', $class, $name ) );
}

sub __get_field_query
{
	my ( $self, $field ) = @_;

	my %shares     = ();
	my $has_shares = 0;

	foreach my $share ( @{ $field -> required_shares() } )
	{
		my $share_name = $share;

		{
			my $class = $self -> class();

			while( $class and ( my $share_import_spec = $class -> meta() -> smp_find_share_import_spec_by_name( $share_name ) ) )
			{
				if( $share_import_spec )
				{
					$share_name = ( $share_import_spec -> { 'orig' } or $share_name );
					$class      = $share_import_spec -> { 'class' };

				} else
				{
					$class = undef;
				}
			}
		}

		$shares{ $share_name } = $self -> __get_shared_value( $share );

		if( $share ne $share_name )
		{
			$shares{ $share } = undef; # compatibility crutch
		}

		$has_shares ||= 1;
	}

	return $field -> query( ( $has_shares ? \%shares : () ) );
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

__END__

# ABSTRACT: Query object

=pod

=head1 NAME

Salvation::MacroProcessor::Spec - Query object

=head1 REQUIRES

L<Scalar::Util> 

L<Carp::Assert> 

L<Moose> 

=head1 METHODS

=head2 parse_and_new

 Salvation::MacroProcessor::Spec -> parse_and_new( $class_or_object, $query );

Creates and returns new query object, an instance of B<Salvation::MacroProcessor::Spec> class.

C<$class_or_object> is a class name or instance of the class which will be the base class for the query. It has been thought of as "I will check or select objects of that type".

C<$query> is an object of type ArrayRef[ArrayRef[Any]]. It is the query you want to perform. Each inner ArrayRef represents a filter, a field which consists of two parameters: the first is the name and the second is the value. Imagine you have following C<$query> object:

 [
 	[ method => $value ]
 ]

. C<method> here is the name of the method description which will be the part of the query, and C<$value> is the value for this column, a condition for a filter. It should be thought of as "I want to select an object which method()' call returns the $value".

I.e., a query with two fields will look somewhat like this:

 [
 	[ method1 => $value1 ],
	[ method2 => $value2 ]
 ]

. Note this very explicit separation of fields.

=head2 select

 $spec -> select();

Selects objects.

=head2 check

 $spec -> check( $object );

Checks if given C<$object> could be selected using this C<$spec>.

C<$object> is an object representing a single row of data returned by the query.

=head2 new

 Salvation::MacroProcessor::Spec -> new(
 	class => $class,
	fields => $fields
 )

Constructor.

Returns B<Salvation::MacroProcessor::Spec> instance.

All arguments are required.

Arguments:

=over

=item class

String (could be coerced from Object though), the name of base class for this query.

=item fields

ArrayRef[Salvation::MacroProcessor::Field], list of fields used in this query.

=back

=head2 add_field

 $spec -> add_field( $field )

Add field to the list.

C<$field> is a L<Salvation::MacroProcessor::Field> instance.

=head2 all_fields

 $spec -> all_fields()

Returns an array of all fields (each is a L<Salvation::MacroProcessor::Field> instance) used in the query.

=head2 fields

 $spec -> fields()

Returns an ArrayRef of all fields (each is a L<Salvation::MacroProcessor::Field> instance) used in the query.

=head2 query

 $spec -> query()

Processes fields, aggregates query parts and returns an ArrayRef which contains the final query.

All aggregations and processing here are done only once per object instance, so the second call to C<query> of the same object instance will be much faster than first.

=cut

