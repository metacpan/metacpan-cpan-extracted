package NetworkInfo::Discovery::Scan;

use strict;
use warnings;

use NetworkInfo::Discovery::Detect;
use base ("NetworkInfo::Discovery::Detect");

use Socket;

=head1 NAME

NetworkInfo::Discovery::Scan - host/port scanner

=head1 SYNOPSIS

    use NetworkInfo::Discovery;
    use NetworkInfo::Discovery::Register;
    use NetworkInfo::Discovery::Scan;
    
    my $disc = new NetworkInfo::Discovery::Register (
        'file' => '/tmp/scan.register',
        'autosave' => 1
        )
        || warn ("failed to make new obj");
    
    my $scan = new NetworkInfo::Discovery::Scan (
        hosts=>["localhost", "127.0.0.1"],
        ports=>[53,99,1000..1004],
        timeout=>1,
        'wait'=>0,
        protocol => 'tcp'
    );
    
    $scan->do_it();
    $disc->add_interface($_) for ($scan->get_interfaces);
    
    foreach my $h ($scan->get_interfaces) {
        print $h->{ip} . "\n";
        print "    has tcp ports: " . join(',',@{$h->{tcp_open_ports}}) . "\n" if (exists $h->{tcp_open_ports}) ;
    }
    
    $scan->{protocol} = 'tcp';
    $scan->{ports} = [20..110];
    $scan->do_it();
    $disc->add_interface($_) for ($scan->get_interfaces);
    
    foreach my $h ($scan->get_interfaces) {
        print $h->{ip} . "\n";
        print "    has tcp ports: " . join(',',@{$h->{tcp_open_ports}}) . "\n" if (exists $h->{tcp_open_ports}) ;
    }


=head1 DESCRIPTION

C<NetworkInfo::Discovery::Scan> is a host/port scanner that is used to
find hosts that are too quiet for C<NetworkInfo::Discovery::Sniff> to
find.
It is a detection module subclassed from C<NetworkInfo::Discovery::Detect>.
We can probe tcp or udp ports.  
There is the ability to set a timeout on the connection so that we don't
wait all day for the scan to finish.
There is a wait attribute that keeps us from scanning the network too fast
and affecting it in a negetive manner.
The hosts attribute takes hostnames, ipaddresses, or CIDR-like network/bitmask
lists.

=head1 METHODS

=cut

=pod

=over 4

=item new 

returns a new Scan object, and takes the arguments shown in this example:

    $obj = NetworkInfo::Discovery::Scan->new(
	    hosts     =>    ["hostname", "1.2.3.4", "4.3.2.1/26"],
	    [protocol =>    ("tcp"|"udp")],
	    [timeout  =>    3 ],    #in seconds
	    [wait     =>    100],   #in miliseconds
	    [ports    =>    [80,23,100..300] ],
	);

timeout is the amount of time to wait in seconds  before giving up on a connection attempt.
wait is how long to wait in miliseconds  between each probe.
protocol is either tcp or udp -- we will only try to connect to that type of port.
hosts is an array ref of hosts to try.  The CIDR-like addresses will be expanded out
(i.e., 172.16.1.129/24 is really 172.16.1.(0-255)).  If this type of addres is used, we
do not scan the top and bottom of the range, as this should be the network and broadcast addresses.
ports is and arrey ref of numeric ports to scan for each host.

=cut

sub new {
    my $classname  = shift;
    my %args = @_;

    my $class = ref($classname) || $classname;


    my $self  = {
	    # this will hold our expanded hosts
	    _hosts => {}, # and this is our private version
	   
	    # set defaults
	    timeout => 5,	# don't hang on connect forever
	    'wait'  => 25,	# this is a wait between connect attempts in miliseconds
	    protocol => 'tcp',
	    ports   => [80, 23, 22],

	    # these are from Detect.pm
	    hostlist => [],
	    hoplist => [],
	    
    };

    bless ($self, $class);

    if ( $args{hosts} ) {
	$self->hosts($args{hosts});
	delete $args{hosts};
    }

    while (my ($k, $v) = each (%args) ) {
	$self->{$k} = $v;
    }

    
    return $self;
} 


=pod

=item do_it

Runs the scan, builds up hosts out of what we found open, and returns the hostlist.

=cut

sub do_it {
    my $self = shift;

    $self->scan;
    $self->make_hosts;

    return $self->get_interfaces;
}


