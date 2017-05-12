package World5 ;

use strict;

use base 'Stem::Cell' ;

my $attr_spec =
[
	{
		'name'		=> 'planet',
		'default'	=> 'world',
	},
	{
		'name'		=> 'cell_attr',
		'class'		=> 'Stem::Cell',
	},
];

sub new {

	my( $class ) = shift ;
	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

# Track the object in the class level hash %planets

	return ( $self );
}

sub triggered_cell {

	my( $self ) = @_ ;

	$self->{'planet'} = $self->cell_get_args( 'planet' ) || 'pluto' ;

	return;
}

# based on who was the receiver of the message
# we return with the appropriate response

sub hello_cmd {

	my( $self ) = @_;

	return "Hello world from $self->{'planet'}\n" ;
}

=head1 Stem Cookbook - World3

=head1 NAME

World5

=head1 DESCRIPTION

=cut

1;
