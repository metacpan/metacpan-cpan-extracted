use strict;

package Salvation::Service::Hook;

use Moose;

extends 'Salvation::Service';

has '__associated_service'	=> ( is => 'rw', isa => 'Salvation::Service', lazy => 1, default => undef, weak_ref => 1, predicate => '__has_associated_service', trigger => sub{ shift -> __associated_service_trigger( @_ ) } );

has '__parent_link'	=> ( is => 'rw', isa => sprintf( 'Maybe[%s]', __PACKAGE__ ), lazy => 1, default => undef, predicate => '__has_parent_link' );

has '__Call_cache'	=> ( is => 'rw', isa => 'ArrayRef[Any]', lazy => 1, default => sub{ [] }, predicate => '__has_Call_cache', clearer => '__clear_Call_cache' );


sub Call
{
	my ( $self, @rest ) = @_;

	if( $self -> __has_associated_service() )
	{
		$self -> __associated_service() -> Call( @rest );

	} else
	{
		push @{ $self -> __Call_cache() }, \@rest;
	}

	return 1;
}

sub init
{
	shift -> __associated_service() -> init( @_ );
}

sub main
{
	shift -> __associated_service() -> main( @_ );
}

sub __associated_service_trigger
{
	my $self = shift;

	if( $self -> __has_Call_cache() )
	{
		foreach my $args ( @{ $self -> __Call_cache() } )
		{
			$self -> Call( @$args );
		}

		$self -> __clear_Call_cache();
	}

	return 1;
}

sub __associate_with_hook
{
	my ( $self, $hook ) = @_;

	$hook -> __parent_link( $self );
	$hook -> __associated_service( $self -> __associated_service() );

	return 1;
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Base class for a hook

=pod

=head1 NAME

Salvation::Service::Hook - Base class for a hook

=head1 SYNOPSIS

 package YourSystem::Services::SomeService::Hooks::SomeType::SomeValue;

 use Moose;

 extends 'Salvation::Service::Hook';

 no Moose;

=head1 REQUIRES

L<Moose> 

=head1 DESCRIPTION

A special object used to override service's behaviour.

If the service has the hook and the hook has one or more things which can override service's original ones - hook ones will be used.

In example, if service C<S> has its own view (C<S::Defaults::V>) and model (C<S::Defaults::M>), and uses a hook right now (C<S::Hooks::ExampleType::ExampleValue>) which on its own has only a view (C<S::Hooks::ExampleType::ExampleValue::Defaults::V>) then C<S> will use C<S::Defaults::M> as the model and C<S::Hooks::ExampleType::ExampleValue::Defaults::V> as the view. This could be done with view, model, countroller and output processor. DataSet is unhookable.

Also you can define C<init> and C<main> methods for your hook to override service's ones (which are still accessible via C<SUPER::>).

A hook can C<Call> and C<Hook> too, as it is just a subclass of a service. The second gives you an ability to create chained hooks.

In addition to previous example, let's imagine that C<S::Hooks::ExampleType::ExampleValue> uses its own hook right now, say it is C<S::Hooks::ExampleType::ExampleValue::Hooks::ExampleType2::ExampleValue2> which has a controller (C<S::Hooks::ExampleType::ExampleValue::Hooks::ExampleType2::ExampleValue2::Defaults::C>). Then the service's contoller will be C<S::Hooks::ExampleType::ExampleValue::Hooks::ExampleType2::ExampleValue2::Defaults::C> instead of possible C<S::Hooks::ExampleType::ExampleValue::Defaults::C> or its original C<S::Defaults::C> if it had any.

To define a hook, two things should be done:

=over

=item 1. Hook spec should be added via C<Salvation::Service::Hook> call;

=item 2. Hook package should be present inside your project's directory.

=back

=head2 Subclass of

L<Salvation::Service>

=cut

