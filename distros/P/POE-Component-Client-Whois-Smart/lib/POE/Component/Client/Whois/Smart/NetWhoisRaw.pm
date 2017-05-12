#
#===============================================================================
#
#         FILE:  NetWhoisRaw.pm
#
#  DESCRIPTION:  POE::Component::Client::Whois::Smart::NetWhoisRaw
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  24.05.2009 19:09:08 MSD
#     REVISION:  ---
#===============================================================================

package POE::Component::Client::Whois::Smart::NetWhoisRaw;

use strict;
use warnings;

use POE qw(Filter::Stream Wheel::ReadWrite Wheel::SocketFactory
	   Component::Client::DNS);
use Socket;
use HTTP::Request;

use CLASS;

use List::Util qw/first/;
use Hash::MoreUtils qw/slice/;

use Time::HiRes qw( time );

use Data::Dumper;

use POE::Component::Client::Whois::Smart; # for utility functions
use Net::Whois::Raw::Common;

sub DEBUG { 1 }

our $named;

sub initialize {
    $named = POE::Component::Client::DNS->spawn(
	Alias   => 'named',
	Timeout => 10,
    );

    1;
}

sub query_order {
    15
}

sub plugin_params {
    return (
       use_cnames  => undef,
       cache_dir   => undef,
       cache_time  => 1,
       omit_msg    => 2,
       exceed_wait => 0,
       referral    => 1,

       retry_another_ip => 1,
    );
}

sub query {
    my $self = shift;
    my $query_list = shift;
    
    my @my_queries = @$query_list;
    @$query_list = ();

    $self->_query( \@my_queries, @_ );
}

sub _query {
    my $package  = shift;
    my $queries = shift;
    my $heap  = shift;
    my $args_ref  = shift;

    #$args{lc $_} = delete $args{$_} for keys %args;

    $package->get_whois_for_all( $queries, $heap, $args_ref );
}

sub get_whois_for_all {
    my ($package, $queries, $heap, $args_ref) = @_;

    my %my_params = slice( 
	$heap->{params}, qw/referral exceed_wait omit_msg use_cnames/
    );
    
    foreach my $q (@$queries) {
	++$heap->{tasks};

	my $result = $heap->{result}{ $q } ||= [];
	$package->get_whois(
	    %$args_ref,
	    retry_another_ip=> $heap->{params}{retry_another_ip},
	    query	    => $q,
	    original_query  => $q,
	    result	    => $result,
	    params	    => \%my_params,
	);
    }
}

sub get_whois {
    my $package = shift;
    $package = ref($package)|| $package;
    my %args = @_;

    if ( $args{query} eq 'pleasetesttimeoutonthisdomainrequest.com' ) {
	sleep 10;
	return;
    }

    unless ( $args{host} ) {
        my $whois_server = Net::Whois::Raw::Common::get_server($args{query}, $args{params}->{use_cnames});
        unless ( $whois_server ) {
            warn "Could not determine whois server from query string, defaulting to internic \n";
            $whois_server = 'whois.internic.net';
        }
        $args{host} = $whois_server;
    }

    my $self = bless { 
	result  => delete( $args{result} ),
	params	=> delete( $args{params} ),
	request => \%args,
    }, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [ 
            $self => [
                qw/ 
		    _start _start_resolve _start_query
		    _sock_input _sock_down
		    _sock_up _sock_failed _time_out
		  /
            ],
        ],
        options => { trace => 0 },
    )->ID();

    return $self;
}

# connects to whois-server (socket)
sub _start {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    $kernel->delay_add( '_time_out' => $self->{request}->{timeout} );

    $kernel->yield('_start_resolve');
}

sub _start_resolve {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $response = $named->resolve(
	event	=> "_start_query",
	host    => $self->{request}->{host},
	timeout => $self->{request}->{timeout},
	context => { },
    );

    if ( $response ) {
	$self->{resolved} = $response;
	$kernel->yeild('_start_query');
    }
}

