package Net::PSYC::Circuit;

our $VERSION = '0.4';

use strict;
use Socket qw(SO_KEEPALIVE inet_ntoa);
use IO::Socket::INET;

import Net::PSYC qw( watch add W sendmsg same_host send_mmp parse_uniform BLOCKING makeMSG make_psyc parse_psyc parse_mmp PSYC_PORT PSYCS_PORT register_host register_route make_mmp UNL);

sub listen {
	# looks funky.. eh? undef makes IO::Socket handle INADDR_ANY properly
	# whereas '' causes an exception. stupid IO::Socket if you ask me.
    my ($class, $ip, $port, $options) = @_;
    my $socket = IO::Socket::INET->new(
			LocalAddr => $ip || undef,
				    # undef == use INADDR_ANY
                        LocalPort => $port || undef,
				    # undef == take any port
                        Proto => 'tcp',
                        Listen => 7,
		        Blocking => BLOCKING() & 2,
			Timeout => 5,
                        ReuseAddr => 1
		    )
			or return $!;
    my $self = { 
	'SOCKET' => $socket,
	'IP' => $ip||$socket->sockhost(),
	'PORT' => $_[2] || $socket->sockport,
	'LAST_RECV' => getsockname($socket),
	'type' => 'c',
	'O' => $options,
    };
    W1('TCP Listen %s:%s successful.', $self->{'IP'}, $self->{'PORT'});
    bless $self, 'Net::PSYC::Circuit::L';
    watch($self) unless BLOCKING() & 2;
    return $self;
}

#   new ( \*socket, vars )
sub new {
    my ($class, $socket, $vars) = @_;
    my $self = {
	'O' => {},
	'SOCKET' => $socket,
	'type' => 'c',
	# These buffer may be moved to a reconnected object. 
	# maybe not the IN-buffer, but right now we cannot do anything
	# about it. -> later TODO
	'I_BUFFER' => '',
	'O_BUFFER' => [],
	# this one not! (its only used for negotiation and such)
	'N_BUFFER' => [], 
	'O_COUNT' => 0,
	'CACHE' => {}, # cache for fragmented data
	'I_LENGTH' => 0, # whether _length of incomplete
			 # packets exceeds buffer-length
	'FRAGMENT_COUNT' => 0,
	'R' => {},
	'L' => 0,
	'state_temp' => {},
	'state' => {},
	'vars' => {},
	'error' => 0,
	%$vars,
    };
    $socket->sockopt( SO_KEEPALIVE(), 1 );
    bless $self, 'Net::PSYC::Circuit::C';

    $self->{'R_HOST'} =	$self->{'R_IP'};
    $self->{'peeraddr'} = "psyc://$self->{'R_HOST'}:$self->{'R_PORT'}/"; 
    $Net::PSYC::C{"$self->{'R_IP'}\:$self->{'R_PORT'}"} = $self;
    
    # stupid if. 
    register_host($self->{'R_IP'}, $self->{'R_HOST'}) if ($self->{'R_HOST'});
    register_host('127.0.0.1', 'localhost');
    # TRUST ist something arbitrary anyway.. there is no problem to wait for 
    # the dns_resolution to set it correctly
    same_host('127.0.0.1', $self->{'R_IP'},
	      sub {
		    my $result = shift;
		    $self->TRUST(9) if $result;			
	      });
    register_route("$self->{'R_HOST'}\:$self->{'R_PORT'}", $self);

    # if we are an accepted socket, the greeting has allready been fired out
    # 
    # in case we are blocking _and_ mmp modules have been activated we block
    # here and do negotiation
    #
    watch($self) unless (BLOCKING() & 2);
    if (BLOCKING() & 1) { # blocking writes!
	$self->logon();
    } else {
	add($self->{'SOCKET'}, 'w', sub { $self->logon() }, 0);
    }
    return $self;
}

