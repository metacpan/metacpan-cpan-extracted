package POE::Component::Server::PreforkTCP;


#sub POE::Kernel::TRACE_EVENTS { 1 }

use strict;

use vars qw($VERSION);
$VERSION = 0.11;

use POE;
use POE::Session;
use POE::Wheel::Run;
use POE::Component::Server::TCP;
use Carp;

sub DEBUG { 0 }

##################################################################
#
# Master Server Section
#
##################################################################

sub _preforkConfig
{
	my $params = shift;

	$params->{Alias} = 'prefork_server'
		unless exists $params->{Alias};

	my $heap = {
		server_alias => $params->{Alias},
		};

	$heap->{master_alias} = delete $params->{MasterAlias} 
				|| 'prefork_master';

	$heap->{max_server} = delete $params->{MaxServer}
				|| 20;

	$heap->{start_server} = delete $params->{StartServer}
				|| 5;

	$heap->{min_server} = delete $params->{MinServer}
				|| $heap->{start_server} ;

	$heap->{min_spare_server} = delete $params->{MinSpareServer}
				|| $heap->{min_server};

	$heap->{max_spare_server} = delete $params->{MaxSpareServer}
				|| ($heap->{max_server} - $heap->{min_server});

	$heap->{master_heartbeat_time} = delete $params->{MasterHeartBeatTime}
				|| 10;

	$heap->{server_heartbeat_time} = delete $params->{ServerHeartBeatTime}
				|| $heap->{master_heartbeat_time} / 2 ;

	$heap->{max_session} = delete $params->{MaxSessionPerServer}
				|| 0;

	$heap->{max_expire_time} = delete $params->{MaxServerExpireTime}
				|| $heap->{master_heartbeat_time} * 5;

	$heap->{grace_expire_time} = delete $params->{GraceExpireTime}
				|| $heap->{max_expire_time} ;

	$heap->{max_spare_time} = delete $params->{MaxServerSpareTime}
				|| 0;

#	$heap->{max_free_time} = delete $params->{MaxServerFreeTime}
#				|| 0;

	$heap->{max_life_time} = delete $params->{MaxServerLifeTime}
				|| 0;

	$heap->{max_life_times} = delete $params->{MaxServerLifeTimes}
				|| 0;

	$heap->{shutdown_children} = delete $params->{ShutdownChildren}
				|| 0;
	DEBUG || 
		return $heap;

	print "HEAP PARAMS \n";
	foreach ( keys %$heap ) {
		print "\t $_ => $heap->{$_} \n";
	}

	$heap;
}

