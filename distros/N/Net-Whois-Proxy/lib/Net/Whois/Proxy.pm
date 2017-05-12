package Net::Whois::Proxy;

use strict;
use IO::Socket;
use vars qw ($VERSION);

$VERSION = $1 if('$Id: Proxy.pm,v 1.9 2005/05/22 02:40:36 cfaber Exp $' =~ /,v ([\d.]+) /);

=head1 NAME

Net::Whois::Proxy - an easy to use recursive whois client library

=head1 DESCRIPTION

The Net::Whois::Proxy library is an easy to use recursive whois client library that does not do any additional parsing of the whois data. It's goal is to quickly track down domain, ipv4, ipv6, and BGP Anonymous System numbers.

=head1 SYNOPSIS

 use Net::Whois::Proxy;
 my $whois = new Net::Whois::Proxy;

 my $record = $whois->whois('EXAMPLE.COM');

 print $record;

 exit;


Also see the whois.pl example script provided with the library distrobution

=head1 METHODS

=cut

=head2 new(option => value)

Create a new Net::Whois::Proxy object.

Avaliable options:

=over

=item * debug

Accepted values:

1 - turn on debugging, 0 - turn off debugging (default), *HANDLE - turn on debugging and send all debugging info to this file handle.

Option description:

Dump debugging information to STDOUT or a file handle.


=item * stacked_results

Accepted values:

1 - turn on result stacking, 0 - turn off result stacking (default)

Option description:

Result stacking will result in the data found durning a whois crawl being stacked on top of each other with additional tags QUERY_#: <server name> tags beening added above each result chunk.

=item * clean_stack

Accepted values:

1 - turn on clean result stacking (default), 0 - turn off clean result stacking

Option description:

Using this option will disable the QUERY_#: <server name> entries from being added to a result stack.  This option is only used if the B<stacked_results> option is enabled.

=item * master_ip_whois

Accepted values:

IP or Fully qualified domain name of a valid whois server (default: whois.arin.net)

Option description:

The master IP whois server to preform initial queries against.

=item * master_ip_port

Accepted values:

Ports 0 - 65535 (default: 43)

Option description:

The port number to use when querying the master IP whois server when preforming initial queries.

=item * master_domain_whois

Accepted values:

IP or Fully qualified domain name of a valid whois server (default: whois.internet.net)

Option description:

The master domain whois server to preform initial queries against.

=item * master_domain_port

Accepted values:

Ports 0 - 65535 (default: 43)

Option description:

The port number to use when querying the master domain whois server when preforming initial queries.

=item * master_whois

Accepted values:

IP or Fully qualified domain name of a valid whois server (default: whois.internic.net)

Option description:

The master whois server that should be queried if both IP and domain whois queries fail.

=item * master_port

Accepted values:

Ports 0 - 65535 (default: 43)

Option description:

The port number to use when querying the master whois server.


=item * query_timeout

Accepted values:

Time in seconds (default: 10)

Option description:

Sets the amount of time allowed to elaspe before assuming the server has timed out.

=cut

sub new {
 my ($class, %opts) = @_;

 my $self = bless {
	debug		=> $opts{debug},
	stacked_results	=> $opts{stacked_results},
	clean_stack	=> $opts{clean_stack},
	master_ip_whois	=> $opts{master_ip_whois} || 'whois.arin.net',
	master_ip_port	=> $opts{master_ip_port} || 43,
	master_whois	=> $opts{master_whois} || 'rs.internic.net',
	master_port	=> $opts{master_port} || 43,
	query_timeout	=> $opts{query_timeout} || 10
 }, $class;

 $self->{master_domain_whois} = ($opts{master_domain_whois} || $self->{master_whois});
 $self->{master_domain_port} = ($opts{master_domain_port} || $self->{master_port});

 return $self;
}