sub connect {
    my $class = shift;
    my $ip = shift;
    my $port = shift || PSYC_PORT();
    my $socket = IO::Socket::INET->new(Proto     => 'tcp',
                                       PeerAddr  => $ip,
				       Blocking	=> BLOCKING() & 1,
                                       PeerPort  => $port );
    # we need some nonblocking error handling
    if (!$socket) {
	W1('TCP connect to %s:%d failed. (%s)', $ip, $port, $!);
	return 0;
    }
    my $self = {
	'R_IP' => $ip,
	'R_PORT' => $port,
    };
    return Net::PSYC::Circuit->new($socket, $self);
}

# TCP connection class
package Net::PSYC::Circuit::C;

use bytes;
use strict;

use Socket;

use base qw(Net::PSYC::MMP::State Net::PSYC::Hook);

import Net::PSYC qw( revoke W UNL sendmsg same_host send_mmp parse_uniform BLOCKING makeMSG make_psyc parse_psyc parse_mmp make_mmp register_route register_host dns_lookup);

my $PING_INTERVAL = 77;

sub TRUST {
    my $self = shift;
    $self->{'TRUST'} = $_[0] if exists $_[0];
    return $self->{'TRUST'} || 3;
}

sub accept_modules {
    my $self = shift;
    my $module = shift;
    my $on = shift;
    
    # !defined($on) ist quasi 1
    if (!defined($on) || $on) {
	return 1 if $self->accepting_modules($module);
	$self->{'O'}->{'_understand_modules'}->{$module} = 1;
	$self->fire($self->{'peeraddr'},0,{ '+_understand_modules' => $module });
	# it is possible that this happens before proper neg? then we are
	# dead! TODO

	return 1 if (!$self->{'R'}->{'_understand_modules'}->{$module});

	if ($module eq '_compress') {
	    return $self->zlib_init_client(); 
	} elsif ($module eq '_encrypt') {
	    unless (SSL()) {
		W0("The other side offers SSL-encryption. It would be wise to install IO::Socket::SSL (v0.93 or above).");
		return 1;
	    }
	
	    $self->fire($self->{'peeraddr'},0,
			{ '+_using_modules' => '_encrypt' },
			sub { $self->{'OK'} = 0 },
		    );
	    $self->{'SSL_client'} = 1;
	    # TODO . same code as in gotiate(). Think about something else. 
	    # plus: in case we have eventing we should use a timer-event to
	    # stop waiting. 
	    return 1;
	}
    } else {
	# may be impossible.
	W0('It is impossible to remove the mmp module %s from an established'.
	   ' connection.', $module);
	return 1 if (!exists $self->{'O'}->{'_understand_modules'}->{$module});
    }
}

sub accepting_modules {
    my $self = shift;
    my $module = shift;
    
    return 0 unless ($self->{'O'}->{'_understand_modules'}->{$module});
    return 1;
}

# counterparts to understand_ and use_
# means that a _using_modules came in
sub negotiate {
    my $self = shift;
    my $module = shift;
   
    unless (exists $self->{'R'}->{'_using_modules'}) {
	$self->{'R'}->{'_using_modules'} = {};
    }
    $self->{'R'}->{'_using_modules'}->{$module} = 1;
    
    if ($module eq '_encrypt') {
	if ($self->{'SSL_client'}) {
	    return $self->tls_init_client();
	} else {
	    return $self->tls_init_server();
	}
    } elsif ($module eq '_compress') {
	return $self->zlib_init_server();
    }
}

