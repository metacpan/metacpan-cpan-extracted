use strict;

package Salvation::MacroProcessor::MethodDescription;

use Moose;
use MooseX::StrictConstructor;

use Carp::Assert 'assert';

use Scalar::Util 'blessed';


has 'method'	=> ( is => 'ro', isa => 'Str', required => 1 );

has 'orig_method'	=> ( is => 'ro', isa => 'Str', lazy => 1, default => sub{ shift -> method() }, clearer => '__clear_orig_method' );

has 'associated_meta'	=> ( is => 'ro', isa => 'Class::MOP::Module', required => 1, weak_ref => 1 );

has 'connector_chain'	=> ( is => 'ro', isa => 'ArrayRef[ArrayRef[Str]]', default => sub{ [] } );


has 'previously_associated_meta'	=> ( is => 'ro', isa => 'Class::MOP::Module', weak_ref => 1, predicate => 'has_previously_associated_meta' );

has '__query'	=> ( is => 'ro', isa => 'ArrayRef|CodeRef', init_arg => 'query', lazy => 1, default => sub{ [] }, predicate => 'has_query' );

has '__postfilter'	=> ( is => 'ro', isa => 'CodeRef', lazy => 1, default => sub{ sub{} }, predicate => 'has_postfilter', init_arg => 'postfilter' );

has '__required_shares'	=> ( is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub{ [] }, predicate => 'has_required_shares', init_arg => 'required_shares' );

has '__required_filters'	=> ( is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub{ [] }, predicate => 'has_required_filters', init_arg => 'required_filters' );

has '__excludes_filters'	=> ( is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub{ [] }, predicate => 'has_excludes_filters', init_arg => 'excludes_filters' );

has '__imported'	=> ( is => 'ro', isa => 'Bool', default => 0, init_arg => 'imported' );


has 'inherited_description'	=> ( is => 'ro', isa => sprintf( 'Maybe[%s]', __PACKAGE__ ), lazy => 1, builder => '__build_inherited_description', init_arg => undef, clearer => '__clear_inherited_description' );

has 'attr'	=> ( is => 'ro', isa => 'Maybe[Moose::Meta::Attribute]', lazy => 1, builder => '__build_attr', weak_ref => 1, init_arg => undef, clearer => '__clear_attr' );


sub clone
{
	my ( $self, %overrides ) = @_;

	my $clone = $self -> meta() -> clone_object( $self, %overrides );

	$clone -> __clear_orig_method() if exists $overrides{ 'method' } and not exists $overrides{ 'orig_method' };
	$clone -> __clear_inherited_description() if exists $overrides{ 'previously_associated_meta' };
	$clone -> __clear_attr() if exists $overrides{ 'associated_meta' };

	return $clone;
}

sub __build_inherited_description
{
	my $self = shift;

	if( $self -> has_previously_associated_meta() )
	{
		return $self -> previously_associated_meta() -> smp_find_description_by_name( $self -> method() );
	}

	return undef;
}

sub __build_attr
{
	my $self = shift;

	return $self -> associated_meta() -> find_attribute_by_name( $self -> orig_method() );
}

sub query
{
	my $self       = shift;
	my $shares     = undef;
	my $has_shares = 0;

	if( scalar( @_ ) == 2 )
	{
		$shares     = shift;
		$has_shares = 1;
	}

	my $value = shift;
	my @query   = ();

	assert( ref( $shares ) eq 'HASH' ) if $has_shares;

	{
		my $present_shares = join( ', ', map{ sprintf( '"%s"', $_ ) } keys %$shares );

		foreach my $share ( @{ $self -> required_shares() } )
		{
			assert( exists( $shares -> { $share } ), sprintf( 'Share "%s" is required for filter "%s" of class "%s", but not present. Present shares: %s', $share, $self -> method(), $self -> associated_meta() -> name(), $present_shares ) );
		}
	}

	my @inner_args = ( ( $has_shares ? $shares : () ), $value );

#	if( my $id = $self -> inherited_description() )
#	{
#		push @query, @{ $id -> query( @inner_args ) };
#	}

	if( $self -> has_query() )
	{
		my $query = $self -> __query();

		if( ref( $query ) eq 'CODE' )
		{
			assert( ref( $query = $query -> ( @inner_args ) ) eq 'ARRAY' );
		}

		push @query, @$query;

	} elsif( my $attr = $self -> attr() )
	{
		my $meta = $self -> associated_meta();

		assert( ( my $hook = $meta -> smp_hook() ), sprintf( 'Cannot process attribute "%s" for class "%s": no hook specified', $attr -> name(), $meta -> name() ) );

		push @query, $hook -> query_from_attribute( $self, $attr, @inner_args );

	} elsif( not $self -> has_postfilter() )
	{
		assert( 0, sprintf( 'Cannot process attribute "%s" for class "%s": do no know how', $self -> method(), $self -> associated_meta() -> name() ) );
	}

	return \@query;
}

