package Net::Server::NonBlocking;

use 5.000503;

use strict;
use warnings;
use POSIX;
use IO::Socket;
use IO::Select;
use Socket;
use Fcntl;
use Tie::RefHash;
use vars qw($VERSION);
use Data::Dumper;

$VERSION = '0.048';

my @now=localtime(time);
my $cronCounter=$now[0]+60*$now[1]+3600*$now[2]+3600*24*$now[3];
my %buff;

# begin with empty buffers
my %inbuffer  = ();
my %outbuffer = ();
my %ready = ();

my %turn_timeout;
my %turn_timeout_trigger;
my $select = IO::Select->new();
my %idle;
my %timer;
my %map_all;
my %map_specific;
my %map_server;
my %map_client;
my %alive;

tie %ready, 'Tie::RefHash';

sub new{
    my($proto,@arg)=@_;
    my $class=ref($proto) || $proto;
    my $hash=$arg[0];

    my $self={};
    $self->{pidfile}=exists $hash->{pidfile} ? $hash->{pidfile} : '/tmp/anonymous_server';

    bless $self,$class;
}

sub add {
    my $self=shift;
    my $hash=shift;

    die("server_name is required") if not exists $hash->{server_name};
    
    if (not exists $hash->{local_port}) {
	$self->{listen}->{$hash->{server_name}}->{delimiter}=
	    exists $hash->{delimiter} ? $hash->{delimiter} : "\0";
	$self->{listen}->{$hash->{server_name}}->{string_format}=
	    exists $hash->{string_format} ? $hash->{string_format} : '.*?';
	$self->{listen}->{$hash->{server_name}}->{timeout}=
	    exists $hash->{timeout} ? $hash->{timeout} : 300;
	$self->{listen}->{$hash->{server_name}}->{on_disconnected}=
	    exists $hash->{on_disconnected} ? $hash->{on_disconnected} : sub {};
	$self->{listen}->{$hash->{server_name}}->{on_recv_msg}=
	    exists $hash->{on_recv_msg} ? $hash->{on_recv_msg} : sub {};
	$self->{listen}->{$hash->{server_name}}->{read_buffer} = 
	    exists $hash->{read_buffer} ? $hash->{read_buffer} : \&read_buffer;
	$self->{listen}->{$hash->{server_name}}->{on_disconnected_param}=
	    exists $hash->{on_disconnected_param} ? $hash->{on_disconnected_param} : [];
	$self->{listen}->{$hash->{server_name}}->{on_recv_msg_param}=
	    exists $hash->{on_recv_msg_param} ? $hash->{on_recv_msg_param} : [];

	return undef;
    } else {
	my $server;

	if (exists $hash->{local_address}) {
	    $server = IO::Socket::INET->new(
					    LocalAddr => $hash->{local_address},
					    LocalPort => $hash->{local_port},
					    Listen    => 50,
					    Proto	=> 'tcp',
					    Reuse	=> 1,
					    Blocking => 0)
		or die "Can't make server socket -- $@\n";
	} else {
	    $server = IO::Socket::INET->new(
					    LocalPort => $hash->{local_port},
					    Listen    => 50,
					    Proto	=> 'tcp',
					    Reuse	=> 1,
					    Blocking => 0)
		or die "Can't make server socket -- $@\n";
	}
	$self->nonblock($server);

	$self->{listen}->{$hash->{server_name}}->{socket}=$server;
	$self->{listen}->{$hash->{server_name}}->{local_address}=$hash->{local_address} || "localhost";
	$self->{listen}->{$hash->{server_name}}->{local_port}=$hash->{local_port};
	$self->{listen}->{$hash->{server_name}}->{delimiter}=
	    exists $hash->{delimiter} ? $hash->{delimiter} : "\0";
	$self->{listen}->{$hash->{server_name}}->{string_format}=
	    exists $hash->{string_format} ? $hash->{string_format} : '.*?';
	$self->{listen}->{$hash->{server_name}}->{timeout}=
	    exists $hash->{timeout} ? $hash->{timeout} : 300;
	$self->{listen}->{$hash->{server_name}}->{on_connected}=
	    exists $hash->{on_connected} ? $hash->{on_connected} : sub {};
	$self->{listen}->{$hash->{server_name}}->{on_disconnected}=
	    exists $hash->{on_disconnected} ? $hash->{on_disconnected} : sub {};
	$self->{listen}->{$hash->{server_name}}->{on_recv_msg}=
	    exists $hash->{on_recv_msg} ? $hash->{on_recv_msg} : sub {};
	$self->{listen}->{$hash->{server_name}}->{read_buffer} = 
	    exists $hash->{read_buffer} ? $hash->{read_buffer} : \&read_buffer;
	$self->{listen}->{$hash->{server_name}}->{on_connected_param}=
	    exists $hash->{on_connected_param} ? $hash->{on_connected_param} : [];
	$self->{listen}->{$hash->{server_name}}->{on_disconnected_param}=
	    exists $hash->{on_disconnected_param} ? $hash->{on_disconnected_param} : [];
	$self->{listen}->{$hash->{server_name}}->{on_recv_msg_param}=
	    exists $hash->{on_recv_msg_param} ? $hash->{on_recv_msg_param} : [];

	if (exists $hash->{local_address}) {
	    $map_specific{"$hash->{local_address}:$hash->{local_port}"}=
		$hash->{server_name};
	} else {
	    $map_all{$hash->{local_port}}=
		$hash->{server_name};
	}

	$map_server{$server} = $hash->{server_name};

	return $server;
    }
}

