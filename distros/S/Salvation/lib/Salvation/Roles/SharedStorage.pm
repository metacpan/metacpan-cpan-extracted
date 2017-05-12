use strict;

package Salvation::Roles::SharedStorage;

use Moose::Role;

has 'storage' => ( is => 'rw', isa => 'Salvation::SharedStorage', lazy => 1, builder => '__build_storage' );

sub __build_storage
{
	require Salvation::SharedStorage;

	my $self = shift;
	my $o    = Salvation::SharedStorage -> new();

	if( $self -> isa( 'Salvation::Service' ) )
	{
		$o -> add_around_get_handler( sub
		{
			my ( $orig, $lself, $key, @rest ) = @_;

			$self -> system() -> on_service_shared_storage_get( {
				service  => ( ref( $self ) or $self ),
				instance => $self,
				key      => $key
			} );

			return $lself -> $orig( $key, @rest );
		} );

		$o -> add_around_put_handler( sub
		{
			my ( $orig, $lself, $key, $value, @rest ) = @_;

			$self -> system() -> on_service_shared_storage_put( {
				service  => ( ref( $self ) or $self ),
				instance => $self,
				key      => $key,
				value    => $value
			} );

			if( $key eq '$@' )
			{
				$self -> system() -> on_service_shared_storage_receives_error_notification( {
					service  => ( ref( $self ) or $self ),
					instance => $self,
					data     => $value
				} );
			}

			return $lself -> $orig( $key, $value, @rest );
		} );

	} elsif( $self -> isa( 'Salvation::System' ) )
	{
		$o -> add_around_get_handler( sub
		{
			my ( $orig, $lself, $key, @rest ) = @_;

			$self -> on_shared_storage_get( {
				key => $key
			} );

			return $lself -> $orig( $key, @rest );
		} );

		$o -> add_around_put_handler( sub
		{
			my ( $orig, $lself, $key, $value, @rest ) = @_;

			$self -> on_shared_storage_put( {
				key   => $key,
				value => $value
			} );

			if( $key eq '$@' )
			{
				$self -> on_shared_storage_receives_error_notification( {
					data => $value
				} );
			}

			return $lself -> $orig( $key, $value, @rest );
		} );
	}

	return $o;
}

no Moose::Role;

-1;

# ABSTRACT: Shared storage reference definition

=pod

=head1 NAME

Salvation::Roles::SharedStorage - Shared storage reference definition

=head1 REQUIRES

L<Moose::Role> 

=head1 METHODS

=head2 storage

 $self -> storage();

Return appropriate L<Salvation::SharedStorage> object instance.

=cut