sub postfilter
{
	my ( $self, $node, $value ) = @_;

#	if( my $id = $self -> inherited_description() )
#	{
#		unless( $id -> postfilter( $node, $value ) )
#		{
#			return 0;
#		}
#	}

	if( $self -> has_postfilter() )
	{
		return $self -> __postfilter() -> ( $node, $value );
	}

	return 1;
}

sub required_shares
{
	my $self   = shift;
	my @shares = ();

#	if( my $id = $self -> inherited_description() )
#	{
#		push @shares, @{ $id -> required_shares() };
#	}

	if( $self -> has_required_shares() )
	{
		push @shares, @{ $self -> __required_shares() };
	}

	return \@shares;
}

sub required_filters
{
	my $self    = shift;
	my @filters = ();

#	if( my $id = $self -> inherited_description() )
#	{
#		push @filters, @{ $id -> required_filters() };
#	}

	if( $self -> has_required_filters() )
	{
		push @filters, @{ $self -> __required_filters() };
	}

	return \@filters;
}

sub excludes_filters
{
	my $self    = shift;
	my @filters = ();

#	if( my $id = $self -> inherited_description() )
#	{
#		push @filters, @{ $id -> excludes_filters() };
#	}

	if( $self -> has_excludes_filters() )
	{
		push @filters, @{ $self -> __excludes_filters() };
	}

	return \@filters;
}


__PACKAGE__ -> meta() -> make_immutable();

no MooseX::StrictConstructor;
no Moose;

-1;

__END__

# ABSTRACT: Method description object

=pod

=head1 NAME

Salvation::MacroProcessor::MethodDescription - Method description object

=head1 DESCRIPTION

=head1 REQUIRES

L<Scalar::Util> 

L<Carp::Assert> 

L<MooseX::StrictConstructor> 

L<Moose> 

=head1 METHODS

=head2 new

 Salvation::MacroProcessor::MethodDescription -> new(
 	method => $method,
 	orig_method => $orig_method,
	associated_meta => $associated_meta,
	previously_associated_meta => $previously_associated_meta,
	query => $query,
	postfilter => $postfilter,
	required_shares => $required_shares,
	required_filters => $required_filters,
	excludes_filters => $excludes_filters,
	imported => $imported,
	connector_chain => $connector_chain
 )

Constructor.

Returns B<Salvation::MacroProcessor::MethodDescription> instance.

Only C<method> and C<associated_meta> arguments are required.

Mostly all arguments documented at this section below, or at C<smp_add_description> function documentation of L<Salvation::MacroProcessor> module, except C<imported> argument which is simply a boolean value where C<true> means "this description is imported from some other class" and C<false> means "this description is not imported from anywhere".

=head2 method

 $description -> method();

Returns a name of the description. Usually matches a name of the method being described, though can be different in some cases.

=head2 orig_method

 $description -> orig_method();

Returns an original name of the description. In example, if the description of method named C<id> has been imported into another class with prefix C<parent_>, then such description will have C<method> equal to C<parent_id> and C<orig_method> equal to C<id>.

=head2 associated_meta

 $description -> associated_meta();

Returns L<Moose::Meta::Class> or L<Moose::Meta::Role> object instance corresponding to the object which has defined the description.

=head2 connector_chain

 $description -> connector_chain();

Return an ArrayRef. Each element is another ArrayRef containing two elements:

=over

=item class name

String. A name of the class where the description has been imported.

=item connector name

String. A name of the connector which has been used to import description.

=back

This will hold the whole import chain for description being imported.

=head2 previously_associated_meta

 $description -> previously_associated_meta();

Returns L<Moose::Meta::Class> or L<Moose::Meta::Role> object instance corresponding to the object which has defined the description. It is used when child class inherits a description from its parent and holds the reference to parent's class metaclass.

=head2 inherited_description

 $description -> inherited_description();

Returns L<Salvation::MacroProcessor::MethodDescription> object instance as it has been defined by a parent class if the description has been inherited.

=head2 attr

 $description -> attr();

Returns L<Moose::Meta::Attribute> object instance if the description is for attribute instead of plain method.

=head2 clone

 $description -> clone();

Clones description, returning new-made clone.

=head2 excludes_filters

 $description -> excludes_filters();

Returns an ArrayRef. Each element is the name of conflicting description.

=head2 postfilter

 $description -> postfilter( $object, $value );

Returns boolean value. Executes custom description's post-filtering code. See C<postfilter> argument of L<Salvation::MacroProcessor>C<::smp_add_description> method.

=head2 query

 $description -> query( $value );
 $description -> query( $shares, $value );

Returns ArrayRef which is a processed query part for this description, customized for given C<$value> and C<$shares> as told by C<query> argument of L<Salvation::MacroProcessor>C<::smp_add_description> or L<Salvation::MacroProcessor::Hooks>C<::query_from_attribute> call, if any is applicable.

=head2 required_filters

 $description -> required_filters();

Returns an ArrayRef. Each element is the name of required description.

=head2 required_shares

 $description -> required_shares();

Returns an ArrayRef. Each element is the name of required share.

=cut

