package Mongol::Roles::Relations;

use Moose::Role;
use Moose::Util qw( does_role find_meta );

use Class::Load qw( load_class );

use Lingua::EN::Inflect qw( PL );

requires( qw( id find find_one retrieve delete ) );

sub has_many {
	my ( $class, $type, $foreign_key, $moniker ) = @_;

	die( 'No type defined!' )
		unless( defined( $type ) );

	die( 'No foreign key defined!' )
		unless( $foreign_key );

	$moniker = _get_moniker( $type )
		unless( $moniker );

	_load_class( $type );

	my $meta = find_meta( $class );

	$meta->add_method( sprintf( 'add_%s', $moniker ) => sub {
			my ( $self, $data, $options ) = @_;

			$data->{ $foreign_key } = $self->id();

			return $type->new( $data )
				->save();
		}
	);

	$meta->add_method( sprintf( 'get_%s', PL( $moniker ) ) => sub {
			my ( $self, $query, $options ) = @_;

			$query ||= {};
			$query->{ $foreign_key } = $self->id();

			return $type->find( $query, $options );
		}
	);

	$meta->add_method( sprintf( 'get_%s', $moniker ) => sub {
			my ( $self, $id ) = @_;

			return $type->find_one(
				{
					_id => $id,
					$foreign_key => $self->id(),
				}
			);
		}
	);

	$meta->add_method( sprintf( 'remove_%s', PL( $moniker ) ) => sub {
			my ( $self, $query ) = @_;

			$query ||= {};
			$query->{ $foreign_key } = $self->id();

			return $type->delete( $query );
		}
	);
}

sub has_one {
	my ( $class, $type, $foreign_key, $moniker ) = @_;

	die( 'No type defined!' )
		unless( defined( $type ) );

	die( 'No foreign key defined!' )
		unless( $foreign_key );

	$moniker = _get_moniker( $type )
		unless( $moniker );

	_load_class( $type );

	my $meta = find_meta( $class );

	$meta->add_method( sprintf( 'get_%s', $moniker ) => sub {
			my $self = shift();

			return $type->retrieve( $self->$foreign_key() );
		}
	);
}

sub _load_class {
	my $type = shift();

	load_class( $type );
	die( sprintf( '%s cannot do basic operations!', $type ) )
		unless( does_role( $type, 'Mongol::Roles::Core' ) );
}

sub _get_moniker {
	my $type = shift();

	( my $name = $type ) =~ s/.+:://;
	return lc( $name );
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Mongol::Roles::Relations - Automatic relations builder

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 has_many

To be implemented.

=head2 has_one

To be implemented.

=head1 SEE ALSO

=over 4

=item *

L<MongoDB>

=back

=cut