sub gotiate {
    my $self = shift;
    my $module = shift;

    unless (exists $self->{'R'}->{'_understand_modules'}) {
	$self->{'R'}->{'_understand_modules'} = {};
    }
    $self->{'R'}->{'_understand_modules'}->{$module} = 1;
    return 1 unless ($self->accepting_modules($module));

    if ($module eq '_encrypt') {
	unless (SSL()) {
	    W0("The other side offers SSL-encryption. It would be wise to install IO::Socket::SSL (v0.93 or above).");
	    return 1;
	}
	
if (Net::PSYC::FORK) {
	$self->fire($self->{'peeraddr'},0,
		    { '+_using_modules' => '_encrypt' },
		    sub { $self->{'OK'} = 0 }
		);
} else {
	$self->fire('',0,{ '_using_modules' => '_encrypt' },
		    sub { $self->{'OK'} = 0 }
		);
}
	$self->{'SSL_client'} = 1;
	
	return 1;
    } elsif ($module eq '_compress') {
	Net::PSYC::Event::revoke($self->{'SOCKET'}, 'w');
	$self->zlib_init_client();	
	return 1;
    }
}

sub ping_init {
    my $self = shift;
    # we are a server or do not have eventing
    return 1 if ($self->{'L'} || BLOCKING());
    
    Net::PSYC::Event::remove($self->{'ping_id'}) if exists $self->{'ping_id'};
    $self->{'ping_sub'} ||= sub { 
	syswrite($self->{'SOCKET'}, ".\n");
    };
    $self->{'ping_id'} = Net::PSYC::Event::add( $PING_INTERVAL, 't', 
			      $self->{'ping_sub'}, 1); 
}

sub tls_init_server { 1 }
sub tls_init_client {
    my $self = shift;
    my $t = IO::Socket::SSL->start_SSL($self->{'SOCKET'}); 
#	SSL_server => ($self->{'L'}) ? 1 : 0);
    if (ref $t ne 'IO::Socket::SSL') {
	return 1;
    }
    W1('Using encryption to %s.', $self->{'peeraddr'});
    $self->{'SOCKET'} = $t;
    $self->{'OK'} = 1;
    unless (BLOCKING()) {
	Net::PSYC::Event::forget($self);
	Net::PSYC::Event::watch($self);
	Net::PSYC::Event::revoke($self->{'SOCKET'}, 'w');
    }
}

# the naming of client/server is fucked up. TODO
sub zlib_init_server {
    my $self = shift;
    unless (eval{ require Net::PSYC::MMP::Compress }) {
	Net::PSYC::shutdown($self->{'SOCKET'});
	W0('Somehow your Compression modules does not work (%s). '. 
	   'Shutting down connection.', $@);
	# shut down.. whatever
	# TODO switch off _understand_modules _compress
	return 1;
    }
    unless ($self->{'_compress'}) {
	$self->{'_compress'} = new Net::PSYC::MMP::Compress($self);
    }
    $self->{'_compress'}->init('decrypt');
    return 1;
}

sub zlib_init_client {
    my $self = shift;
    unless (eval { require Net::PSYC::MMP::Compress }) {
	W0('Somehow your Compression modules does not work (%s).', $@);
	return 1;
    }

    unless ($self->{'_compress'}) {
	$self->{'_compress'} = new Net::PSYC::MMP::Compress($self);
    }
if (Net::PSYC::FORK) {
    $self->fire($self->{'peeraddr'},0,{ '+_using_modules' => '_compress' },
		sub { $self->{'_compress'}->init('encrypt') });
} else {
    $self->fire('',0,{ '_using_modules' => '_compress' },
		sub { $self->{'_compress'}->init('encrypt') });
}
}

