

package Stem::Load::Ticker ;

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
		'name'		=> 'dbi_addr',
		'help'		=> <<HELP,
Address to send the insert messages
HELP
	},
	{
		'name'		=> 'max_cnt',
		'default'	=> 20,
		'help'		=> <<HELP,
Maximum number of rows to insert
HELP
	},
	{
		'name'		=> 'parallel_cnt',
		'default'	=> 1,
		'help'		=> <<HELP,
Number of inserts to do in parallel
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

	my %go_args ;

	if ( my $data = $msg->data() ) {

		%go_args = ${$data} =~ /(\S+)=(\S+)/g if $$data ;
	}

	$self->{'start_time'} = gettimeofday() ;
	$self->{'go_from_addr'} = $msg->from() ;
	$self->{'go_max_cnt'} = $go_args{'max_cnt'} || $self->{'max_cnt'} ;

	$self->{'inserted_cnt'} = 0 ;
	$self->{'send_cnt'} = $self->{'go_max_cnt'} ;
	$self->{'parallel_cnt'} = $go_args{'para_cnt'} if $go_args{'para_cnt'} ;

	$self->send_ticker_msgs( $self->{'parallel_cnt'} ) ;

	return "Ticker Started\n" ;
}

sub send_ticker_msgs {

	my( $self, $parallel_cnt ) = @_ ;

#print "PARA $parallel_cnt\n" ;

	while ( $parallel_cnt-- ) {

		$self->insert_ticker_row() ;
	}

	return ;
}

sub insert_ticker_row {

	my( $self ) = @_ ;

	return if $self->{'send_cnt'} <= 0 ;
	$self->{'send_cnt'}-- ;

	my $ticker = join '', map ['A' .. 'Z']->[rand 26], 1 .. 3 ;

	my $price = 100 + int rand 9900 ;

	my $delta = -1000 + int rand 2000 ;

	my $dbi_msg = Stem::Msg->new(

		'to'		=> $self->{'dbi_addr'},
		'from'		=> $self->{'reg_name'},
		'type'		=> 'cmd',
		'cmd'		=> 'execute',
		'reply_type'	=> 'insert_done',
		'data'		=> {
			statement	=> 'insert_tick',
			bind		=> [ $ticker, $price, $delta ],
		},
	);

#print $dbi_msg->dump( 'SEND' ) ;
	$dbi_msg->dispatch() ;

	return ;
}

sub insert_done_in {

	my( $self, $msg ) = @_ ;

#print $msg->dump( 'DONE' ) ;

	if ( $self->{'send_cnt'} ) {

		$self->send_ticker_msgs( 1 ) ;
	}

	if ( ++$self->{'inserted_cnt'} >= $self->{'go_max_cnt'} ) {

		my $data = $msg->data() ;

		die "insert_done_in: $$data" unless ref $data eq 'HASH' ;

		my $time_delta = sprintf( "%8.4f",
				     gettimeofday() - $self->{'start_time'} ) ;

		my $rows_per_second = $self->{'inserted_cnt'} / $time_delta ;

		my $done_msg = Stem::Msg->new(
			'to'	=> $self->{'go_from_addr'},
			'from'	=> $self->{'reg_name'},
			'type'	=> 'response',
			'data'	=> <<DATA,
inserted $self->{'inserted_cnt'} rows in $time_delta seconds
$rows_per_second rows per second
with $self->{'parallel_cnt'} inserts in parallel
last row ID $data->{'insert_id'}
DATA
		) ;

		$done_msg->dispatch() ;

		return ;
	}


	return ;
}

1 ;