sub bind {
    my $self=shift;
    my $server_name=shift;
    my $client=shift;

    $select->add($client);
    $self->nonblock($client);

    $alive{$client}=1;
    $idle{$client}=time;
    $turn_timeout{$client}=-1;

    $map_client{$client}=$server_name;
}

sub nonblock {
    my $self=shift;
    my $socket=shift;
    my $flags;

    $flags = fcntl($socket, F_GETFL, 0)
	or die "Can't get flags for socket: $!\n";
    fcntl($socket, F_SETFL, $flags | O_NONBLOCK)
	or die "Can't make socket nonblocking: $!\n";
}

sub handle {
    my $self=shift;
    my $server_name=shift;
    my $client = shift;
    my $request;

    # requests are in $ready{$client}
    # send output to $outbuffer{$client}

    foreach $request (@{$ready{$client}}) {
	# $request is the text of the request
	# put text of reply into $outbuffer{$client}

	$self->{listen}->{$server_name}->{on_recv_msg}->($self,$client,$request,@{$self->{listen}->{$server_name}->{on_recv_msg_param}});
    }

    delete $ready{$client};
}

sub get_server_socket {
    my $self=shift;
    my $server_name = shift;

    $self->{listen}->{$server_name}->{socket};
}

sub get_server_name {
    my $self=shift;
    my $client=shift;
    #my @caller=caller();

    return $map_server{$client} if exists $map_server{$client};
    return $map_client{$client} if exists $map_client{$client};
    
    if (exists $map_specific{$client->sockhost().":".$client->sockport()}) {
        return $map_specific{$client->sockhost().":".$client->sockport()};
    } else {
        return $map_all{$client->sockport()};
    }
}

sub start_turn {
    my $self=shift;
    my $client=shift;
    my $time=shift;

    $turn_timeout{$client}=$time;
    $turn_timeout_trigger{$client}=$_[0];
}

sub reset_turn {
    my $self=shift;
    my $client=shift;

    $turn_timeout{$client}=-1;
    delete($turn_timeout_trigger{$client});
}

#sub flush_input {
#    my $self=shift;
#    my $client=shift;
#    my $server_name=$self->get_server_name($client);
#
#    my $rin='';
#    vec($rin,fileno($client),1)=1;
#
#    select(my $rout=$rin,undef,undef,0);
#
#    if (vec($rout,fileno($client),1)) {
#	my $data = '';
#	my $rv = $client->recv($data, POSIX::BUFSIZ, 0);
#		
#	unless (defined($rv) && length $data) {
#	    # This would be the end of file, so close the client
#	    $self->erase_client($server_name,$client);
#	    next;
#	}
#
#	$inbuffer{$client} .= $data;
#	$self->{listen}->{$server_name}->{read_buffer}->($self,\$inbuffer{$client},\$ready{$client},$server_name);
#
#	$idle{$client}=time;
#    }
#
#    $self->handle($server_name,$client);
#}