sub logon {
    my $self = shift;

    $self->{'O'} = \%Net::PSYC::O;
    # TODO nonblocking dns.
    $self->{'R_HOST'} = gethostbyaddr($self->{'SOCKET'}->peeraddr(), AF_INET()) 
			|| $self->{'R_IP'};
    $self->{'IP'} = $self->{'SOCKET'}->sockhost();
    $self->{'PORT'} = $self->{'SOCKET'}->sockport();
    $self->{'R_IP'} = $self->{'SOCKET'}->peerhost();
    $self->{'R_PORT'} = $self->{'SOCKET'}->peerport();
    $self->{'LAST_RECV'} = $self->{'SOCKET'}->peername();
    register_host($self->{'R_IP'}, inet_ntoa($self->{'SOCKET'}->peeraddr()));
    register_host('127.0.0.1', $self->{'IP'});
    register_route(inet_ntoa($self->{'SOCKET'}->peeraddr()).":$self->{'R_PORT'}", $self);

    W1('TCP: Connected with %s:%s', $self->{'R_IP'}, $self->{'R_PORT'});
    syswrite($self->{'SOCKET'}, ".\n");

    # I would like to rename OK. it may be necessary to work on STATE-BITS in
    # the future. for now this is okay TODO
    #
    # we allow sending messages before receiving a _notice_circuit_established
    # in case
    # 	- we accept()ed the connection
    # 	- we are doing blocking writes _and_ reads 
    # 	- we are anachronistic and not on tls, zlib or lsd TODO
    unless (BLOCKING() & 1) {
	Net::PSYC::Event::add($self->{'SOCKET'}, 'w', sub {$self->write()}, 0);
    }
    if ($self->{'L'} || (BLOCKING() & 1 && BLOCKING() & 2)) {
	$self->{'OK'} = 1;
    }
    $self->greet();
}

# greet
sub greet {
    my $self = shift;

    # _notice_circuit_established versenden. (MMP-neg)
    # we _could_ send _using_modules here.. but. who cares???
    my $h;
    my $m;
if (Net::PSYC::FORK) {
    $h = {
	'=_understand_modules' => [ keys %{$self->{'O'}->{'_understand_modules'}} ],
	'=_implementation' => $self->{'O'}->{'_implementation'},
	'=_understand_protocols' => $self->{'O'}->{'_understand_protocols'},
    };
    $m = make_psyc('_notice_circuit_established', 
		      'Connection to [_source] established!');
} else {
    $h = {
	'_understand_modules' => [ keys %{$self->{'O'}->{'_understand_modules'}} ],
	'_implementation' => $self->{'O'}->{'_implementation'},
	'_understand_protocols' => $self->{'O'}->{'_understand_protocols'},
    };
    $m = make_psyc('_notice_circuit_established', 
		      'Connection to [_source] established!');
    $self->fire($self->{'peeraddr'}, $m, $h);
    # formally this is wrong, because in !FORK _*_modules are psyc vars. but
    # since the muve does not give a shit we do neither. 
    $m = make_psyc('_status_circuit', 
		      'I feel good.');

}
    $self->fire($self->{'peeraddr'}, $m, $h);
}

sub send {
    my ($self, $target, $data, $vars, $prio) = @_;

    W2('"%s" -> send(%.10s.., %s)', $self->{'peeraddr'}, $target, $data);
    if (!exists $vars->{"_source"} && exists $self->{'me'}) {
	$vars->{"_source"} = $self->{'me'};
    }
    if (ref $data eq 'ARRAY') {
	if (1) { #$self->{'O'}->{'_using_modules'}->{'_fragments'}) {
	    $vars->{'_counter'} = $self->{'FRAGMENT_COUNTER'}++; 
	    $vars->{'_amount_fragments'} = scalar(@$data);
	} else {
	    # very bad bad idea... better drop the packet
	    $data = [ join('', @$data) ];
	}
    } else {
	$data = [ $data ];
    }

    push(@{$self->{'O_BUFFER'}}, [ $data, $vars, 0 ]);

    $self->{'O_COUNT'} = scalar(@{$self->{'O_BUFFER'}}) - 1 if ($prio);
    
    if (BLOCKING()) { # send the packet instantly
        $self->write();
    } elsif ($self->{'OK'}) {
	revoke($self->{'SOCKET'}, 'w');
    }
    
    return 0;
}

