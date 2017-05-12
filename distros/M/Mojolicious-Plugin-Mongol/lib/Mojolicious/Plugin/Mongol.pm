package Mojolicious::Plugin::Mongol;

use Moose;

extends 'Mojolicious::Plugin';

use MongoDB;

use Mongol;

our $VERSION = '1.0';

sub register {
	my ( $self, $app, $config ) = @_;

	$app->attr( '_mongodb' => sub {
			return MongoDB->connect( $config->{host}, $config->{options} || {} );
		}
	);

	$app->helper( 'mongodb' => sub { shift()->app()->_mongodb() } );

	# Here's where the magic happens ...
	Mongol->map_entities( $app->_mongodb(), %{ $config->{entities} } );
}

__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Mongol - Mongol plugin for Mojolicious

=head1 SYNOPSIS

	sub startup {
		my $self = shift();

		$self->plugin( 'Mongol',
			{
				host => 'mongodb://localhost:27017',
				options => {},
				entities => {
					'My::Models::Person' => 'db.people',
					'My::Models::Address' => 'db.addresses',
				}
			}
		);
	}


=head1 DESCRIPTION

L<Mongol> plugin for Mojolicious.

=head1 HELPERS

=head2 mongodb

	sub action {
		my $self = shift();

		my $mongo = $self->mongodb();

		...

		return $self->render( json => undef );
	}

Just in case you need access to the MongoDB client instance you can use this helper to get it.

=head1 AUTHOR

Tudor Marghidanu <tudor@marghidanu.com>

=head1 SEE ALSO

=over

=item *

L<Mongol>

=back

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