sub flush_output {
    my $self=shift;
    my $client=shift;
    my $server_name=$self->get_server_name($client);

    return unless length $outbuffer{$client}; 

    my $rin='';
    vec($rin,fileno($client),1)=1;

    select(undef,my $rout=$rin,undef,0);

    if (vec($rout,fileno($client),1)) {
	while ($outbuffer{$client}) {
	    my $rv;

	    eval{
		$rv = $client->send($outbuffer{$client}, 0);
	    };
	    return if $@;   #the $client is disconnected

	    unless (defined $rv) {
		# Whine, but move on.
		
		warn "I was told I could write, but I can't.\n";
		next;
	    }

	    if ( $rv == length $outbuffer{$client}  || $! == POSIX::EWOULDBLOCK) {
		substr($outbuffer{$client}, 0, $rv) = '';
		delete $outbuffer{$client} unless length $outbuffer{$client};
	    } else {
		# Couldn't write all the data

		substr($outbuffer{$client}, 0,$rv,'') if defined $rv;
		delete $outbuffer{$client} unless length $outbuffer{$client};
	    }
	}
    }
}

sub close_client {
    my $self=shift;
    my $client=shift;

    #print "Idle delete close_client $client\n";

    delete $alive{$client};
    delete $turn_timeout{$client};
    delete $turn_timeout_trigger{$client};
    delete $idle{$client};
    delete $inbuffer{$client};
    delete $outbuffer{$client};
    delete $ready{$client};
    delete $map_client{$client} if exists $map_client{$client};

    $select->remove($client);
    close $client if $client;
}

sub erase_client {
    my $self=shift;
    my $server_name=shift;
    my $client=shift;

    delete $alive{$client};
    delete $turn_timeout{$client};
    delete $turn_timeout_trigger{$client};
    delete $idle{$client};
    delete $inbuffer{$client};
    delete $outbuffer{$client};
    delete $ready{$client};
    delete $map_client{$client} if exists $map_client{$client};

    $self->{listen}->{$server_name}->{on_disconnected}->($self,$client,@{$self->{listen}->{$server_name}->{on_disconnected_param}});

    $select->remove($client);
    close $client if $client;
}

sub enqueue {
    my $self=shift;
    my $client=shift;
    my $data=shift;

    return unless $client and $data;

    $outbuffer{$client}.=$data;
}

sub read_buffer {
    my $self=shift;
    my $raw_input=shift;
    my $cooked_input=shift;
    my $server_name=shift;

    my $dm=$self->{listen}->{$server_name}->{delimiter};
    my $sf=$self->{listen}->{$server_name}->{string_format};

    while ($$raw_input =~ s/($sf)$dm//s) {
	push( @{$$cooked_input}, $1 );
    }
}