sub fire {
    my $self = shift;
    my ($target, $data, $vars, $cb) = @_;

    $data ||= '';
    $vars ||= {};
    $vars->{'_target'} = $target if $target;
    #unless ($vars->{'_target'}) {
    #	W("fire may not be called without a proper _target",0);
    #	return 0;
    #}
    $vars->{'_source'} ||= delete $vars->{'_source'};

    #W("'$vars->{'_target'}'->fire('$data', $vars, ".($cb||'undef').")",2);

    if (!exists $vars->{"_source"} && exists $self->{'me'}) {
	$vars->{"_source"} = $self->{'me'};
    }

    push(@{$self->{'N_BUFFER'}}, [ [ $data ], $vars, 0, $cb ]);
    if (BLOCKING()) { # send the packet instantly
        $self->write();
    } else {
	Net::PSYC::Event::revoke($self->{'SOCKET'}, 'w');
    }
}

sub write () {
    my $self = shift;
    
    # no permission to send packets.. and we are not wierdo enough!
    # TODO
    return 1 unless ($self->{'OK'});

    my $N = $self->{'N_BUFFER'};
    my $O = $self->{'O_BUFFER'};
    my ($data, $vars, $count, $cb);    

    if (scalar @$N) {
	($data, $vars, $count, $cb) = @{$N->[0]};
    } elsif (exists $O->[$self->{'O_COUNT'}]) {
	($data, $vars, $count) = @{$O->[$self->{'O_COUNT'}]};
    } else {
	W2('packets in %p: %d%s', $self, scalar(@$O), "\n");
	return 1; # no packets!
    }
    
    $vars->{'_fragment'} = $count if ($vars->{'_amount_fragments'});

    my $d = $data->[$count];

    use Storable qw(dclone);
    $vars = dclone($vars); # but the current design.. TODO
    # TODO . shutdown connection if trigger fails. its really important for
    # encryption/decryption
    $self->trigger('send', $vars, \$d);
    
    my $m = make_mmp($vars, $d, $self);
    $self->trigger('encrypt', \$m);

    if (!defined(syswrite($self->{'SOCKET'}, $m))) {
	# put the packet back into the queue
	
	if (++$self->{'error'} >= 3) {
	    W0('Sending a tcp packet to %s failed for the third time. Closing '.
	       'connection.', $self->{'peeraddr'});
	    return -1; 
	}
	W0('Sending a packet to %s failed (%s). %d more retries.', 
	    $self->{'peeraddr'}, $self->{'error'});
	return 1;
    } else {
	$self->{'error'} = 0;
    }
    $self->ping_init();
    
    $self->trigger('sent', $vars, \$d);
    $cb->() if ($cb);

    W2('TCP: wrote %d bytes of data to the socket', length($m));     
    W2('TCP: >>>>>>>> OUTGOING >>>>>>>>\n%s\nTCP: <<<<<<< OUTGOING <<<<<<<\n',
       $m);

    if (($vars->{'_amount_fragments'} || @$data) == $count + 1) {
	# all fragments of this packet sent
	# delete it..
	if (scalar @$N) {
	    shift @$N;
	} else {
	    splice(@{$O}, $self->{'O_COUNT'}, 1);
	}
    } else {
	# fragments of this packet left
	# increase the fragment-id
	$self->{'O_BUFFER'}->[$self->{'O_COUNT'}]->[2]++;
	# increase the packet id.. 
	$self->{'O_COUNT'}++;
    }
    $self->{'O_COUNT'} = 0 unless ( exists $O->[$self->{'O_COUNT'}] );
    if ( @$N || @$O ) {
	if (BLOCKING() || $Net::PSYC::ANACHRONISM) { # send the packet 
	    $self->write();
	} else {
	    revoke($self->{'SOCKET'}, 'w');
	}	
    }
    return 1;
}

