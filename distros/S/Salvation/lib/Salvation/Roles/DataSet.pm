use strict;

package Salvation::Roles::DataSet;

use Moose::Role;

use Salvation::Stuff '&load_class';

has 'dataset' => ( is => 'rw', isa => 'Maybe[Salvation::Service::DataSet]', lazy => 1, builder => '_build_dataset' );

sub _build_dataset
{
        my $self = shift;

        my $pkg = sprintf( '%s::DataSet',
                           ref( $self ) );

	my $service = undef;

	if( $self -> isa( 'Salvation::Service' ) )
	{
		$service = $self;

	} elsif( $self -> does( 'Salvation::Roles::ServiceReference' ) )
	{
		$service = $self -> service();
	}

        return ( &load_class( $pkg ) ? $pkg -> new( ( $service ? ( service => $service ) : () ) ) : undef );
}

no Moose::Role;

-1;

# ABSTRACT: DataSet reference definition

=pod

=head1 NAME

Salvation::Roles::DataSet - DataSet reference definition

=head1 REQUIRES

L<Moose::Role> 

=head1 METHODS

=head2 dataset

 $self -> dataset();

Return appropriate L<Salvation::Service::DataSet>-derived object instance.

=cut

