package Stem::Demo::CLI ;

print "LOAD\n" ;

use strict;

use base 'Stem::Cell' ;

my $attr_spec = [
		 {
		  name      => 'reg_name',
		  help      => <<HELP,
Name this Cell was registered with.
HELP
	 },
		 {
		  name	    => 'cell_attr',
		  class	    => 'Stem::Cell',
		  help	    => <<HELP,
This value is the attributes for the included Stem::Cell which handles
cloning and sequencing.
HELP
	 },
];

sub new {

	my( $class ) = shift ;
#print "ARGS [@_]\n" ;
	my $self = Stem::Class::parse_args( $attr_spec, @_ );
	return $self unless ref $self;

	return $self ;
}

sub triggered_cell {

	my( $self ) = @_ ;

print "TRIGGERED\n" ;

	$self->cell_activate;

#print $self->SUPER::_dump( "CLI TRIGGERED\n" ) ;

	return;
}

my %op_to_code = (

	set	=> \&_set,
	get	=> \&_get,
	dump	=> \&_dump,
	clear	=> \&_clear,
	help	=> \&_help,
) ;

sub data_in {

	my( $self, $msg ) = @_;

#print $msg->dump( 'IN' ) ;

	$self->{data_in_msg} = $msg ;

	my $data = $msg->data() ;

	my $op = $data->{op} ;

	if( my $code = $op_to_code{ $op } ) {

		$self->$code( $data ) ;
	}
	else {

		$self->send_reply( "unknown CLI op '$op'" ) ;
	}
}

sub send_reply {

	my ( $self, $data ) = @_;

	my $in_msg = delete $self->{data_in_msg} ;

	my $reply_msg = $in_msg->reply( type => 'data', data => $data ) ;

#print $reply_msg->dump( 'REPLY' ) ;

	$reply_msg->dispatch() ;
}

sub _set {

	my( $self, $data ) = @_;

	my $key = $data->{key} ;
	if ( defined( $key ) ) {

		my $value = $data->{value} ;

		$self->{data}{$key} = $value ;

		$self->send_reply( "set '$key' to '$value'" ) ;
	}
	else {
		$self->send_reply( "set is missing a key" ) ;
	}
}

sub _get {

	my( $self, $data ) = @_;

	my $key = $data->{key} ;
	if ( defined( $key ) ) {

		my $value = $self->{data}{$key} ;

		$self->send_reply( "'$key' was set to '$value'" ) ;
	}
	else {
		$self->send_reply( "get is missing a key" ) ;
	}
}

sub _clear {

	my( $self ) = @_;

	$self->{data} = {} ;
	$self->send_reply( "cleared your data" ) ;
}

sub _dump {

	my( $self ) = @_;

	my $text = join '', map "\t$_ => $self->{data}{$_}\n",
					sort keys %{$self->{data}} ;

	$self->send_reply( "your data is:\n$text\n" ) ;
}

sub _help {

	my( $self ) = @_;

	my $text = <<TEXT ;

These are the commands supported in Stem::Demo::CLI

set <name> <value>
get <name>
dump
clear
help

set sets a value in the CLI session hash
get gets a value in the CLI session hash
dump returns a dump of the session hash
clear will empty the the session hash
help prints this text

TEXT

	$self->send_reply( $text ) ;
}


1 ;
