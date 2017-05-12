
package Stem::Load::Driver ;

use strict ;

use Time::HiRes qw( gettimeofday tv_interval ) ;

my $attr_spec = [


	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
Name this Cell was registered with.
HELP
	},
	{
		'name'		=> 'load_addr',
		'help'		=> <<HELP,
Address to send the load messages
HELP
	},
	{
		'name'		=> 'load_data',
		'help'		=> <<HELP,
Data string to send.
HELP
	},
	{
		'name'		=> 'data_sizes',
		'help'		=> <<HELP,
Range of data sizes to select from randomly
HELP
	},
	{
		'name'		=> 'max_msg_cnt',
		'default'	=> 1000,
		'help'		=> <<HELP,
Maximum number of messages to send
HELP
	},
	{
		'name'		=> 'max_duration',
		'default'	=> 10,
		'help'		=> <<HELP,
Maximum number of seconds to run
HELP
	},
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	return $self ;
}

sub go_cmd {

	my( $self, $msg ) = @_ ;

	$self->{'echo_cnt'} = 0 ;

	$self->{'start_time'} = gettimeofday() ;

	$self->{'go_from_addr'} = $msg->from() ;

	$self->send_load_msg() ;

	return "Load Started\n" ;
}

sub response_in {

	my( $self, $msg ) = @_ ;

	my $time_delta = gettimeofday() - $self->{'start_time'} ;

	if ( ++$self->{'echo_cnt'} >= $self->{'max_msg_cnt'} ||
	     $time_delta > $self->{'max_duration'} ) {

		my $msgs_per_second = $self->{'echo_cnt'} / $time_delta ;

		my $done_msg = Stem::Msg->new(
			'to'	=> $self->{'go_from_addr'},
			'from'	=> $self->{'reg_name'},
			'type'	=> 'response',
			'data'	=> <<DATA,
sent $self->{'echo_cnt'} messages in $time_delta seconds
$msgs_per_second messages per second
DATA
		) ;

		$done_msg->dispatch() ;

		return ;
	}

	$self->send_load_msg() ;

	return ;
}


sub send_load_msg {

	my( $self ) = @_ ;

	$self->{'echo_msg'} ||= Stem::Msg->new(
			'to'	=> $self->{'load_addr'},
			'from'	=> $self->{'reg_name'},
			'type'	=> 'echo',
			'data'	=> \'echo me',
	) ;

	$self->{'echo_msg'}->dispatch() ;

	return ;
}

1 ;