sub read () {
    my $self = shift;
    my ($data, $read);
    
    # if you change the buffer-size.. remember to fix buffersize of
    # MMP::Compress and rest..
    $read = sysread($self->{'SOCKET'}, $data, 4096);
    
    return if (!$read); # connection lost !?
    # gibt es nen 'richtigen' weg herauszufinden, ob die connection noch lebt?
    # connected() und die ganzen anderen socket-funcs helfen einem da in
    # den ekligen fällen nicht..
    
    unless ($self->trigger('decrypt', \$data)) {
	W0('Fatal error during decrypt. Closing connection');	
	return;
    }
    
    $$self{'I_BUFFER'} .= $data;
    warn $! unless (defined($read));
    $self->{'I_LENGTH'} += $read;
#    open(file, ">>$self->{'HOST'}:$self->{'PORT'}.in");
#    print file $data;
#    print file "\n========\n";
#    close file;
    W2('TCP: Read %d bytes from socket.', $read);
    W2('TCP: >>>>>>>> INCOMING >>>>>>>>\n%s\nTCP: <<<<<<< INCOMING <<<<<<<', 
	$data);
    
    unless ($self->{'LF'}) {
	# we need to check for a leading ".\n"
	# this is not the very best solution though.. 
	if ($self->{'I_LENGTH'} > 2) {
	    if ( $self->{'I_BUFFER'} =~ s/^\.(\r?\n)//g ) {
		$self->{'LF'} = $1;
		# remember if the other side uses \n or \r\n
		# to terminate lines.. we need that for proper
		# and safe parsing
	    } else {
		syswrite($self->{'SOCKET'}, 
		    make_psyc('_error_syntax_initialization', 
		    'The protocol begins with a dot on a line by itself.'));
		W0('Closed Connection to %s', $self->{'R_HOST'});
		Net::PSYC::shutdown($self);
	    }
	}
    }
    
    return 1;
}