sub _preforkHandler
{
	my $params = shift;
	my $master_alias = shift;

	my $old_error_handler = delete $params->{Error} 
			|| sub { 
				delete $_[HEAP]->{listener}; 

				# here is the default Compoent::Server::TCP
				# error handler, it will be call in server
				# session when error happened to shutdown server
			};

	$params->{Error} = sub {
		my ( $heap, $kernel, $scmd ) = @_[HEAP, KERNEL, ARG3];

		if ( $scmd eq 'pause' ) {
			my $accept_socket = $heap->{listener}->[ 
				POE::Wheel::SocketFactory::MY_SOCKET_HANDLE() 
				] ;
			$kernel->select_pause_read ( $accept_socket );
			#$kernel->select_pause_write ( $accept_socket );
			return 1;
		}
		elsif ( $scmd eq 'resume' ) {
			my $accept_socket = $heap->{listener}->[ 
				POE::Wheel::SocketFactory::MY_SOCKET_HANDLE() 
				] ;
			$kernel->select_resume_read ( $accept_socket );
			#$kernel->select_resume_write ( $accept_socket );
			return 1;
		}
		$old_error_handler->(@_);

		# since POE::Component::Server::TCP just handle few
		# event for accept SocketFactory Wheel,
		# (one is error, another is accept)
		
		# but i need one event handler to setup
		# the accept socket's option, to pause/resume it.
		# of course the best way is : change the
		# source of POE::Coponent::Server::TCP to
		# add other handlers for "pause" and "resume"
		# but i don't want to do like this.
		# since the Server::TCP is not included in the package.
		# and i think the ::TCP need not "resume"/"pause".

		# another way is rewrite the code about tcp servers
		# but i don't like to do same work
		# since the Server::TCP has done it.

		# so i just do a wrapper for error_handler
		# to do the resume/pause work, before the
		# Server::TCP can do it.

		# today i read the reply in perl.poe groups,
		# i found Rocco has add pause_accept and resume_accept
		# for SocketFacotory. 
		# next revision i will check the SocketFactory's Version
		# and use the two functions , not access the 
		# SocketFactory's internel data struct, too.

		};

	my $old_connected_handler = delete $params->{ClientConnected}
			|| sub { };

	$params->{ClientConnected} = sub {
			my ( $heap, $kernel, $session) 
					= @_[HEAP,KERNEL,SESSION];

			$kernel->post( $master_alias, 'client_manage',
				'connected', 
				$session->ID(),
				$heap->{remote_ip}, 
				$heap->{remote_port},
				);
			$old_connected_handler->(@_);
		};

	my $old_disconnected_handler = delete $params->{ClientDisconnected}
			|| sub { };

	$params->{ClientDisconnected} = sub {
			my ( $heap, $kernel, $session) 
					= @_[HEAP,KERNEL,SESSION];

			$kernel->post( $master_alias, 'client_manage',
				'disconnected', 
				$session->ID(),
				$heap->{remote_ip}, 
				$heap->{remote_port},
				);
			$old_disconnected_handler->(@_);
		};
}

sub _preforkMaster
{
	my ( $params, $newheap ) = @_;

	create POE::Session (
		inline_states => {
			_start => \&master_start,
			_stop => \&master_stop,
			
			born => \&born_server,
			term => \&term_server,
			kill => \&kill_server,

			heartbeat => \&master_heartbeat,
			
			pause => \&accept_pause,
			resume => \&accept_resume,

			child_stdout => \&master_child_out,
			signal =>\&master_signal,

# child_close and child_error to handle the child exit.
# the work have done in singal event, too, so the two event
# is useless. 

			child_close => \&master_child_close,
			child_error => \&master_child_error,

		},
		heap => $newheap,
	);
}

sub master_stop
{
	my ($heap, $kernel) = @_[HEAP,KERNEL];

	# here , cancel heartbeat event, make the session close.
	$kernel->state( 'heartbeat' );

	if (  $heap->{shutdown_children} == 0 ) {
		return ;
	}

	# maybe the function is useless,
	# now, the event can be used to kill
	# all children server and master server,
	# just post "_stop" to the "prefork_master".

	# since children will be recieved SIGPIPE and exit
	# ?? i don't get the result i guess
	# if user INT the master process,
	# child don't get sigPIPE, why?
	
	my $children= $heap->{children};
	foreach my $pid ( keys %$children ) {
#		$kernel->yield('kill', $pid );
		kill KILL => $pid;
		delete $heap->{children}->{$pid};
		delete $heap->{'child_' . $pid};
	}

	delete $heap->{children};

	$kernel->post( $heap->{server_alias}, 'shutdown' );
}

sub master_signal
{
	my ( $heap, $kernel) = @_[HEAP, KERNEL] ;
	my ( $signal, $pid, $status )= @_[ARG0, ARG1, ARG2];

	if ( $signal eq 'CHLD' ) {
		DEBUG && print  "child $pid singal $signal\n" ;
		$kernel->yield('kill', $pid );
	}
}

sub master_child_error
{
	my ( $heap, $kernel, $wheel_id ) = @_[HEAP, KERNEL, ARG3 ];
	
	return ;
	
# the child's exit can be handler better by signal (CHLD),
# so the function can be skip

	my $children= $heap->{children};
	foreach my $pid ( keys %$children ) {
		if ( $children->{$pid}->ID() == $wheel_id ) {
			$kernel->yield( 'kill', $pid );
			return ;
		}
	}	
}

