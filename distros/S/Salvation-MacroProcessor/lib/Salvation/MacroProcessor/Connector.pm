use strict;

package Salvation::MacroProcessor::Connector;

use Moose;
use MooseX::StrictConstructor;

use Carp::Assert 'assert';

use Scalar::Util 'blessed';


has 'name'	=> ( is => 'ro', isa => 'Str', required => 1 );

has 'associated_meta'	=> ( is => 'ro', isa => 'Class::MOP::Module', required => 1, weak_ref => 1 );

has 'code'	=> ( is => 'ro', isa => 'CodeRef', required => 1 );


has 'previously_associated_meta'	=> ( is => 'ro', isa => 'Class::MOP::Module', weak_ref => 1, predicate => 'has_previously_associated_meta' );

has '__required_shares'	=> ( is => 'ro', isa => 'ArrayRef[Str]', predicate => 'has_required_shares', init_arg => 'required_shares' );


has 'inherited_connector'	=> ( is => 'ro', isa => sprintf( 'Maybe[%s]', __PACKAGE__ ), lazy => 1, builder => '__build_inherited_connector', init_arg => undef, clearer => '__clear_inherited_connector' );

sub clone
{
	my ( $self, %overrides ) = @_;

	my $clone = $self -> meta() -> clone_object( $self, %overrides );

	$clone -> __clear_inherited_connector() if exists $overrides{ 'previously_associated_meta' };

	return $clone;
}

sub __build_inherited_connector
{
	my $self = shift;

	if( $self -> has_previously_associated_meta() )
	{
		return $self -> previously_associated_meta() -> smp_find_connector_by_name( $self -> name() );
	}

	return undef;
}

sub required_shares
{
	my $self   = shift;
	my @shares = ();

#	if( my $id = $self -> inherited_connector() )
#	{
#		push @shares, @{ $id -> required_shares() };
#	}

	if( $self -> has_required_shares() )
	{
		push @shares, @{ $self -> __required_shares() };
	}

	return \@shares;
}


__PACKAGE__ -> meta() -> make_immutable();

no MooseX::StrictConstructor;
no Moose;

-1;

__END__

# ABSTRACT: An object representing interconnection between two classes

=pod

=head1 NAME

Salvation::MacroProcessor::Connector - An object representing interconnection between two classes

=head1 REQUIRES

L<Scalar::Util> 

L<Carp::Assert> 

L<MooseX::StrictConstructor> 

L<Moose> 

=head1 METHODS

=head2 new

 Salvation::MacroProcessor::Connector -> new(
 	name => $name,
	code => $code,
	associated_meta => $associated_meta,
	previously_associated_meta => $previously_associated_meta,
	required_shares => $required_shares
 )

C<name>, C<code> and C<associated_meta> are required arguments.

Constructor.

Returns L<Salvation::MacroProcessor::Connector> instance.

All arguments documented at this section below, or at C<smp_add_connector> function documentation of L<Salvation::MacroProcessor> module.

=head2 name

 $object -> name();

Returns string which is the name of this connector.

=head2 code

 $object -> code();

Returns CodeRef which is the actual connecting code.

=head2 associated_meta

 $object -> associated_meta();

Returns L<Moose::Meta::Class> or L<Moose::Meta::Role> object instance corresponding to the object which has defined the connector.

=head2 previously_associated_meta

 $object -> previously_associated_meta();

Returns L<Moose::Meta::Class> or L<Moose::Meta::Role> object instance corresponding to the object which has defined the connector. It is used when child class inherits a connector from its parent and holds the reference to parent's class metaclass.

=head2 inherited_connector

 $description -> inherited_connector();

Returns L<Salvation::MacroProcessor::Connector> object instance as it has been defined by a parent class if the connector has been inherited.

=head2 clone

 $object -> clone();

Clones connector, returning new-made clone.

=head2 required_shares

 $object -> required_shares();

Returns an ArrayRef. Each element is the name of required share.

=cut