# return undef if packets are incomplete
# return 0 if there maybe/are still packets in the buffer
# return the packet
sub recv () {
    my $self = shift;
    
    return unless ($self->{'LF'});
    return if ($self->{'I_LENGTH'} < 0 || '' eq $self->{'I_BUFFER'});

    my ($vars, $data) = parse_mmp(\$$self{'I_BUFFER'}, $self->{'LF'}, $self);

    return if (!defined($vars));
    
    if ($vars < 0) {
	$self->{'I_LENGTH'} = $vars;
	return;
    }

    if ($vars == 0) {
	return (-1, $data);			
    }

if (!Net::PSYC::FORK) {
    if (exists $vars->{'_using_modules'}) {

	unless (ref $vars->{'_using_modules'} eq 'ARRAY') {
	    $self->negotiate($vars->{'_using_modules'}) 
		if $vars->{'_using_modules'};
	} else {
	    map { $_ && $self->negotiate($_) } @{$vars->{'_using_modules'}};
	}
    }
}

    return (-1, "Fatal error during receive.") 
	unless ($self->trigger('receive', $vars, \$data));

    unless (exists $self->{'me'} || $self->{'L'} || !exists $vars->{'_target'}) {
	$self->{'me'} = $vars->{'_target'};
	my $r = parse_uniform($vars->{'_target'});
	if (ref $r && $r->{'host'}) {
	    dns_lookup($r->{'host'},
		       sub {
			    my $ip = shift;
			    unless ($ip) {
				W0('Could not resolve %s.', $r->{'host'});
			    }
			    W0('%s -> %s', $r->{'host'}, $ip);
			    register_host('127.0.0.1', $ip || $r->{'host'});
		       });
	} else {
	    W0('I cannot parse that target: %s. Closing connection.', 
		$vars->{'_target'});
	    return -1;
	}
    }
    
    $vars = { %{$self->{'vars'}}, %$vars } if (each %{$self->{'vars'}});
    
    # TODO return -1 unless trigger(). 
    # TODO we have to check _context for consistency anyway! do that or someone
    # starts killing perlpsycs
    # these routing schemes are bogus. i would like to use the new ones. should
    # be easier to do nonblocking dns then. one big change
    unless (exists $vars->{'_source'}) {
	$vars->{'_source'} = $self->{'peeraddr'};
    } else {
	my $h = parse_uniform($vars->{'_context'}||$vars->{'_source'});
	unless (ref $h) {
	    W0('I cannot parse that uni: %s. Closing connection.', 
		$vars->{'_context'} || $vars->{'_source'} );
	    return -1;
	}
	
	unless (same_host($h->{'host'}, $self->{'R_IP'})) {
	    if ($self->TRUST < 5) {
		# just dont relay
		W0('TCP: Refused packet from %s. (_source: %s)', 
		    $self->{'peeraddr'}, $vars->{'_source'});
		return 0;
	    }
	} else {
	    # we will relay for you in the future
	    register_route($vars->{'_source'}, $self);
	}
    }
=onion    
    if (exists $vars->{'_source_relay'} && $self->{'_options'}->{'_accept_modules'} =~ /_onion/ && $self->{'r_options'}->{'_accept_modules'} =~ /_onion/) {
	register_route($vars->{'_source_relay'}, $self);
	W("_Onion: Use $self->{'R_IP'} to route $vars->{'_source_relay'}",2);
	# remember pseudo-address to route packets back!
    }
=cut
    ####
    # FRAGMENT
    # handle fragmented data
    #if (exists $self->{'O'}->{'_understand_modules'}->{'_fragments'}
    #&& exists $vars->{'_fragment'}) {
    if (exists $vars->{'_fragment'}) {
	# {source} {logical target} {counter} [ {fragment} ]
	my $packet_id = '{'.($vars->{'_source'} || '').
			'}{'.($vars->{'_target'} || '').
			'}{'.($vars->{'_counter'} || '').'}';
	if (!exists $self->{'CACHE'}->{$packet_id}) {
	    $self->{'CACHE'}->{$packet_id} = [
		{
		    '_totalLength' => $vars->{'_totalLength'},
		    '_amount_fragments' => $vars->{'_amount_fragments'},
		    '_amount' => 0,
		},
		[]
	    ];
	}
	my $v = $self->{'CACHE'}->{$packet_id}->[0];
	my $c = $self->{'CACHE'}->{$packet_id}->[1];
	# increase the counter
	$v->{'_amount'}++ if (!$c->[$vars->{'_fragment'}]);
	#print STDERR "Fragment: $vars->{'_fragment'} (total: $vars->{'_amount_fragments'}, amount: $v->{'_amount'}, id: '$packet_id')\n";
	    
	$c->[$vars->{'_fragment'}] = $data;
	if ($v->{'_amount'} == $v->{'_amount_fragments'}) {
	    $data = join('', @$c);
	    delete $self->{'CACHE'}->{$packet_id};
	    W1('TCP: Fragmented packet complete! length: %d', length($data));
	} else {
	    W1('TCP: Fragmented number %d', int($vars->{'_fragment'}));
	    return 0;
	}
    }
    ####
    return 0 if ($data eq '');
    
    W1('TCP[%s] => %s', $vars->{'_source'}, $vars->{'_target'});
    $vars->{'_INTERNAL_origin'} = $self;
    return ($vars, $data);	
}

sub DESTROY {
    my $self = shift;
    $self->{'SOCKET'}->shutdown(0) if $self->{'SOCKET'};
}

# TCP listen class
package Net::PSYC::Circuit::L;

use strict;

import Net::PSYC qw(W0);

sub read () {
    my $self = shift;
    my $socket = $self->{'SOCKET'}->accept();
    my $obj = Net::PSYC::Circuit->new($socket, { 
	'L' => 1,
	'R_IP' => $socket->peerhost(),
	'R_PORT' => $socket->peerport(),
	});
    return 1;
}

sub recv () { }

sub send {
    W0("\nTCP: I am listening, not sending! Dont use me that way!");
}

sub TRUST {
    W0("\nTCP: Dont TRUST() me, I'm only listening.");
}

1;