sub master_child_close
{
	my ( $heap, $kernel, $wheel_id ) = @_[HEAP, KERNEL, ARG3 ];
	
	return ;

# the child's exit can be handler better by signal (CHLD),
# so the function can be skip

	my $children= $heap->{children};
	foreach my $pid ( keys %$children ) {
		if ( $children->{$pid}->ID() == $wheel_id ) {
			$kernel->yield( 'kill', $pid );
			return ;
		}
	}	
}

sub accept_pause
{
	$_[KERNEL]->call( 
				$_[HEAP]->{server_alias} , 
				'tcp_server_got_error',
				undef, undef, undef,
				'pause' );
}

sub accept_resume
{
	$_[KERNEL]->call( 
				$_[HEAP]->{server_alias} , 
				'tcp_server_got_error',
				undef, undef, undef,
				'resume' );
}

sub term_server
{
	my ( $heap, $pid ) = @_[HEAP, ARG0];
	return unless ( defined $pid );
	
	# here it is a way to tell child by signal
	# maybe use POE::Wheel::Run's put is better, 
	# but a little complex...

	kill INT => $pid ; 

	# the children has handled the INT singal,
	# so the kill don't term the child ,
	# then the child will exit gracefully.
	
	DEBUG 
		&& print "term: close the server $pid \n";

	# set the graceful exit timestamp, which is used
	# to term the child if it can not exit gracefully.

	my $pheap = $heap->{'child_' . $pid};
	unless ( defined $pheap->{grace_exit} ) {
		$pheap->{grace_exit} = time();
	}
}

sub kill_server
{
	my ( $heap, $pid ) = @_[HEAP, ARG0];
	return unless ( defined $pid );
	
	# here it is a way to tell child by signal
	# maybe use POE::Wheel::Run's put is better, but a little complex...
	DEBUG 
		&& print "kill: close the server $pid \n";

	# clean the relative data of the child .

	if ( ! delete $heap->{children}->{$pid} 
		&& ! delete $heap->{'child_' . $pid } ) {
			DEBUG &&
				print "kill, $pid maybe have killed\n";
			return ;
	}

	unless ( kill ( KILL => $pid ) ) {
			DEBUG && print "server has closed!\n";
	}
	# send the KILL signal.
}

sub born_server
{
	my ( $heap , $kernel ) = @_[HEAP,KERNEL];
	
	my $child = new POE::Wheel::Run (
				Program => sub {
						server_main( $heap, $kernel );
						},
				StdoutEvent => 'child_stdout',
				CloseEvent => 'child_close',
				ErrorEvent => 'child_error',
			);
	DEBUG 
		&& print "born the server ", 
				$child->PID(), " " , 
				$child->ID(), "\n";

	# set the relative data of the child.
	$heap->{children}->{$child->PID()} = $child;
	$heap->{'child_' . $child->PID() } = {starttime => time()};
}

sub master_start
{
	my ( $heap, $kernel, $session) = @_[HEAP, KERNEL, SESSION] ;

	$heap->{children} = {};

	my $master_alias = $heap->{master_alias} 
				|| 'prefork_master' ;
	$kernel->alias_set( $master_alias );

	DEBUG &&
		print "Try start " , $heap->{start_server} , " child \n";

	$kernel->call( $master_alias, 'pause' );
				
	for( my $i = 0 ; $i < $heap->{start_server} ; $i ++ ) {
		$kernel->call( $master_alias, 'born' );
	}

	$kernel->sig('CHLD', 'signal' );

	$heap->{heartbeat_count} = 0;
	$kernel->delay( 'heartbeat', $heap->{master_heartbeat_time} );
}