=head2 whois(BGP AS # or IPv6 addr or IPv4 addr or PTR or FQDN or IPv4 addr to convert)

Attempt to preform useful commands on the data provided.

If the string provided is: 'AS #' or 'AS#' preform an anonymous system whois query on the IPv4 BGP tree.

 Example:

 print $whois->whois("AS 12345");

If the string provided is an IPv6 address preform an whois query on it.

 Example:

 print $whois->whois("3ffe:b80:138c:1::59");

If the string provided is an IPv4 address preform an whois query on it.

 Example:

 print $whois->whois("63.224.69.57");

If the string provided starts with 'reverse' or 'dns' or 'rdns' and a dotted quad IPv4 address preform a PTR query.

 Example:

 print $whois->whois("reverse 63.224.69.57");


If the string provided starts with 'convert' and a dotted quad IPv4 address or long integer address, convert the address to a long integer address or a dotted quad address

 Example:

 print $whois->whois("convert 63.224.69.57");

=cut

sub whois {
 my ($self, $in) = @_;
 if((my $ip = $self->convert_ipv4($in))){     
        return $self->whois_ipv4($ip);      
 } elsif($in =~ /^[a-f0-9][a-f0-9][a-f0-9][a-f0-9]:/){
        return $self->whois_ipv6($in);     
 } elsif($in =~ /AS\s*?([0-9\s]+)/i){  
        return $self->whois_bgp_as("AS$1");                   
 } elsif($in =~ /([A-Za-z0-9-]+\.[A-Za-z]{2,4})$/){
        return $self->whois_domain($1);      
 } elsif($in =~ /^(rev|r|dns)(erse|dns)?.*?\:?\s?(\d+\.\d+\.\d+\.\d+)/i){
        return $self->whois_ptr($3);               
 } elsif($in =~ /^(con|v)(ert|vert)?.*?:?\s?(\d+\.\d+\.\d+\.\d+|\d+)/i){
        return $self->convert_ipv4($3);     
 } else {
        return $self->_seterrstr("Unknown address type");
 }
}

=head2 convert_ipv4(###.###.###.### or long_int)

Take an IPv4 "dotted quad" address and convert it to long interger format, or an IPv4 long integer address and convert it to the "dotted quad" format.

=cut

sub convert_ipv4 {
 my ($self, $int) = @_;
 $self->_pd("checking IPv4 for conversion", caller);

 if($int =~ /^\d+$/){
	$self->_pd("IPv4 is long integer format", caller);
	return inet_ntoa(pack "L", $int);
 } elsif($self->check_ipv4($int)) {
	$self->_pd("IPv4 is dotted quad format", caller);
	return unpack("L", inet_aton $int);
 } else {
	$self->_pd("address appears to be invalid", caller);
	return;
 }
}

=head2 whois_ipv4(IPv4_dotted_quad or IPv4_long_integer[, whois, port, timeout])

Preform a whois query on an IPv4 address of some type.  Optionally query B<whois> on port B<port> and timeout after B<timeout> seconds.

=cut

sub whois_ipv4 {
 my ($self, $ip, $server, $port) = @_;

 if($ip =~ /^\d+$/){
	$ip = $self->convert_ipv4($ip) || return undef; 
 }
 
 $self->check_ipv4($ip) || return undef;

 # This is our hints list to try and figure out where to look for more
 # ip information. The format is as follows:
 # whoisd => { port => port, s_flag => 'startflag', e_flag => 'stopflag', regexps => [re,re] }
 #

 my %hints = (
	 # LACNIC hints
	'whois.lacnic.net'	=> {
			port		=> 43,
			regexps	=> ['/LACNIC/'],
	},
	 # APNIC hints
	'whois.apnic.net'	=> {
			port		=> 43,
			regexps	=> ['/APNIC/'],
	},
	# AUNIC hints
	'whois.aunic.net'	=> {
			port		=> 43,
			regexps	=> ['/AUNIC-AU/'],
	},
	# RIPE hints
	'whois.ripe.net'	=> {
			port		=> 43,
			regexps	=> ['/(NET)?(BLK)?.*?-RIPE/'],
	},
	# Brazilian NIC
	'whois.nic.br'		=> {
			port		=> 43,
			regexps	=> ['/NETBLK-BRAZIL/'],
	},
	# Japan's NIC
	'whois.nic.ad.jp'	=> {
			port		=> 43,
			regexps	=> ['/JPNIC/'],
			e_flag	=> '/e',
	},
	# Telstra NIC
	'whois.telstra.net'	=> {
			port		=> 43,
			regexps	=> ['/whois\.telstra/i'],
	},
	# The Korean NIC
	'whois.nic.or.kr'	=> {
			port		=> 43,
			regexps	=> ['/whois.nic.or.kr/i'],
	},
	# Some big rwhois servers.
	# The Exodus rwhois server
	'rwhois.exodus.net'	=> {
			port		=> 4321,
			regexps	=> ['/rwhois\.exodus/i'],
	},
	# The DNAI rwhois server
	'rwhois.dnai.com'	=> {
			port		=> 4321,
			regexps	=> ['/rwhois\.dnai/i'],
	},
	# The Digex rwhois server
	'rwhois.digex.net'	=> {
			port		=> 4321,
			regexps	=> ['/rwhois\.digex/i'],
	},
	# The Internex rwhois server
	'rwhois.internex.net' => {
			port		=> 4321,
			regexps	=> ['/rwhois.internex/i'],
	},
	# The XO/Concentric rwhois server
	'rwhois.concentric.net' => {
			port		=> 4321,
			regexps	=> ['/rwhois\.concentric/i'],
	},
 );

 # If we're not querying ARIN right off the bat then add it to our hints list.
 $server || ($server = $self->{master_ip_whois});

 if($server !~ /whois\.arin\.net/i){
	 $hints{'whois.arin.net'}->{port} = 43;
	 $hints{'whois.arin.net'}->{regexps} = ['/IANA-NETBLOCK/'];
 }
 
 
 my $data = $self->_query_whois($ip, $server, $port || $self->{master_ip_port}, $self->{master_timeout}) || return;

 # See if ``ReferralServer'' exists in the CDIR
 if($data =~ /ReferralServer\:\s*(?:whois:\/\/)?([A-Za-z0-9:.-]+)/){
	my ($wi, $po) = split(/:/, $1, 2);
	$po ||= ($self->{master_whois_port} || 4321);

	$self->_pd("ReferralServer Match: $wi:$po", caller);
	my $data2 = $self->_query_whois($ip, $wi, $po, $self->{master_timeout}) || return;

	if($self->{stacked_results}){
		$self->_pd("Stacking results", caller);
		return (!$self->{clean_stack} ? 'QUERY_0: ' . $server : undef) . "\n" . $data . "\n" . (!$self->{clean_stack} ? 'QUERY_1: ' . "$wi\:$po" : "") . "\n" . $data2;
	} else {
		return ($data2 ? $data2 : $data);
	}
 }

	
 WHOIS: for my $whoisd (keys %hints){
	$self->_pd($whoisd, caller);
	HINT: for my $re (@{$hints{$whoisd}->{regexps}}){
		$re = "\$data =~ $re";
		$self->_pd("Testing: $re", caller);
		if(eval $re){
			$self->_pd("Match!", caller);
			my $data2 = $self->_query_whois($hints{$whoisd}->{'s_tag'} . $ip . $hints{$whoisd}->{'e_tag'}, $whoisd, $hints{$whoisd}->{'port'}, $hints{$whoisd}->{'timeout'} || $self->{master_timeout}) ||
				return undef;
			if($self->{stacked_results}){
				$self->_pd("Stacking results", caller);
				return (!$self->{clean_stack} ? 'QUERY_0: ' . $server : undef) . "\n" . $data . "\n" . (!$self->{clean_stack} ? 'QUERY_1: ' . $whoisd : undef) . "\n" . $data2;
			} else {
				return ($data2 ? $data2 : $data);
			}
		}
	}
 }
 return $data;
}

=head2 whois_ipv6(IPv6_address)

Preform an IPv6 whois query on B<IPv6_address>

=cut

sub whois_ipv6 {
 my ($self, @ip) = (shift, split(/:/, shift, 8));
 # This is the IPv6 hints data
 # each regexp# represents a differnt chunk of the ipv6 ip block.
 # If you know if any pTLA's which aren't in this please
 # send me an email and ill add them cfaber@fpsn.net
 #
 my %hints = (
	 # The 6bone testbed pTLD
	'whois.6bone.net'	=> {
		 port			=> 43,
		 regexps		=> ['/^3ffe/i','/^5[fF][0-fF][0-fF]/'],
	},
	# The APNIC IPv6 block
	'whois.apnic.net'	=> {
		port			=> 43,
		regexps			=> ['/^2001/','/^2[0-fF][0-fF]/'],
	},
	# The ARIN IPv6 block
	'whois.arin.net'	=> {
		port			=> 43,
		regexps			=> ['/^2001/','/^4[0-fF][0-fF]/'],
	},
	# The RIPE IPv6 block
	'whois.ripe.net'	=> {
		port			=> 43,
		regexps			=> ['/^2001/','/^6[0-fF][0-fF]/','/^2002/'],
	},
 );
 

 WHOIS: for my $whoisd (keys %hints){
	$self->_pd($whoisd, caller);
	HINT: for my $re (@{$hints{$whoisd}->{regexps}}){
		$re = "\$ip[0] =~ $re";
		$self->_pd("Testing: $re", caller);
		if(eval $re){
			$self->_pd("Match!", caller);
			my $data = $self->_query_whois($hints{$whoisd}->{'s_tag'} . join(':', @ip) . $hints{$whoisd}->{'e_tag'}, $whoisd, $hints{$whoisd}->{'port'}, $hints{$whoisd}->{'timeout'} || $self->{master_timeout}) || return undef;
			return $data;
		}
	}
 }

 return $self->_seterrstr("IPv6 Lookup failure: Unknown mask range.");
}


=head2 whois_bgp_as(ID)

Preform an whois query on an anonymous system number on the IPv4 BGP tree.

=cut

sub whois_bgp_as {
 my ($self, $id) = @_;
 $id =~ s/[^0-9]+//g;
 return $self->_seterrstr("whois_bgp_as() requires a valid id") if(!$id);
 
 my %as_table = (
	'whois.arin.net' => {
		as_table =>		[
							[1, 1876],
							[1902, 2042],
							[2044, 2046],
							[2048, 2106],
							[2137, 2584],
							[2615, 2772],
							[2823, 2829],
							[2880, 3153],
							[3354, 4607],
							[4865, 5376],
							[5632, 6655],
							[6912, 7466],
							[7723, 8191],
							[11264, 12287],
							[13312, 14335],
						],
		port		=> 43,
		's_tag'	=> 'AS',
	},
	'whois.ripe.net' => {
		as_table =>		[
							[1877, 1901],
							[2043],
							[2047],
							[2107, 2136],
							[2585, 2614],
							[2773, 2822],
							[2830, 2879],
							[3154, 3353],
							[5377, 5631],
							[6656, 6911],
							[8192, 9215],
							[12288, 13311],
						],
		port		=> 43,
		's_tag'	=> 'AS',
	}, 
	'whois.apnic.net' => {
		as_table =>		[
							[4608, 4864],
							[7467, 7722],
							[9216, 10239],
						],
		port		=> 43,
		's_tag'	=> 'AS',
	},
 );
 
 for my $whoisd (keys %as_table){
	 for my $entry (@{$as_table{$whoisd}->{as_table}}){
		 if($entry->[0] && $entry->[1]){
			if($id >= $entry->[0] && $id <= $entry->[1]){
				 my $data = $self->_query_whois($as_table{$whoisd}->{'s_tag'} . $id . $as_table{$whoisd}->{'e_tag'}, $whoisd, $as_table{$whoisd}->{port}, $as_table{$whoisd}->{timeout} || $self->{master_timeout}) ||
					 return undef;
				return $data;
			}
		} elsif($id == $entry->[0]){
				 my $data = $self->_query_whois($as_table{$whoisd}->{'s_tag'} . $id . $as_table{$whoisd}->{'e_tag'}, $whoisd, $as_table{$whoisd}->{port}, $as_table{$whoisd}->{timeout} || $self->{master_timeout}) ||
					 return undef;
				return $data;
			}
		}
 }

 return $self->_seterrstr("Unable to lookup entry for AS ID $id");
}

=head2 whois_domain(FQDN[, whois, port, timeout)

Preform a recursive whois lookup on a fully qualified domain name (FQDN), Optionally preform the initial query against the B<whois> whois server on port B<port> with the timeout B<timeout>.

=cut

sub whois_domain {
 my ($self, $domain, $server, $port, $timeout) = @_;
 my $nic;

 if(!$domain || $domain !~ /^[0-9A-Za-z-]+\.[A-Za-z]{2,4}$/){
	return $self->_seterrstr("Domain name appears invalid");
 } else {
	my $data = $self->_query_whois('=' . $domain, $server || $self->{master_domain_whois}, $port || $self->{master_domain_port}, $timeout || $self->{master_timeout}) || return $self->_seterrstr("_query_whois() failed to return any data. Possible error(s): " . ($self->errstr ? $self->errstr : 'Unknown'));

	if($data =~ /Whois\s?Server:\s?([A-Za-z0-9.-]+\.[A-Za-z]{2}[A-Za-z]?)/i){
		$nic = $1;
	}

	if(!$nic && $data){
		return ($data ? $data : 'Server returned no data');
	} elsif($nic) {
		my $data2 = $self->_query_whois($domain, $nic, $port || $self->{master_domain_port}, $timeout || $self->{master_timeout}) || return $self->_seterrstr("_query_whois() failed to return any data. Possible error(s): " . ($self->errstr ? $self->errstr : 'Unknown'));

		if($self->{stacked_results}){
				return (!$self->{clean_stack} ? 'QUERY_0: ' . $server : undef) . "\n" . $data . "\n" . (!$self->{clean_stack} ? 'QUERY_1: ' . $nic : undef) . "\n" . $data2;
		} else {
			return ($data2 ? $data2 : 'Server returned no data');
		}
	} else {
		return $self->_seterrstr("Domain lookup failed.");
	}
 }
}

=head2 check_ipv4(IPv4_dotted_quad)

Attempt to determin if an IPv4 address is syntaxually valid.

=cut

sub check_ipv4 {
 my ($self, @ip) = (shift, split(/\./, shift, 4));

 if(!$ip[0] || $ip[-1] !~ /\d/ || $ip[0] > 255 || $ip[0] !~ /^\d+$/){
	return $self->_seterrstr("Invalid IPv4 address");
 } else {
	for my $i (1 .. 3){
		if($ip[$i] > 255 || $ip[$i] !~ /^\d+$/){
			return $self->_seterrstr("Invalid IPv4 address");
		}
	}
	 return join('.', @ip);
 }
}

=head2 errstr()

Return the last error message set.

=cut

sub errstr {
 my ($self, $err) = @_;
 $self->{errstr} = $err if($err);
 return $self->{errstr};
}

=head2 whois_ptr(IPv4_dotted_quad_address);

Return the PTR / Reverse domain name of a dotted quad IPv4 address.

=cut

sub whois_ptr {
 my ($self, $ip) = @_;
 my $name = (gethostbyaddr(pack('C4', split(/\./, $ip, 4)), 2))[0];
 return ($name ? $name : $self->_seterrstr("The $ip failed to contain a valid PTR record"));
}

=head2 whois_raw(command, server, port, timeout)

Preform a raw whois with B<command> against the whois server B<server> on the port B<port> with the timeout B<timeout>/

=cut 

sub whois_raw {
 my $self = shift;
 return $self->_query_whois(@_);
}

sub _query_whois {
 my ($self, $data, $serv, $port, $timeout) = @_;
 my $sock;

 $self->{master_timeout} ||= 10;

 $port ||= $self->{master_port};
 $serv ||= $self->{master_serv};
 $timeout ||= $self->{master_timeout};

 $self->_pd("Attempting to connect to: $serv:$port (to: $timeout)", caller);

 eval {
	$SIG{ALRM} = sub { die 'timeout'; };
	alarm(($timeout || $self->{master_timeout}) + 5);
	$sock = IO::Socket::INET->new(
		Proto		=> 'tcp',
		PeerAddr	=> $serv || $self->{master_whois},
		PeerPort	=> $port || $self->{master_port},
		Timeout	=> $timeout || $self->{master_timeout}
	) || die "Unable to create socket $!";
	alarm(0);
 };
 if($@ =~ /timeout/){
	$self->_pd("Timed out!", caller);
	return $self->_seterrstr("Connection to " . ($serv || $self->{master_whois}) . ':' . ($port || $self->{master_port}) . " was refused.");
 } elsif($@){
	$self->_pd("Failure: $@", caller);
	return $self->_seterrstr("Unknown error while connecting to " . ($serv || $self->{master_whois}) . ':' . ($port || $self->{master_port}) . '.');
 } elsif(!$sock){
	$self->_pd("Failure: Connection failed", caller);
	return $self->_seterrstr("Unable to connect to " . ($serv || $self->{master_whois}) . ':' . ($port || $self->{master_port}) . '.');
 } else {
	$self->_pd("Connected. Sending data: $data", caller, caller);
	$data .= "\r\n" if($data !~ /[\r\n]+$/);
	print $sock $data;
	my @data = <$sock>;
	return (@data && wantarray ? @data : (@data ? "@data" : $self->_seterrstr("Query on ``$data'' failed to return results" . ($! ? ': ' . $! : undef))));
 }
}

sub _seterrstr {
 my ($self, $err) = @_;
 $self->errstr($err);
 return;
}

sub _clean {
 my ($self, @lines) = @_;
 for(my $i = 0; $i < @lines; $i++){
	$lines[$i] =~ s/^\s+|\s+$//g;
	$lines[$i] =~ s/[\r\n\x0A\x0D]+//g;
 }
 return (wantarray ? @lines : join("\n", @lines));
}

sub _pd {
 my ($self, $msg, $pkg, $file, $line) = (shift, shift, @_);
 my ($l_pkg, $l_file, $l_line) = caller;

 $self->{_debug_cnt}++;
 if($self->{debug}){
	my $str = sprintf("[%5d] internal->{ $l_pkg on $l_line line } external->{ $file\->$pkg on $line } data->{ %s }\r\n", $self->{_debug_cnt}, scalar $msg);
	if($self->{debug} eq 1){
		print STDOUT $str;
	} else {
		my $handle = $self->{debug};
		print $handle $str;
	}
 }
 return 1;
}

1;

__END__

=head1 AUTHOR

Colin Faber <cfaber@fpsn.net> http://www.fpsn.net

=head1 LICENSE

(C) Colin Faber All rights reserved.  This license may be used under the terms of Perl it self.

=head1 REPORTING BUGS

Please email all bug reports to me at <cfaber@fpsn.net>. Be sure to include the version of the module you're using along with a sample script which can reproduce the bug and remember if all else fails. debug => 1 is your friend.