=pod

=item hosts ([$aref]

Builds up our list of hosts to scan, or returns that list.
The aref can contain any of the following:
    "hostname"
    "1.2.3.4"
    "1.2.3.4/26"

The CIDR-like address will be expanded into an address range and all the
hosts in that range (minus the top one, and the bottom one) will be 
added to the host list to be scanned.

=cut

sub hosts {
    my $self = shift;
    my $aref = shift;

    #figure out what host format they are using
    foreach (@$aref) {
#	print "hosts: $_\n";
	# if is is a regular ipaddress, use it like regular
	if (m#^\d+\.\d+\.\d+\.\d+$#) {
	    push (@{$self->{hosts}}, $_);
#	    print "hosts -- single host: $_\n";

	# if it is in CIDR notation, expand it    
	} elsif (m#^(\d+\.\d+\.\d+\.\d+)(?:/(\d+))$#) {
#	    print "hosts -- CIDR host: $_\n";

	    # 0.0.0.0/0 matches all
	    if (($1 eq "0.0.0.0") and ($2 eq 0)) {
		next;	# please ignore an "all" internet scan
	    }

	    # put the ip addr into machine representation
	    my $mbits = $2 ;
	    my $bits = 32 - ($2 || 32) ;
	    my $baseIP = unpack("N", pack("C4", split(/\./, $1)));
	    my $mask = unpack("N", pack("B32", "1" x $mbits . "0" x $bits));
	    my $maskedIP = $baseIP & $mask;

	    # starting at the baseIP ending at the mask limit,
	    #	increment the ipaddress,
	    #	convert it back to a dotted quad, and add it to the list
#	    print "base = $baseIP,masked =$maskedIP, bits = $bits, 2**bits = " . (2**$bits -2) . "\n";
	    for (my $i=1; $i <= (2**$bits-2) ; $i++ ) {
		$maskedIP += 1;
		my $ip = join(".",unpack("C4", pack("N",$maskedIP)));
#		print "i=$i, i < " .(2**$bits-2) . " ip=$ip \n";
		push (@{$self->{hosts}}, $ip);
	    }

	# perhaps this is just the dns name?
	} elsif (m#([\w.]+)# ) {
	    push (@{$self->{hosts}}, $_);
	}

    }

    return $self->{'hosts'};
}


=pod

=item scan

Runs a tcp or udp scan against the hosts in our host list.  This method
uses alarm if you have set the "timeout" attribute, so please keep that
in mind and don't use your own alarm while running this.

=cut

sub scan {
    my $self = shift;

    foreach my $host (@{$self->{hosts}}) {
#	print "scanning $host\n";

	foreach my $port (@{$self->{ports}} ) {
	    my $success;

#	    print "    port $port\n";
	    select(undef, undef, undef, $self->{'wait'}/100) if ($self->{'wait'});

#	    print "    done waiting\n";

	    # build the address of the remote machine
	    my $internet_addr = inet_aton($host)
	         or (warn "Couldn't convert $host into an Internet address: $!\n" && next);
	    my $paddr = sockaddr_in($port, $internet_addr);

	    # create a socket
	    if ($self->{protocol} eq "udp") {
		socket(HOST, PF_INET, SOCK_DGRAM, getprotobyname("udp")) 
		        or (warn "failed to open socket: $!" && next);

		# udp dosn't use "connect", send and recv instead
		$success = $self->try_timeout(  
		    sub { 
			my $msg = "This is not an attack." .
				"  NetworkInfo::Discovery 0.07.";
			my $reply;
			send (HOST, $msg, 0, $paddr) 
			    || die ("udp send to $host:$port : $!");
			recv(HOST, $reply, 0, 0)
			    || die ("udp recv from $host:$port : $!");
			} 
		    );
	    } elsif ($self->{protocol} eq "tcp") {
		socket(HOST, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
		        or (warn "failed to open socket: $!" && next);

		# try the connect
		$success = $self->try_timeout(  
		    sub { 
			connect(HOST, $paddr) 
			    || die "connect error: $!";  
			} 
		    );
	    } else {
		warn "unknown protocol: " . $self->{protocol} . "\n";
		next;
	    }

	    if ($success) {
		$self->{_hosts}{$host}{$port} = $success;
	    }

	    # ... do something with the socket
	    #print HOST "Why don't you call me anymore?\n\n\n";
	    
	    # and terminate the connection when we're done
#	    print "    closing the socket\n";
	    close(HOST);
	}
	
    }
}

=pod

=item make_hosts

Builds our hostlist according to how 
C<NetworkInfo::Discovery::Detect> requires.

=cut

sub make_hosts {
    my $self = shift;

    my @hostname;

    while (my ($host, $href) = each %{$self->{_hosts}} ) {
#	print "found host $host\n";
	my $ports;
	foreach my $port ( keys (%{$href} ) ) {
#	    print " found port $port\n";
	    push (@{$ports}, $port);
	}

	my $hostObj;
	if ($self->{protocol} eq 'udp') {
	    $self->add_interface({
		ip=>$host,
		dns=>$self->lookup_ip($host),
		udp_open_ports=> $ports,
	    });
	} else {
	    $self->add_interface({
		ip=>$host,
		dns=>$self->lookup_ip($host),
		tcp_open_ports=> $ports,
	    });
	}
    }

}

=pod

=item try_timeout

This is a wrapper function to wrap our connection attempts in an
alarmed eval.

=cut

sub try_timeout {
    my $self = shift;
    my $sub = shift;

    
    eval {
	 local $SIG{ALRM} = sub { die "timeout" };

#	print "    setting alarm for " . $self->{timeout} ." seconds\n";
	alarm($self->{timeout});
	
	&$sub();   # long-time operations here

	alarm(0);
#	print "    unsetting alarm for $self->{timeout} seconds\n";
    };

    # if there was an error in the eval
    if ($@) {
#	print "        bailing -- croaked out of the eval: ";
	if ($@ =~ /^timeout$/) {
#	    print "with a timeout\n";
	    return 0;
	} elsif ($@ =~ /^connect error/) {
#	    print "with an $@\n";
	    return 0;
	} else {
#	    print "with an unknown error: $@\n";
	    alarm(0);           # clear the still-pending alarm
	    return undef;
	} 
    }
#    print "    SUCCESS: got connection!\n";

    return 1;
}

=pod

=item lookup_ip ($ip)

Does a reverse lookup on the IP and returns a list of the names we found.

=cut

sub lookup_ip {
    my $self = shift;
    my $ip = shift;
   
    my @name_lookup;
    my @resolved_ips;

    my $claimed_hostname = gethostbyaddr($ip, AF_INET) || return undef;
    #print "looking up $ip hostname:  $claimed_hostname, @name_lookup, @resolved_ips";
    @name_lookup      = gethostbyname($claimed_hostname)
	or die "Could not look up $claimed_hostname : $!\n";
    
    @resolved_ips     = map { inet_ntoa($_) }
	    @name_lookup[ 4 .. $#name_lookup ];
	    #print "looking up $ip hostname:  $claimed_hostname, @name_lookup, @resolved_ips";
}
sub lookup {
    my $self = shift;
    my $sock = shift;
    
    my $remote = getpeername($sock)
	or die "Couldn't identify other end: $!\n";
    my ($port, $iaddr)   = unpack_sockaddr_in($remote);
    my $actual_ip        = inet_ntoa($iaddr);
    my $claimed_hostname = gethostbyaddr($iaddr, AF_INET);
    my @name_lookup      = gethostbyname($claimed_hostname)
	or die "Could not look up $claimed_hostname : $!\n";
    
    my @resolved_ips     = map { inet_ntoa($_) }
	    @name_lookup[ 4 .. $#name_lookup ];
	    #print "looking up $actual_ip: hostname:  $claimed_hostname, @name_lookup, @resolved_ips";
}

=back

=head1 AVAILABILITY

This module can be found in CPAN at http://www.cpan.org/authors/id/T/TS/TSCANLAN/
or at http://they.gotdns.org:88/~tscanlan/perl/
=head1 AUTHOR

Tom Scanlan <tscanlan@they.gotdns.org>

=head1 AUTHOR

Tom Scanlan <tscanlan@they.gotdns.org>

=head1 SEE ALSO

L<NetworkInfo::Discovery::Detect>

L<NetworkInfo::Discovery::Sniff>

L<NetworkInfo::Discovery::Traceroute>

=head1 BUGS

Please send any bugs to Tom Scanlan <tscanlan@they.gotdns.org>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2002 Thomas P. Scanlan IV.  All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;

1;