sub master_child_out
{
	my ($out, $heap) = @_[ARG0, HEAP];

	my ( $wheelid, $pid, $type, $param ) = split(/\s+/, $out );
	# the format of children's out put.

	DEBUG &&
		print "CHILD : $out\n";

	my $pheap = $heap->{'child_' . $pid} 
		or return ;

	if ( $type eq 'heartbeat' ) {
		$pheap->{child_heartbeat} = time;
		$pheap->{child_heartbeat_tick} = $heap->{heartbeat_count};
	}
	elsif ( $type eq 'connected' ) {
		$pheap->{connection} ++ ;
		$pheap->{connection_num} ++ ;
		$pheap->{connection_active} = time;
		if ( $heap->{max_session} > 0 
			&& $pheap->{connection} >= $heap->{max_session} 
			&& ! exists $pheap->{accept_pause} ) {
				DEBUG &&
					print "try pause $pid \n";
				$pheap->{accept_pause} = 1;
				kill USR1 => $pid;
				# send USR1 is means pause,
				# here is the hardcode, if the user
				# can configure which signal to use ?

				# and , here pause the child may not
				# as quickly as the client request,
				# so maybe there is someone can send
				# accept request after the child connected
				# but before the master process the
				# connection event.
		}
	}
	elsif ( $type eq 'disconnected' ) {
		$pheap->{connection} -- ;
		$pheap->{connection_active} = time;
		if ( $heap->{max_session} > 0 
			&& $pheap->{connection} < $heap->{max_session} 
			&& exists $pheap->{accept_pause} ) {
				DEBUG &&
					print "try resume $pid \n";
				delete $pheap->{accept_pause} ;
				kill USR2 => $pid;
				# look above about "pause"
				# to see discusss about signal and connection.
		}
	}
	elsif ( $type eq 'grace_exit' ) {
		$pheap->{grace_exit} = time;
	}
}

sub _check_expire_children
{
	my ($heap, $kernel) = @_;

	my $children = $heap->{children};
	my $server_count = 0;
	my $spare_server_count = 0;
	
	foreach my $pid ( keys %$children ) {
		my $pheap = $heap->{'child_' . $pid} ;

		# something is wrong about server pid?
		unless( defined $pheap ) {
			$kernel->yield('kill', $pid );
			next;

			# if it can kill other process unfortunatly?
		}

		if ( defined $pheap->{grace_exit} 
			&& time() - $pheap->{grace_exit} > $heap->{grace_expire_time} ) {
			$kernel->yield('kill', $pid );
			next;

			# kill the server which exit gracefully.
			# if the heartbeat cycle is too long and
			# system is too busy, if the system will
			# spawn some other process which pid is it?
			# maybe , maybe few, but not none.
		}
		
		$kernel->yield('term', $pid ) 
			if (		
				# if the server has run too long time?
			 	(
				 $heap->{max_life_time} > 0
				&& ( time() - $pheap->{starttime} > $heap->{max_life_time} )
#				&& print "term life \n"
				)
			||
				# if the server has accept too many connection? 
				(
				 $heap->{max_life_times} > 0 
				&& ($pheap->{connection_num} > $heap->{max_life_times} )
#				&& print "term life times \n"
				)
			||
				# if the server has some time without heartbeat?
				( 
				 $heap->{max_expire_time} > 0
				&& ( time() - $pheap->{child_heartbeat} > $heap->{max_expire_time} )
#				&& print "term expire ", $heap->{max_expire_time} , " ", $pheap->{child_heartbeat}," \n"
				)
			|| 
				# if the server has heartbeat but has some time not to do anything?
				( 
				 $heap->{max_spare_time} > 0
				&& ( time() - $pheap->{connection_active} > $heap->{max_spare_time} )
#				&& print "term spare \n"
				)
			) ;
		
		$server_count ++ ;
		$spare_server_count ++ 
			if ( (! exists $pheap->{connection}) || ($pheap->{connection} == 0) ) ;
	}
	return ( $server_count, $spare_server_count );
}

