package Stem::ChatLabel ;

use strict ;


my $attr_spec = [

	{
		'name'		=> 'sw_addr',
		'help'		=> <<HELP,
This is the address of the chat switch
HELP
	},
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	return $self ;
}

sub data_in {

	my ( $self, $msg ) = @_ ;

	my $data = $msg->data() ;

#print "$$data" ;

	substr( $$data, 0, 0, $msg->from_cell() . ': ' ) ;

	$msg->data( $data ) ;
	$msg->to_cell( $self->{'sw_addr'} ) ;

	$msg->dispatch() ;
}

1 ;
