use strict;

package Salvation::Service::Intent;

use Moose;

with 'Salvation::Roles::AppArgs', 'Salvation::Roles::DataSet', 'Salvation::Roles::SharedStorage', 'Salvation::Roles::SystemReference', 'Salvation::Roles::ServiceState';

use Salvation::Stuff '&load_class';

use Carp 'confess';

use Scalar::Util 'blessed';

has '__service'	=> ( is => 'ro', isa => 'Str', required => 1, lazy => 1, default => undef, init_arg => 'service' );

has 'service' => ( is => 'ro', isa => 'Salvation::Service', builder => '_build_service', lazy => 1, init_arg => undef );

has '__built'	=> ( is => 'rw', isa => 'Bool', default => 0, init_arg => undef );

sub BUILD
{
	my $self = shift;

	$self -> __built( 1 );
}

sub DEMOLISH
{
	my $self = shift;

	$self -> __built( 0 );
}

sub _build_service
{
	my $self = shift;

	return ( &load_class( $self -> __service() ) ? $self -> __service() -> new(
		( map{ $_ => $self -> $_() } ( 'args', 'dataset', 'storage', 'system', 'state' ) )
	) : undef );
}

{
	our $AUTOLOAD;

	sub AUTOLOAD
	{
		my ( $self, @rest ) = @_;

		( my $method = $AUTOLOAD ) =~ s/^.*\:\://;

		if( $self -> __built() )
		{
			my $o = $self -> service();

			return $o -> $method( @rest ) if $o -> can( $method );

			confess( sprintf( 'Nor %s, nor %s has method %s', ( ref( $self ) or $self ), ( ref( $o ) or $o ), $method ) );
		}

		confess( sprintf( '%s has no method %s', ( ref( $self ) or $self ), $method ) );
	}
}

sub can
{
	my ( $self, @rest ) = @_;

	if( defined( my $code = $self -> SUPER::can( @rest ) ) )
	{
		return $code;
	}

	return $self -> service() -> can( @rest ) if blessed( $self ) and $self -> __built();

	return undef;
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Special object representing an intention of running another service within the same environment as the current one

=pod

=head1 NAME

Salvation::Service::Intent - Special object representing an intention of running another service within the same environment as the current one

=head1 SYNOPSIS

 $service_instance
 	-> intent( 'YourSystem::Services::OtherService' )
	-> start()
 ;

=head1 REQUIRES

L<Scalar::Util> 

L<Carp> 

L<Moose> 

=head1 DESCRIPTION

It C<AUTOLOAD>s service's methods.

=head2 Applied roles

L<Salvation::Roles::AppArgs>

L<Salvation::Roles::DataSet>

L<Salvation::Roles::SharedStorage>

L<Salvation::Roles::SystemReference>

L<Salvation::Roles::ServiceState>

=head1 METHODS

=head2 service

 $intent -> service();

Returns an appropriate L<Salvation::Service>-derived object instance.

=cut