sub master_heartbeat
{
	my ( $session, $heap, $kernel ) = @_[SESSION, HEAP, KERNEL];

	$heap->{heartbeat_count} ++ ;
		
	my ( $server_count, $spare_server_count ) = _check_expire_children( $heap, $kernel );
	
	my $term_servers = 0;

	# check server numbers for max spare server number ..
	if ( $heap->{max_spare_server} > 0
		&& $heap->{max_spare_server} < $spare_server_count ) {
			$term_servers = $spare_server_count - $heap->{max_spare_server} ;
	}
		
	# check server numbers for max server number ..
	if ( $heap->{max_server} > 0 
		&& $heap->{max_server} < $server_count  
		&& $term_servers < $server_count - $heap->{max_server} ) {
			$term_servers = $server_count - $heap->{max_server} ;
	}
		
	if ( $term_servers > 0 ) {
		my $children = $heap->{children} ;
		foreach my $pid ( keys %$children ) {
			$kernel->yield('term', $pid );
			last if ( --$term_servers == 0 );
		}
	}

	# if there is a server termed, so don't born new one.
	if ( $term_servers == 0 ) {
		my $born_servers = 0;
	
		# check server numbers for min spare server number ..
		if ( $heap->{min_spare_server} > 0 
			&&  $heap->{min_spare_server} > $spare_server_count ) {
			$born_servers = $heap->{min_spare_server} - $spare_server_count ;
		}

		# check server numbers for min server number..
		if ( $heap->{min_server} > 0 
			&&  $heap->{min_server} > $server_count 
			&& $heap->{min_server} - $server_count > $born_servers ) {
			$born_servers = $heap->{min_server} - $server_count ;
		}
		
		for( my $i=0; $i<$born_servers; $i++ ) {
			$kernel->yield('born');
		}
	}	
# term server is check at first before born servers.
# so, the maxserver has more level than other parameter.

	$kernel->delay( 'heartbeat', $heap->{master_heartbeat_time} );
}

sub new 
{
	my ( $type, %params ) = @_;

	my $newheap = _preforkConfig( \%params );

	_preforkHandler( \%params, $newheap->{master_alias} );

	new POE::Component::Server::TCP(
		%params,
	);

	POE::Kernel->call( $newheap->{server_alias},
				'tcp_server_got_error',
				undef, undef, undef,
				'pause' 
			);

	# here to pause the server as early as possible
	# another way is pause the server when master session start
	# or after forking,
	# which is also ok but maybe a little later.
	# it will be terrible if there are some connection request
	# when child has not been forked.
	
	# if pause accept in master session, we can get
	# better interface to do pause and resume since
	# we can use the unique interface to post event 
	# to master session, not post event to Compoent::Server::TCP
	# directly. maybe it is better. 
	
	# maybe everything can be improve to rewrite Accept Handler
	# for Server::TCP. it is next step...

	my $master = _preforkMaster( \%params, $newheap );
				
	undef;
}


######################################################################
#
# child server
#
######################################################################

sub server_clean_wheel
{
	my $heap = shift;

	my $children = $heap->{children};
	my $sum = 0;
	my $count = 0;
	foreach my $key ( keys %$children ) {
		$sum ++ ;
		if ( $key == $$ ) {
			$heap->{wheel_id} = $children->{$key}->ID();
			# next ;
		}
		
#		next if ( $key == $$ );
# remove all children and relative wheel

		delete $children->{$key};
		delete $heap->{'child_'. $key };
		$count ++;
	
		# here i think it is very important to remove these wheel,
		# since i use many poe::wheel::run in same program,
		# it is means the process do many times fork(),
		# so there are any poe::wheel::run obj in the children,
		# it is useless , if these wheel exist in children,
		# a child maybe sent the out to another child,
		# not to parent process directly.

	}
	delete $heap->{children}; 
	# in fact , just the one is enough in function, 
	# but it will not clean heap.

#	my $master_alias = $heap->{master_alias} || 'prefork_master' ;
#	my $session = $kernel->alias_resolv( $master_alias );
#	undef $session;

	# in fact, i want to release the master session 
	# and create the new server session
	# in child server, but failed, so it means
	# i need study POE more.
	# so i have to clean the event the master own
	# and add new event state the server want ...

	DEBUG &&
		print "release $count wheel in $sum \n";
}