sub _start_query {
    my ($kernel, $self, $resolved) = @_[KERNEL, OBJECT, ARG0];

    $resolved ||= $self->{resolved};

    my $resolved_host;

    if ( $resolved->{response} ) {
	foreach my $answer ( $resolved->{response}->answer() ) {
	    if ( $answer->type eq 'A' ) {
		$resolved_host = $answer->rdatastr;
		last;
	    }
	}
    }

    unless ( $resolved_host ) {
	$kernel->yield( '_sock_failed', 
	    'host resolve of '.$self->{request}{host}.' failed', '', '' );
	return;
    }

    if ( not exists $self->{request}{local_ip} ) {
	my $local_ip = next_local_ip(
	    $self->{request}->{host},
	    $self->{request}->{clientname},
	    $self->{request}->{rism},
	);
	
	unless ( $local_ip ) {
	    my $unban_time = unban_time(
		$self->{request}->{host},
		$self->{request}->{clientname},
		$self->{request}->{rism},                        
	    );
	    my $delay_err = $kernel->delay_add('_start', $unban_time);
	    warn "All IPs banned for server ".$self->{request}->{host}.
		", waiting: $unban_time sec\n"
		    if DEBUG;
	    return;
	}

	#warn $local_ip;

	$self->{request}{local_ip} = $local_ip eq 'default' ? undef : $local_ip;
    }

    # do it here, because we can yeild to _start from referral/another IP retry
    # and get another query in case of referral retry (new_query, see get_recursion)
    
    my $request = $self->{request};

    $request->{query_real} = 
	Net::Whois::Raw::Common::get_real_whois_query(
		$request->{query},
		$request->{host}
	);

    $request->{referral_retry} = 0;

    print time, " $self->{session_id}: Query '".$request->{query_real}.
        "' to ".$request->{host}.
        " from ".($request->{local_ip}||'default IP')."\n"
            if DEBUG;

    $self->{server} = POE::Wheel::SocketFactory->new(
        SocketDomain   => AF_INET,
        SocketType     => SOCK_STREAM,
        SocketProtocol => 'tcp',
        RemoteAddress  => $resolved_host,
        RemotePort     => $self->{request}->{port} || 43,
        BindAddress    => $self->{request}->{local_ip},
        SuccessEvent   => '_sock_up',
        FailureEvent   => '_sock_failed',
    );

    undef;
}

# socket error
sub _sock_failed {
    my ($kernel, $self, $op, $errno, $errstr) = @_[KERNEL, OBJECT, ARG0..ARG2];

    #warn "_sock_failed: $self->{request}{query}";

    $kernel->delay( '_time_out' => undef );

    delete $self->{server};

    $self->{request}->{error} = "$op error $errno: $errstr";
    my $request = delete $self->{request};
    my $session = delete $request->{manager_id};

    return unless $self->process_query( $request );

    $kernel->post( $session => $request->{event} => $request );
    
    undef;
}

# connection with socket established, send query
sub _sock_up {
    my ($kernel, $self, $session, $socket) = @_[KERNEL, OBJECT, SESSION, ARG0];
    delete $self->{server};

    $self->{server} = new POE::Wheel::ReadWrite(
        Handle     => $socket,
        Driver     => POE::Driver::SysRW->new(),
	Filter	   => POE::Filter::Stream->new(),
        InputEvent => '_sock_input',
        ErrorEvent => '_sock_down',
	AutoFlush  => 1,
    );

    unless ( $self->{server} ) {
        my $request = delete $self->{request};
        my $session = delete $request->{manager_id};
        $request->{error} = "Couldn\'t create a Wheel::ReadWrite on socket for whois";
        $kernel->post( $session => $request->{event} => $request );
        
        return undef;
    }

    $self->{request}->{whois} = '';

    $self->{server}->put( $self->{request}->{query_real}."\r\n" );
    
    undef;
}

# connection with socket finished, post result to manager
sub _sock_down {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    #warn "_sock_down: $self->{request}{query}\n";

    delete $self->{server};

    $kernel->delay( '_time_out' => undef );

    my $request = $self->{request};

    if ( $request->{whois} ) {
        delete $request->{error};
    } else {
        $request->{error} = "No information received from remote host";
    }

    return unless $self->process_query( $request );

    $kernel->post( $request->{manager_id} => $request->{event} => $request );
    
    undef;
}

# got input from socket, save it
sub _sock_input {
    my ($kernel,$self,$line) = @_[KERNEL,OBJECT,ARG0];
    #warn $line;

    $self->{request}->{whois}  .= $line;

    undef;
}

# socket timeout, abort connection
sub _time_out {
    my ($kernel,$self) = @_[KERNEL,OBJECT];

    delete $self->{server};

    #warn Dumper $self;

    #warn "_time_out: $self->{request}{query}\n";
    
    my $request = delete $self->{request};
#    my $session = delete $request->{manager_id};

    #warn Dumper $request;

    $request->{error} = "Timeout";

    return unless $self->process_query( $request );

    $kernel->post( $request->{manager_id} => $request->{event} => $request );
    
    undef;
}