sub start{
    my $self=shift;
    my $current_time=time;

    foreach (keys %{$self->{listen}}) {
	next unless $self->{listen}->{$_}->{local_port};
	warn "Listen on ".$self->{listen}->{$_}->{local_address}.":".
	    $self->{listen}->{$_}->{local_port}."\n";
	$select->add($self->{listen}->{$_}->{socket});
    }

    open(FILE,">".$self->{pidfile}) or die "Cannot write PID file: $!\n";
    print FILE $$;
    close(FILE);

    while (1) {
	my $client;
	my $rv;
	my $data;

	# cron
	my $this_time=time;
	if ($current_time != $this_time) {
	    foreach $client($select->handles) {
		next if exists $map_server{$client};
		next unless exists $alive{$client};

		if ($turn_timeout{$client} != -1) {
		    if ($turn_timeout{$client} <= 0) {
			&{$turn_timeout_trigger{$client}}($self,$client);
			delete $turn_timeout_trigger{$client};
			$turn_timeout{$client} = -1;
		    } else {
			--$turn_timeout{$client};
		    }
		} 
	    }

	    $self->onSheddo;
	    $current_time=$this_time;
	}

	#timeout the Idles

	foreach $client ($select->handles) {
	    next if exists $map_server{$client};
	    next unless exists $alive{$client};

	    my $server_name=$self->get_server_name($client);

	    my $this_time=time;
	    if( $this_time - $idle{$client} >= $self->{listen}->{$server_name}->{timeout} ){
		$self->erase_client($server_name,$client);
		next;
	    }
	}
	# check for new information on the connections we have

	# anything to read or accept?
	foreach $client ($select->can_read(1)) {
	    if (exists $map_server{$client}) {
		my $server_name=$self->get_server_name($client);
		# accept a new connection
		$client = $self->{listen}->{$server_name}->{socket}->accept();
		unless ($client) {
		    warn "Accepting new socket error: $!\n";
		    next;
		}

		$select->add($client);
		$self->nonblock($client);

		$alive{$client}=1;
		$self->{listen}->{$server_name}->{on_connected}->($self,$client,@{$self->{listen}->{$server_name}->{on_connected_param}});
		$idle{$client}=time;
		$turn_timeout{$client}=-1;
	    } else {
		next unless exists $alive{$client};
		my $server_name=$self->get_server_name($client);
		# read data

		$data = '';
		$rv   = $client->recv($data, POSIX::BUFSIZ, 0);
		
		unless (defined($rv) && length $data) {
		    # This would be the end of file, so close the client
		    $self->erase_client($server_name,$client);
		    next;
		}

		$inbuffer{$client} .= $data;
		$self->{listen}->{$server_name}->{read_buffer}->($self,\$inbuffer{$client},\$ready{$client},$server_name);

		$idle{$client}=time;
	    }
	}

	# Any complete requests to process?
	foreach $client (keys %ready) {
	    my $server_name=$self->get_server_name($client);
	    $self->handle($server_name,$client);
	}

	my @bad_client;

	# Buffers to flush?
	foreach $client ($select->can_write(1)) {
	    next unless exists $alive{$client};

	    my $server_name=$self->get_server_name($client);
	    
	    # Skip this client if we have nothing to say
	    next unless exists $outbuffer{$client};
	    
	    eval{
		$rv = $client->send($outbuffer{$client}, 0);
	    };
	    push(@bad_client,$client),next if $@;
	    
	    unless (defined $rv) {
		# Whine, but move on.
		
		warn "I was told I could write, but I can't.\n";
		next;
	    }

	    if ( $rv == length $outbuffer{$client} || $! == POSIX::EWOULDBLOCK) {
		substr($outbuffer{$client}, 0, $rv) = '';
		delete $outbuffer{$client} unless length $outbuffer{$client};
	    } else {
		# Couldn't write all the data

		substr($outbuffer{$client}, 0,$rv,'') if defined $rv;
		delete $outbuffer{$client} unless length $outbuffer{$client};
		next;
	    }
	}

	foreach $client (@bad_client){
	    my $server_name=$self->get_server_name($client);
	    $self->erase_client($server_name,$client);
	}

	# Out of band data?
	foreach $client ($select->has_exception(0)) {
	    # arg is timeout
	    # Deal with out-of-band data here, if you want to.
	}
    }

}

sub onSheddo{
    my $self=shift;

    foreach (sort {$a <=> $b} keys %timer) {
	unless ($cronCounter % $_) {
	    my $count=@{$timer{$_}};
	    &{$timer{$_}->[0]}($self,@{$timer{$_}}[1..($count-1)]);
	}
    }

    ++$cronCounter;
}

sub cron {
    my $self=shift;
    my $sec=shift;
    my $sub=shift;

    $timer{$sec}=[$sub,@_];
}

sub select {
    my $self=shift;

    $select;
}

1;

__END__

=head1 NAME

Net::Server::NonBlocking - An object interface to non-blocking I/O server engine

=head1 VERSION

0.48

=head1 SYNOPSIS

	use Net::Server::NonBlocking;
	$|=1;

	$obj=Net::Server::NonBlocking->new();
	$obj->add({
		server_name => 'tic tac toe',
		local_port => 10000,
		timeout => 60,
		delimiter => "\n",
		on_connected => \&ttt_connected,
		on_disconnected => \&ttt_disconnected,
		on_recv_msg => \&ttt_message
	});
	$obj->add({
		server_name => 'chess',
		local_port => 10001,
		timeout => 120,
		delimiter => "\r\n",
		on_connected => \&chess_connected,
		on_disconnected => \&chess_disconnected,
		on_recv_msg => \&chess_message
	});

	$obj->start;

=head1 DESCRIPTION

You can use this module to establish non-blocking style TCP servers without being messy with the hard monotonous routine work.

This module is not state-of-the-art of non-blocking server, it consumes some additional memories and executes some extra lines to support features which can be consider wasting if you do not plan to use. However, at present, programming time is often more expensive than RAM and CPU clocks.

=head1 LIMITATION