sub server_main
{
	my ( $heap, $kernel ) = @_;

	DEBUG &&
		print "Sub process $$ start ...\n";

	server_clean_wheel( $heap );

	# some state of master server is useful, such as resume and pause.	
	$kernel->call( $heap->{master_alias} ,'resume' ); 

#	$kernel->delay( 'resume', 10 ); 
# 	use delay can test if the resume is useful, when delay resume,
# 	any connected request will wait the server resume after 10 second,
# 	not refused.
	
	# clean some useless event state
	foreach my $event ( qw(signal born term kill child_close child_error)){
		$kernel->state( $event );
	}
	
	my $states = {
			heartbeat => \&server_heartbeat,
			shutdown => \&server_shutdown,
			server_signal => \&server_signal,
			client_manage => \&server_manage,
		};
	foreach my $event ( keys %$states ) {
		$kernel->state( $event, $states->{$event} );
	}

	# release CHLD signal handler.	
	$kernel->sig ( 'CHLD' );
	
	foreach my $signal ( qw(PIPE USR1 USR2 INT) ) {
		$kernel->sig( $signal, 'server_signal' );
	}

	$kernel->yield( 'heartbeat' );

	$kernel->run();

	exit 0;
}

sub server_signal
{
	my ( $heap, $kernel) = @_[HEAP, KERNEL] ;
	my ( $signal )= @_[ARG0];

	DEBUG && 
		print  "$$ singal $signal recieved\n" ;

	if ( $signal eq 'USR1' ) {
		$kernel->post( $heap->{master_alias}, 'pause');
	}
	elsif ( $signal eq 'USR2' ) {
		$kernel->post( $heap->{master_alias}, 'resume');
	}
	elsif ( $signal eq 'INT' ) {
		$kernel->post( $heap->{master_alias}, 'shutdown');
	}
	elsif ( $signal eq 'PIPE' ) {
		DEBUG &&
			$heap->{client}->put( "SIGPIPE recievied\n");
		# ?? .....
		# when user INT the master perl process,
		# what signal the child server process get?

		$kernel->post( $heap->{master_alias}, 'shutdown');
	}
}

sub server_manage
{
	# when client connection and disconnection , it will post the event.
	# it is the easiest way to manage the connection number
	# and, here i just print the message to parent process (master),
	# let master to manage the connection number of the server
	
	my ( $heap, $type, $sid, $rip, $rport ) = @_[HEAP, ARG0, ARG1 , ARG2, ARG3];
	
	print $heap->{wheel_id} , " $$ $type ", time(), " $sid $rip $rport \n";	
}

sub server_shutdown
{
	my ( $heap, $kernel) = @_[HEAP, KERNEL] ;

	DEBUG 
		&& print "server $$ shutdown \n";

	$heap->{shutdown} = 1;
	$kernel->post( $heap->{server_alias} , 'shutdown' );
	
	print $heap->{wheel_id} , " $$ grace_exit ", time(), " \n";
}

sub server_heartbeat
{
	my ( $session, $heap, $kernel ) = @_[SESSION, HEAP, KERNEL];
	
	print $heap->{wheel_id} , " $$ heartbeat ", time(), " \n";
	if ( ! exists $heap->{shutdown} or $heap->{shutdown} != 1 ) {
		$kernel->delay( 'heartbeat', $heap->{server_heartbeat_time} );
	}
	# if shutdown is set, don't heartbeat, so
	# the server session will be over since no event.
}