sub process_query {
    my $self = shift;
    my $response = shift;

    my ($whois, $error);

    #warn Dumper $self;

    $error = $response->{error};

    if ( ! $error ) {
	$whois = $response->{whois};

	($whois, $error) = Net::Whois::Raw::Common::process_whois(
	    $response->{original_query},
	    $response->{host},
	    $whois,
	    1,
	    $self->{params}->{omit_msg},
	    2,
	);
    }

    #warn Dumper $error, $response, $self->{result}; #if $error;
    print time, " $self->{session_id}: DONE: '",$response->{query},
	    "' to ",$response->{host}, "\n" if DEBUG;

    if ( !$error || ! @{ $self->{result} } ) {

        my %result = (
            query      => $response->{query},
            server     => $response->{host},
            query_real => $response->{query_real},
            whois      => $whois,
            error      => $error,
        );
        
	push @{ $self->{result} }, \%result;

        my ($new_server, $new_query);

	if ( $result{whois} ) {
	    ($new_server, $new_query) = get_recursion(
		$result{whois},
		$result{server},
		$result{query},
		@{ $self->{result} },
	    )
	}

        if (	$self->{params}->{referral}
	    &&	$new_server 
	    &&	$response->{referral_retry}++ < 10 
	) {

	    $response->{query} = $new_query;
	    $response->{host}  = $new_server;

	    delete $response->{error};
	    delete $response->{whois};

	    $poe_kernel->yield('_start');
	    return;
        }
    }

    # exceed
    if ($error && $error eq 'Connection rate exceeded') {
        my $current_ip = $response->{local_ip} || 'localhost';
	#$servers_ban{$response->{host}}->{$current_ip} = time;
        print "Connection rate exceeded for IP: $current_ip, server: "
            .$response->{host}."\n"
                if DEBUG;
            
	# check for next_local_ip here
        if ( $response->{retry_another_ip}-- >= 0 ) {
	    #warn "THERE!!!";

	    # try to fetch next IP smart -- only all IP's are equal
	    my $old_local_ip = delete $response->{local_ip};
	    if ( not exists $self->{local_ips} ) {
		%{ $self->{local_ips} } = 
		    map { $_ => 0 } local_ips();
	    }

	    my $i;

	    if ( defined $old_local_ip ) {
		$i = ++$self->{local_ips}{ $old_local_ip };
	    }

	    # warn "$i ", Dumper $self->{local_ips};

	    $response->{local_ip} = 
		first { $i > $self->{local_ips}{ $_ } } local_ips();
		
	    $response->{local_ip} ||= next_local_ip();

	    delete $response->{error};
	    delete $response->{whois};

	    $poe_kernel->yield('_start');
	    return;
        }
    }
    
    return 1;
}


#---------------------------------------------------------------------------
#  Utility functions
#---------------------------------------------------------------------------

# check whois-info, if it has referrals, return new server and query
sub get_recursion {
    my ($whois, $server, $query, @prev_results) = @_;

    my ($new_server, $registrar);
    my $new_query  = $query;
    
    foreach (split "\n", $whois) {
    	$registrar ||= /Registrar/ || /Registered through/;
            
    	if ($registrar && /Whois Server:\s*([A-Za-z0-9\-_\.]+)/) {
            $new_server = lc $1;
            #last;
    	} elsif ($whois =~ /To single out one record, look it up with \"xxx\",/s) {
            $new_server = $server;
            $new_query  = "=$query";
            last;
	} elsif (/ReferralServer: whois:\/\/([-.\w]+)/) {
	    $new_server = $1;
	    last;
	} elsif (/Contact information can be found in the (\S+)\s+database/) {
	    $new_server = $Net::Whois::Raw::Data::ip_whois_servers{ $1 };
            #last;
    	} elsif ((/OrgID:\s+(\w+)/ || /descr:\s+(\w+)/) && Net::Whois::Raw::Common::is_ipaddr($query)) {
	    my $value = $1;	
	    if($value =~ /^(?:RIPE|APNIC|KRNIC|LACNIC)$/) {
		$new_server = $Net::Whois::Raw::Data::ip_whois_servers{$value};
		last;
	    }
    	} elsif (/^\s+Maintainer:\s+RIPE\b/ && Net::Whois::Raw::Common::is_ipaddr($query)) {
            $new_server = $Net::Whois::Raw::Data::servers{RIPE};
            last;
	}
    }
    
    if ($new_server) {
        foreach my $result (@prev_results) {
            return undef if $result->{query} eq $new_query
                && $result->{server} eq $new_server;
        }
    }
    
    return $new_server, $new_query;
}

my $pccws = 'POE::Component::Client::Whois::Smart';

sub next_local_ip {
    goto \&{$pccws.'::next_local_ip'};
}

sub local_ips {
    goto \&{$pccws.'::local_ips'};
}

sub unban_time {
    goto \&{$pccws.'::unban_time'};
}
1;