At present, the module handles concurrency with "select"(to eschew waste polling), which limits the number of clients that it can hold(In my linux box(kernel 2.4.18-14) the number is approximately 512). There are 3 choices I'm thinking of, use poll instead, handle multiple of IO::Select objects, or leave this limititation unchange.

=head1 FEATURES

*Capable of handling multiple server in a single process

It is possible since it uses "select" to determine which server has events, then delivers them to some appropriate methods.

*Timer

You can tell the module to execute some functions every N seconds.

*Timeout

Clients that are idle(sending nothing) in server for a configurable period will be disconnected.

*Turn timeout

The meaning of this feature is hard to explain without stimulating a case. Supposing that you write a multi-player turn-based checker server, you have to limit the times that each users spend before sending their move which can easily achieve by client side clock, however, it is not secure. That's why I have to write this feature.

=head1 METHOD

=over 1

=item C<new ([$hash_ref])>

$hash_ref->{pidfile}
    location where pid will be kept default is /tmp/anonymous_server

=item C<add ($hash_ref)>

hash two mode. If $hash_ref->{localport} is given, the module will initialize a server socket binding to IO::Select object. If not the module initialize server information without creating server socket.
(See USAGE for all $hash_ref's key & value)

=item C<bind ($server_name,$user_define_socket)>

to bind a socket, which is not the client of your listening server, to the server_name.

The usage of this function is while you are processing some messages, you create a client socket to somewhere and you would like the module to handle this socket for you like server socket. For example:

$obj=Net::Server::NonBlocking->new;

$obj->add({
    server_name => 'tic tac toe',
    local_port => 10000,
    timeout => 60,
    delimiter => "\r\n",
    on_connected => \&ttt_connected,
    on_disconnected => \&ttt_disconnected,
    on_recv_msg => \&ttt_message
});

$obj->add({
    server_name => 'user socket',
    timeout => 60,
    delimiter => "\0",
    on_disconnected => \&user_disconnected,
    on_recv_msg => \&user_message
});

$obj->start;          

sub ttt_message {
    my $self=shift;
    my $client=shift;
    my $data=shift;

    if ($data eq 'connect') {
	my $sock = IO::Socket::INET->new(PeerAddr => '192.168.3.209',
				      PeerPort => '3456',
				      Proto    => 'tcp');
	$self->bind('user socket',$sock);
    }
}  

sub user_message {
    my $self=shift;
    my $client=shift;
    my $data=shift;

    $self->enqueue($client,"send something to 192.168.3.209\0");
}

sub user_disconnected {
    
}

=item C<get_server_socket ($server_name)>

return $socket of the given server_name

=item C<get_server_name ($client)>

return server_name of the given $client

=item C<start_turn($client, $second, \&code)>

start count down from $second to zero, if zero is reached the module will activate the code with $self and $client as parameters. (see usage for more information)

=item C<reset_turn($client)>

stop the count down process

=item C<flush_output($client)>

send all data in out buffer queue, this operation can be blocked, if the $client is not available for writing.

=item C<enqueue($client,$data)>

to append the out buffer of the client with $data which will be transmit to the client later in the apropriate time.

=item C<start()>

start listening all added socket server.

=item C<cron($second,$code,[@param])>

to activate the $code every $second seconds.

=item C<erase_client($server_name,$client)>

erase the $client from the responsibility of the module. It also activate on_disconnected callback and close $client socket.

=item C<close_client($server_name,$client)>

erase the $client from the responsibility of the module. It closes $client socket without activate on_disconnected callback.

=back

=head1 USAGE

Even though, the module make it easy to build a non-blocking I/O server, but I don't expect you to remeber all its usages. Here is the template to build a server:

	use Net::Server::NonBlocking;
	$SIG{PIPE}='IGNORE';
	$|=1;

	$obj=Net::Server::NonBlocking->new();
	$obj->add({
		server_name => 'tic tac toe',
		local_port => 10000,
		timeout => 60,
		delimiter => "\n",
		on_connected => \&ttt_connected,
		on_disconnected => \&ttt_disconnected,
		on_recv_msg => \&ttt_message
	});
	$obj->add({
		server_name => 'chess',
		local_port => 10001,
		timeout => 120,
		delimiter => "\r\n",
		on_connected => \&chess_connected,
		on_disconnected => \&chess_disconnected,
		on_recv_msg => \&chess_message
	});

	sub ttt_connected {
		my $self=shift;
		my $client=shift;

		print $client "welcome to tic tac toe\n";
	}
	sub ttt_disconnected {
		my $self=shift;
		my $client=shift;

		print "a client disconnects from tic tac toe\n";
	}
	sub ttt_message {
		my $self=shift;
		my $client=shift;
		my $message=shift;

		# process $message
	}

	sub chess_connected {
		my $self=shift;
		my $client=shift;

		print $client "welcome to chess server\r\n";
	}
	sub chess_disconnected {
		my $self=shift;
		my $client=shift;

		print "a client disconnects from chess server\n";
	}
	sub chess_message {
		my $self=shift;
		my $client=shift;
		my $message=shift;

		# process $message
	}

	$obj->start;

You can pass a parameter to the "new method". It is something like this:

	->new({
			pidfile => '/var/log/pidfile'
		});

However, when ignoring this parameter, the pidfile will be
	 '/tmp/anonymous_server' by default.

The "add medthod" has various parameters which means:

*Mandatory parameter

	-server_name	different text string to distinguish a server from others

	-local_port	listening port of the added server

*Optional parameter

	-local_address: If your server has to listen all addresses in its machine, you must not pass this parameter, otherwise my internal logic will screw up. This parameter should be specify when you want to listen to a specific address. For example,

		local_address => '203.230.230.114'


    (** By Default, the module assumes that your TCP protocol has "message delimiter", unless you define your own buffer fetching mechanism, provided by a callback named "read_buffer". OK, I'll mention it later.)

	-delimiter: Every sane protocol should have a or some constant characters for splitting a chunk of texts to messages. If your protocol has inconsistent delimiters, you should write your own code.

		Default is "\0"

	-string_format: By default, string format is ".*?". In the parsing process, the module executes something like this "while ($buffer =~ s/($string_format)$delimiter//) {" and throw $1 to on_recv_msg. In the case that your protocol has no "delimiter" and each message is a single character, you might have to do this:

			delimiter => '',
			string_format => '.'

	-timeout: to set timeout for idle clients, the default value is 300 or 5 minutes

	-on_connected: callback method for an incoming client, parameters passed to this callback is illustrated with this code:

		sub {
			my $self=shift;
			my $client=shift;
		}

	- on_disconnected: callback method when a client disconnects

		sub {
			my $self=shift;
			my $client=shift;
		}

	- on_recv_msg: callback method when a client sends a message to server

		sub {
			my $self=shift;
			my $client=shift;
			my $message=shift;
		}

The 'add' method creates a socket(derived from IO::Socket::INET) binding with the local_address, and local_port and also return the socket to caller to do other socket initializations.

A disadvange of the design is passing parameters to on_connected,on_disconnected and on_recv_msg. Since these callback function will be activated by this package namespace, the only way to use external parameters is by defining global variable which is not a good aspect to deal with OO Design. For example:

	sub chess_connected {
		my $self=shift;
		my $client=shift;

		#you have to define $move as a global variable..
		$move=$move+1
	}

However, if your chess server is written as a class, you might have "$self->{move}". It is generally accepted that $self is autometically pass to methods when they are called, thus it shouldn't defined as a global variable. Consider this:

	package ChessServer;

	sub new {
		my $class=shift;
		my $self={};
		$self->{server}=Net::Server::NonBlocking->new();
		$self->{move}=0;

		# blablabla

		bless $self,$class;
	}

You won't get $self->{move} or $self->{xxxxx}, since $self is not global. Nevertheless, you can build your class by inheriting from this module you can solve the problem, but someone might said "I do not want to inherit from this class", so I've provided three parameters of the "add methods" to be able to pass external parameters.

	- on_connected_param

	- on_disconnected_param

	_ on_recv_msg_param

For example:

	$self->{server}->add({
				server_name => 'chess',
				local_address => $public_ip,
				local_port => $public_port,
				timout => 60,
				on_connected => \&chess_connected,
				on_disconnected => \&chess_disconnected,
				on_recv_msg => \&chess_msg,
				on_connected_param => [\$self,\%blablabla],
			});

And in the chess_connected, the parameters is passed like this

	sub chess_connected {
		my $self=shift;
		my $client=shift;
		my $chess=${$_[0]};
		my %blablalba=%{$_[1]};
	}

Does this approach mitigate the problem? I don't know !!!


Sending data back to clients could be implemented by --

        print $client "data\0"    #for small amount of data

or   
        while (1) {                               #large data or slow connection
              my $sent=send($client, $data, 0);

              substr($data,0,$sent,'') if defined $sent;
              last unless $data;
        }

or
        $self->enqueue($client,$data);   # put data to non-block output queue, most efficient !?

**caution: don't mix $self->enqueue with the other methods, unless unexpected results will occur.

**caution: enqueue doesn't send messages instantly, but queue messages to output queue. It can raise unexpected result, if you code something like this:

    $self->enqueue($client,$data);
    $self->erase_client($server_name,$client);
    # $data won't be sent to the $client, since after the data is put to the output queue, the client is disconnected.

which can be solve by flush_output method like this:

    $self->enqueue($client,$data);
    $self->flush_output($client);   #send all output_queue to $client
    $self->erase_client($server_name,$client);


Let's me introduce a callback function which make the module support broader TCP protocols.
It is:

    sub read_buffer {
	my $self=shift;
	my $raw_input=shift;
	my $cooked_input=shift;
	my $server_name=shift;

	my $dm=$self->{listen}->{$server_name}->{delimiter};
	my $sf=$self->{listen}->{$server_name}->{string_format};

	while ($$raw_input =~ s/($sf)$dm//s) {
	    push( @{$$cooked_input}, $1 );
	}
    }

By default, if you don't provide "read_buffer" parameter to the "add" function, your buffer_fetching mechanism will be the code above. The problem is that the default buffer fetching machanism is designed to work with protocols ended with some delimiters in each message, so if my protocol send a content-length appended with \r\n and the next is data which length is equal to the content-length, the subroutine will not work. It has to be modified something like this:

     $obj->add({
              ...,
              ...,
              read_buffer => \&my_buffer_reader
          });

     sub my_buffer_reader {
	 my $self=shift;
	 my $raw_input=shift;
	 my $cooked_input=shift;
	 my $server_name=shift;

	 for (;;) {
	     last unless $$raw_input =~ m/Content-length: (\d+)\r\n/;
	     last unless $$raw_input =~ s/Content-length: $1\r\n(.{$1})//s;
	     push (@{$$cooked_input}, $1);
         }
     }

** $raw_input is reference to input buffer the current client
** $cooked_input is reference to array reference of the current client incoming messages passed to on_recv_msg


Anyway, if you want to set a timer. You have to do something like this before calling "start" method:

	$obj->cron(30,sub {
			my $self=shift;
			#do something
		},@param);

30 is seconds that the CODE will be triggered.
For setting turn timeout:

	$obj->start_turn($client,$limit_time, sub {
						my $self=shift;
						my $client=shift;
						my @param=@_;

						# mark this client as the loser
					};

	$obj->reset_turn($client); #to clear limit_timer for a client

Let's see another usage for turn timer:

	sub kuay {
		my $self=shift;
		my $client=shift;

		print "timeout !\n";
        }

        my $toggle=0;

        sub chess_message {
            my $self=shift;
            my $client=shift;
            my $request=shift;

            $toggle^=1;

            if ($toggle) {
                $self->start_turn($client,2*60,\&kuay);
            } else {
                $self->stop_time($client);
            }
        }


To disconnect a client from a server, just call

	$self->erase_client($server_name,$client);


To get socket from each added server, inorder to set its property, for example:

        $sock=$self->get_server_socket($server_name);
        setsockopt($sock,SOL_SOCKET,SO_KEEPALIVE,1);
        setsockopt($sock,IPPROTO_TCP,&TCP_KEEPALIVE,120);

=head1 EXPORT

None

=head1 SEE ALSO

There're always more than one way to do it, see "Perl Cook Book" in non-blocking I/O section.

POE -- a big module to do concurrent execution

IO::Multiplex -- I/O Multiplexing server style, the only little thing that differ to this module is that the module assumes that all clients' messages are arriving fast. Entire server will be slow down if there are a group of clients whose messages are delays which are generally caused by their internet connection.

Net::Server -- another server engine implementations such as forking, preforking or multiplexing

=head1 PLATFORM

Currently, only unix. It has been tested on Linux with perl5.8.0.
Win32 platform should be supported in the future.

=head1 AUTHOR

Komtanoo  Pinpimai <romerun@romerun.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 (c) Komtanoo  Pinpimai <romerun@romerun.com>. All rights reserved. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