1;
__END__

=head1 NAME

POE::Component::Server::PreforkTCP - Perl TCP server , which
can fork processes before request and each process can do with
requestion corcurrently as same as Apache.

=head1 SYNOPSIS

you can use POE::Component::Server::PreforkTCP as same as
POE::Component::Server::TCP, since they has same interface,
but ::PreforkTCP has more parameters.

	use POE;
	use POE::Component::Server::PreforkTCP;

	new POE::Component::Server::PreforkTCP(
		Port => 10000,
#		MaxServer => 100,
# 		MinServer => 10,
# 		StartServer => 10,
# 		...
#		MaxSessionPerServer => 1,
#		MaxServerLifeTime => 50,
#		ShutdownChildren => 1,
		ClientConnected => sub {
			my ( $heap , $input, $kernel) 
				= @_[HEAP, ARG0, KERNEL];
			$heap->{client}->put("test server , welcome$$ !\n");
			},
		ClientInput => sub {
			my ( $heap , $input, $kernel) 
				= @_[HEAP, ARG0, KERNEL];
			$heap->{client}->put("$$ : $input\n");
			print("$$ : $input\n");
			if ( $input eq 'quit' ) {
				$kernel->yield('shutdown');
			}
			if ( $input eq 'exit' ) {
				$kernel->yield('shutdown');
				$kernel->post($heap->{master_alias},
						'shutdown');
			}
			if ( $input eq 'kill' ) {
				exit 1;
			}
		}
	);

	POE::Kernel->run();

	exit 0;

=head1 DESCRIPTION

POE::Compoent::Server::PreforkTCP based on POE, the important
packages included: Wheel::SocketFactory, Wheel::Run,
Component::Server::TCP... etc.

	* in fact, the Component::Server::TCP is simple and easy to use,
	so i keep same interface in ::PreforkTCP to ::TCP.

when a Component::Server::PreforkTCP started, it will create many 
the children process before any request is coming, it is called prefork
and used in Apache 1 and Apache 2.

The basic process, or parent prcess, named master process , don't accept 
the connect request from client, the children to do the work.
Master process is used to manage its children, to born, term, check
if the child is expired ... etc.

Apache 1 just serve the connection by prefork,  one child process 
serve one client in same time, Apache 2 can serve many client in
one child process by creating new thread. The ::PreforkTCP can
serve many client in one child in same time, too, but it needn't
thread, the POE assign its power.

The ::PreforkTCP depend the package POE::Wheel::Run to spawn the 
child, use the package, not use fork directly, since the package
can simple the code to commnicate between children and parent 
process, ::Wheel::Run use pipe to do it, the STDOUT of children
is redirectly to parent's ::Wheel::Run obj as event arrived.

In ::PreforkTCP , the master process just recieve the
children's out, and don't sent data by children's stdin, 
some simple instructor is sent to children by signal, 
USR1 to pause the server's accept, USR2 to 
resume the server 's accept, INT to shutdown the server.

The ::PreforkTCP support many parameters when create,
they can decide how many server born, how many spare server, 
how long the child server life...these idea coming form apache...

Constructor parameters:

=over 2

=item MasterAlias

MasterAlias is the master session's alias, so you can use 
$heap->{master_alias} to post the event to master server,
it default name is 'prefork_master'.


=item MaxServer

MaxServer is the maxium number the master to spawn the children
process, you can access it in $heap->{max_server} and change
it in master server. to change it in children process is useless.
it default value is 20.

=item StartServer

StartServer decide how many children when Prefork create.
default it is  5;

=item MinServer

MinServer decide the minium numbers of the children process,
if the children is less than it, master server will be born
now children. its default value is same as StartServer.

=item MinSpareServer

MinSpareServer decide minium numbers of the spare children
process ( no connection ). its default value is same as
MinServer.

=item MaxSpareServer

MaxSpareServer is max spare children. its default value
is MaxServer - MinServer.

NOTE: the MaxServer and MaxSpareServer is checked before
MinServer and MinSpareServer.

=item MasterHeartBeatTime

MasterHeartBeatTime is how long the master check children's
status, include children numbers, if some children has died
but not cleaned...

its default value is 10 seconds, do not set its value to 0,
it will occupy too much system resource.

=item ServerHeartBeatTime

ServerHeartBeatTime is how long the children server check
its own status and report to master.

it should be faster tan MasterHeartBeatTime, its default value
is half of MasterHeartBeatTime.

=item  MaxSessionPerServer

MaxSessionPerServer is how many connection the children can 
accept, default is 0, means no limition. the children can
accept the request as many as it can process.

in fact , the value is not very accurency, since when a limition
is do in master process, so it is possible before the master
send the USR1 signal to children to pause its acception, the
children has accepted another connection. if the user really think
it is not good, you can use ClientConnected and ClientDisconnected
function to do pause and resume in children process, it is different.

it is useful there are many sync/block operater in server process,
make less session the children can acception, the client will not
be blocked.

even in pure POE program, the parameter can be used to
limition one process's resource.

if set the value is small, you should set the bigger MaxServer for
heavy server.

=item MaxServerExpireTime

MaxServerExpireTime is how long the children should be killed if
master don't get children's heartbeat.

its default value is 5 * MasterHeartBeatTime, if the server need
do with work with blocked i/, such as sync DNS request, you need 
give it a bigger value .

=item GraceExpireTime

if a child said it will exit but not exit really, how long the
master should kill it.

its default value is MaxServerExpireTime.

=item MaxServerSpareTime

MaxServerSpareTime is how long the master should term a child if
it don't accept connection in MaxServerSpareTime seconds.

it is useful if some server is blocked and can not work.
but it is terrible if the server is not heavy , not too many
request. so its defalut value is 0, means don't check the parameter.
if you want to set the parameter, don't set it too small.

=item MaxServerLifeTime

MaxServerLifeTime is how long a child will be run, the master
will be term it when children run too long time, maybe it is useful
some server will occupy much memory in less connection, but perl
will not release it, just keep the memory for furture used, but
next time, maybe another children need many memory, not the one.
so long long time , all children occupied many memory, maybe
just one of it really need it.

its default value is 0, means don't check it.

=item MaxServerLifeTimes

MaxServerLifeTimes is how many connection a child can process,
the master will term it after the child do the works.
its goal is same as MaxServerLifeTime.

its default value is 0, means don't check it.

=item ShutdownChildren

the parameter is used to kill children when master exit.
now the parameter can not run as same as i think, 
i just use it in "make test", it decided if another session can
terminal the master's children.

its default value is 0, means don't kill children.


=item others

you can use all Component::Server::TCP's parameter to make a server work.
such as, ClientInput, ClientConnected ...

NOTE::
if you use Acceptor to define yourself acceptor, maybe the prefork Server
will not work correctly. since i haven't test it by a given Acceptor.


=back

=head1 EVENTS

PreforkTCP server support some EVENTS.

=item shutdown

use shutdown to shutdown the connection or server as same as Server::TCP,
but you should post the event to master session, and it just shutdown
one children , not all server.

	$kernel->post( $heap->{master_alias}, 'shutdown');
	
maybe it need a new event, it can shutdown all servers and master. but now
no.

=item pause/resume 

pause and resume be used to pause and resume the server's accept socket.
it is master session's event in master server and children server.
master server is of course is paused, don't make it accept and process
connection.

=item heartbeat/client_manage/server_signal

don't use these event directly.

=item some events in master server

maybe it is useful from outside , maybe not.

back

=head2 EXPORT

None.


=head1 AUTHOR

Wang Bo <lt>wb@95700.net<gt>

=head1 SEE ALSO

L<perl>.L<POE>.L<POE::Component::Server::TCP>.

=cut



