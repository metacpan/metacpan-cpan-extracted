package Net::DNS::Check;

use strict;
use vars qw($VERSION $AUTOLOAD);

$VERSION = '0.45';

use Carp;
use Net::DNS;
use Net::DNS::Resolver::Recurse; 
use Net::DNS::Check::Config;
use Net::DNS::Check::HostsList;
use Net::DNS::Check::Host;
use Net::DNS::Check::NSQuery;
use Net::DNS::Check::Test;
use Data::Dumper;


my %PUBLIC_ARGS = map { $_ => 1 } qw(
	config
	config_file
	domain
	nserver debug);


sub new {
	my ($class) 	= shift;

	my $self = {};

	bless $self, $class;

	# Hash ref of auth nameservers # {$nsname}->{ip} array ref of found ip address # {$nsname}->{ip_orig} array ref of decoded ip address from nserver param
	# {$nsname}->{host}  host object created
	# {$nsname}->{status}  status information about nserver.. it can contains 
	#     the error from host object or the error from nsquery object
	$self->{nsauth} 	= {};

	# Contains  the summary of test:
	# Ex:
	# OK 10
	# E 3
	# W 1
	# $self->{test_summary} = {};

	# Contains the object ref of executed tests 
	$self->{test_obj} = {};

	# Array Ref that contains the NSQuery objects
	$self->{nsquery} = [];


	# Default true
	$self->{check_status} = 1;

	# Process arguments. Return false if not mandatory arguments exist  
	unless ($self->_process_args(@_)) {
        croak("\nnserver param not found!\n");
	}



	# General HostsList: contains the Host object of 
	# hosts outside of the domain name
    $self->{hostslist} = new Net::DNS::Check::HostsList( 
		domain 	=> $self->{domain}, 
		config 	=> $self->{config}
	);
	

	# Decode $self->{nserver} string and create $self->{nsauth} hash ref;
	# If there isn't a nserver string we try to find ns from recursion
	if ( $self->{nserver} ) {
		# Decode nserver string
		$self->{nsauth} = $self->_decode_ns($self->{nserver});
	} else {
		# Search for ns record
		$self->{nsauth} = $self->_auth_finder();
	}

	# authoritative nameservers check (at least one must exists) 
	unless ( keys %{$self->{nsauth}} ) {
		$self->{error} = 'NXDOMAIN';
		$self->{check_status} = 0;
	} 

	# if we haven't any error we proceed with _ns_query
	unless ( $self->{error} ) {
		$self->_ns_query();
	}

    return $self;
}



# Process input arguments. Only %PUBLIC_ARGS keys are
# accepted and copy valid arguments to $self hash/object
sub _process_args {
	my ($self, %args) = @_;

	foreach my $attr ( keys %args) {
		next unless $PUBLIC_ARGS{$attr};
		
		$self->{$attr} = $args{$attr};
	}

	# Create a default config object if no one is passed 
	$self->{config} ||= new Net::DNS::Check::Config();


	# Load a configuration from a config file.
	# The config file override the default params contained
	# in Config object or Config object passed. 
	if ( $self->{config_file} ) {
		# Not yet implemented
		# $self->{config}->load_conf_file();
	}

	# If there is not a debug param we get it from Config 
	unless (defined $self->{debug} ) {
		$self->{debug} = $self->{config}->debug_default(); 
	}

	$self->{domain} = lc $self->{domain};
	$self->{qdomain} = $self->{domain};
	$self->{qdomain}    =~ s/\./\\./g;

	# Return the mandatory arguments
	return $self->{domain};
}



# Decode nsstring and transform it to hash ref
# Example:
# "dns.foo.com=10.10.10.2,192.168.1.2;dns2.foo.com=10.11.2.2"
# Created HASH:
# dns.foo.com => [ 10.10.10.2, 192.168.1.2 ],
# dns2.foo.com => [ 10.11.2.2 ] 
sub _decode_ns() {
	my $self = shift;
	my $nsstr = lc shift;

	my %nshash;

	# We need a regexp check of $nsstr
	if ($nsstr) {
		my @nsarray = split(';', $nsstr);
		foreach my $ns ( @nsarray ) {
			my ($nsname, $nsip) = split('=',$ns);
			my @ip;

			if ( $nsname ) {
				if ( $nsip ) {
					@ip = split(',',$nsip);
				}

				$nshash{$nsname}->{ip_orig} = [ @ip ];

				my $host;
				if ( $nsname =~ /^(.*\.$self->{qdomain}|$self->{qdomain})$/ ) {
					$host = new Net::DNS::Check::Host(
                		debug   => $self->{debug},
                		host    => $nsname,
                		config  => $self->{config},
                		ip      => [ @ip ],
                		ip_orig => [ @ip ]
            		);

				} else {
					$host = $self->{hostslist}->add_host( hostname => $nsname, ip => [ @ip ], ip_orig => [ @ip ] ); 
				}

				$nshash{$nsname}->{ip} 		= $host->get_ip(); 
				$nshash{$nsname}->{status}	= $host->error(); 
				$nshash{$nsname}->{host} 	= $host; 
			}
		}
	} 
	
	return \%nshash;
}


# FIXED? PRENDENDO l'authority section a volte prendiamo i root ns se 
# ad esempio il nameserver a cui poniamo lo damanda non e' autoritativo
# per la zona
###################################
# This function try to find the dns servers of a domain.
# This function doesn't use any local resolver but starts
# query using Net::DNS::Resolver::Recurse facility.
# The main goal of the function is to find  delagated nameservers 
# (some time delegated are not the same of authoritative na) of a domain
# asking them to auth ns of the upper domain.
# For example if I need to find the auth nservers of foo.com domain
# I ask them to .com auth nservers and not to foo.com nserver.
# We found different implementation in the answer from bind8
# to bind9. BIND8 answers with the information contained in
# the delegated zones, while bind9 returns the reference
# to auth nservers of the zone and so I get the answer from them 
# (Authority section).
# For example: if I ask for the NS records for foo.com
# I got the answer directly from auth nservers of .com because 
# .com auth nservers (Root NS) use BIND8, but if I ask for
# foo.it I get the ns list from auth ns of foo.it and
# not from .it auth ns because the majority of them use BIND9.
# This function so try to get the answer always from delegating
# nservers.
sub _auth_finder() {
	my $self = shift; 	

	my @split 		= split('\.', $self->{domain});
	shift(@split);
	my $parent 		= join ('.', @split ); 
	my @ns;    
	my $packet;
	my %nshash;

	if ($self->{debug} > 0) {
		print <<DEBUG;

Searching for delegated nameservers of $self->{domain}
============================================
DEBUG
	}


	# We create an object for Resolver
	my $resolver = Net::DNS::Resolver->new(
        recurse         => 0,
        debug           => ($self->{debug} > 2),
        retrans         => $self->{config}->query_retrans(),
        retry       	=> $self->{config}->query_retry(),
        tcp_timeout     => $self->{config}->query_tcp_timeout(),
    );


	# We create an object for Resolver Recurse
	my $recurse = Net::DNS::Resolver::Recurse->new(
        debug           => ($self->{debug} > 2),
        retrans         => $self->{config}->query_retrans(),
        retry       	=> $self->{config}->query_retry(),
        tcp_timeout     => $self->{config}->query_tcp_timeout(),
	);
	$recurse->hints( @{$self->{config}->rootservers()} );

	# We ask for NS records of parent domain
	$packet =  $recurse->query_dorecursion( $parent , "NS");

	if ($self->{debug} > 0) {
		print <<DEBUG;

 Looking for authoritative nameservers of parent domain: $parent
DEBUG
	}


	if ($packet) {
		foreach my $rr ( $packet->answer ) {
			if ($rr->type eq 'NS') {
				push(@ns, $rr->nsdname()) if ($rr->nsdname);
				if ($self->{debug} > 0) {
					my $ns = $rr->nsdname();
					print <<DEBUG;
  $parent NS $ns
DEBUG
				}
			}
		}
	} else {
		# No answer from root nameserver.... link problem
		$self->{error} = 'NOANSWER';
		return {};
	}

	# Unresolvable domain $parent and then $self->{domain}
	unless (@ns) {
		$self->{error} = 'NXDOMAIN';
		return {};
	}


	# We are looking for $self->{domain} delegated ns list (querying the authoritative
	# nameservers of father of $self->{domain})
	# We stop to the first answer found
	foreach my $qns ( @ns ) {
		my $address;
	
		# Try to get the address of auth nameservers of father domain
		$packet =  $recurse->query_dorecursion( $qns , "A");
		if ($self->{debug} > 0) {
			print <<DEBUG;

 Looking for A RR of $qns 
DEBUG
	}


	
		if ($packet) {
			foreach my $rr ( $packet->answer ) {
				if ($rr->type eq 'A') {
					$address = $rr->address;
					if ($self->{debug} > 0) {
						my $ip = $rr->address();
						print <<DEBUG;
  $qns A $ip
DEBUG
					}
				}
			}
		} 

	
		# if we found an address we try to query it, otherwise we look for another dns
		if ($address) {
			$resolver->nameservers( ( $address ) );
			$packet = $resolver->send( $self->{domain}, "NS");
			if ($self->{debug} > 0) {
				print <<DEBUG;

 Query $address for NS RR of $self->{domain} 
DEBUG
			}

			# If we haven't an answer we try with another dns
			if ($packet) {
				my @nsresult;

				if ( $packet->answer() ) {
					@nsresult = grep { $_->type eq 'NS' } $packet->answer();
				} else {
					foreach my $rr ( $packet->authority() ) {
						# We consider valid only authority information
						# about the domain we are looking for:
						# sometime we got authority section with root nameservers
						# and usually is not the answer we want (lame delegation). 
						# If one $rr->name is equal to $parent probably all
						# name are equal to parent... anyway we check all of them 
						if ( lc($rr->name) eq lc($self->{domain}) and $rr->type eq 'NS' ) {
							push(@nsresult, $rr);
						}
					}
					#@nsresult = grep { $_->type eq 'NS' } $packet->authority();
				}


				if (@nsresult) {
					# Splitted in two foreach loop a better debug output

					# We get all NS RR for every nameservers found,
					# we add them to nshash and, at present, we add them to
					# general hostslist. Note: not all hosts should be added
					# to general hostslist
					foreach my $rr ( @nsresult ) {
				 		my $nsname = lc $rr->nsdname();
						if ($nsname) {
							if ($self->{debug} > 0) {
								print " NS Found $nsname\n";
							}
							$nshash{$nsname}->{ip_orig} = []; 
						}
					}
	
					if ($self->{debug} > 0 ) {
						print <<DEBUG;

Searching for IP of delegated nameservers of $self->{domain}
============================================
DEBUG
					}

					foreach my $nsname ( keys %nshash ) {

						my $host;
						if ( $nsname =~ /^(.*\.$self->{qdomain}|$self->{qdomain})$/ ) {
							$host = new Net::DNS::Check::Host(
                				debug   => $self->{debug},
                				host    => $nsname,
                				config  => $self->{config},
            				);
						} else {
							$host = $self->{hostslist}->add_host( hostname => $nsname ); 
						}

						$nshash{$nsname}->{ip} 		= $host->get_ip(); 
						$nshash{$nsname}->{status}	= $host->error(); 
						$nshash{$nsname}->{host} 	= $host; 
					}

					last;
				} else {
					if ($self->{debug} > 0) {
						print <<DEBUG;
  Not Authoritative answer 
DEBUG
					}

				}
			} else {
				if ($self->{debug} > 0) {
					print <<DEBUG;
  No answer: time out
DEBUG
				}
			}
		}
	}

	return \%nshash;
}


# Create NSQuery object, one for every auth nameservers 
sub _ns_query {
	my $self 	= shift;

	#print Dumper $self->{nsauth};
	foreach my $nsname ( keys %{ $self->{nsauth} } ) {

#		next if ($nsname eq 'dns3.nic.it' || $nsname eq 'dns2.nic.it' );

		# If we have the IP address
		if ( scalar @{$self->{nsauth}->{$nsname}->{ip}} > 0 ) {

    		my $queryobj = new Net::DNS::Check::NSQuery(
        		config       	=> $self->{config},
        		domain      	=> $self->{domain},
        		nserver     	=> $nsname,
        		ip    			=> $self->{nsauth}->{$nsname}->{ip}, 
        		hostslist    	=> $self->{hostslist}
    		);

			# If there is an error in Net::DNS::Check::NSQuery
			unless ( $queryobj->error() ) {
    			push(@{$self->{nsquery}}, $queryobj);
			} else {
				$self->{check_status} = 0;
				$self->{nsauth}->{$nsname}->{status} = $queryobj->error();
				if ($self->{debug} > 0 ) {
					my $error = $queryobj->error();
					print <<DEBUG;
 Error: $error 
DEBUG
				}
			}
		} else {
			if ($self->{debug} > 0 ) {
				my $error;
				if ( $self->{nsauth}->{$nsname}->{host} ) {
					$error = $self->{nsauth}->{$nsname}->{host}->error();
				}

				print <<DEBUG;

Query for RR ANY for $self->{domain} to $nsname
=======================================================
 $nsname IP: not found
 Error: $error

 SKIP
DEBUG
			}

			$self->{check_status} = 0;
		}
	}

}


sub check {
	my $self	= shift;

	my $result;

	# Return and set check_status to false if nsquery array is empty 
	unless ( @{$self->{nsquery}} ) {
		$self->{check_status} = 0;

		return;
	}


	foreach my $test_name ( keys %{ $self->{config}->test_configured() } ) {
    	my $test = new Net::DNS::Check::Test(
        	type    	=>  $test_name,
        	nsquery 	=>  $self->{nsquery}, 
        	nsauth 		=>  [ keys %{$self->{nsauth}} ], 
        	config  	=>  $self->{config},
			hostslist	=>	$self->{hostslist}
    	);


		$self->{test_obj}->{$test_name} = $test;

		# If test_status is true or in other word the test doesn't fail
		if ( $test->test_status() ) {
			$self->{test_obj}->{$test_name}->{status} = $self->{config}->ok_status(); 
			$self->{test_summary}->{$self->{config}->ok_status()}++;
		} else {

			my $status = $self->{config}->test_conf( test => $test_name ) || $self->{config}->default_status();;

			$self->{test_obj}->{$test_name}->{status} = $status;
			$self->{test_summary}->{$status}++;

			if ( grep { $_ eq $status } @{$self->{config}->error_status()} ) {
				$self->{check_status} = 0;
			}
		}
	}

	return $self->{check_status};
}


# Returns the list of executed tests or the list of executed test in a specific status 
sub test_list() {
    my  $self   = shift;
    my  $status = shift;

    unless ( defined $self->{test_obj} || defined $self->{config}->{$status} ) {
        return;
    }

	if ($status) {
		my @status_array;
		foreach my $test_name (keys %{$self->{test_obj}}) {
			if ($self->{test_obj}->{$test_name}->{status} eq $status) {
				push(@status_array, $test_name);
			}
		}
		return @status_array;
	} else {
    	return keys %{$self->{test_obj}};
	}
}

# Returns the status of $test_name test 
sub test_status() {
    my  $self   = shift;
    my  $test_name = shift;

    unless ( $test_name ) { 
        return;
    }

    return $self->{test_obj}->{$test_name}->{status};
}

# Returns the Net::DNS::Check::Test object of $test_name test 
sub test_object() {
    my  $self   = shift;
    my  $test_name = shift;

    unless ( $test_name ) { 
        return;
    }

    return $self->{test_obj}->{$test_name};
}

# Returns the result of Net::DNS::Check::Test::test_detail() for $test_name test 
sub test_detail() {
    my  $self   = shift;
    my  $test_name = shift;

	return unless $test_name;

    unless ( $test_name or $self->{test_obj}->{$test_name} ) { 
        return;
    }

    return $self->{test_obj}->{$test_name}->test_detail();
}





# Return the number of executed test of the requested status.
# For Example: if $status = OK the function return the number of ok tests
# If no status = '' returns an hash containing the number of all result for
# every level ( OK => 5, E => 1, F => 0, W => 0);
sub test_summary() {
	my  $self	= shift;
	my  $status	= shift;

	unless ( defined $self->{test_summary} ) {
		return {};
	}

	if ( $status ) {
		return $self->{test_summary}->{$status}; 
	} else  {
		return $self->{test_summary};
	}
}


# Used to knows if the global process of checking the dns of the domain
# is ok or not
# It Returns true if check_status is true and if there is an error returns 
# an empty value 
sub check_status() {
	my  $self	= shift;

	return ( $self->{check_status} && not $self->{error} );
}


# Returns the array of authoritative/delegated nameserver 
sub nsauth() {
	my  $self	= shift;
	my  $nsname	= shift;

	return keys %{$self->{nsauth}};
}


# This function returns status information about a nameserver 
sub ns_status() {
	my $self	= shift;
	my $nsname  = shift;

	return unless ( $nsname );

	return $self->{nsauth}->{$nsname}->{status};
}


# Return the domain checked or we want to check 
sub domain() {
	my $self	= shift;

	return $self->{domain};
}


sub error() {
	my $self	= shift;

	return $self->{error};
}


1;

__END__

=head1 NAME

Net::DNS::Check::Check - OOP Perl module based on L<Net::DNS|Net::DNS> for domain name checking. 

=head1 SYNOPSIS

 use Net::DNS::Check;

 my $dnscheck = new Net::DNS::Check(
	domain      => 'foo.com'
 );
 print ($dnscheck->check()?'OK':'FAILED');




 use Net::DNS::Check;
 use Net::DNS::Check::Config;

 my $config = new Net::DNS::Check::Config();
 $config->test_conf( test => 'soa_refresh_range', level => 'I');
 my $dnscheck = new Net::DNS::Check(
	domain      => 'foo.com',
	config		=> $config,
	nserver		=> 'ns.acme.com;ns2.acme.com=1.2.3.4',
	debug		=> 1
 );
 print ($dnscheck->check()?'OK':'FAILED');


=head1 DESCRIPTION

Net::DNS::Check is a collection of OOP Perl modules allowing easy implementation of applications for domain name checking.

The Net::DNS::Check was built to be as easy as possible to use and highly configurable and flexible: it allow easy implementation of your custom test and deeper configuration of what you want to check and how. 

=head2 Config Objects 

A Config object is an instance of the 
L<Net::DNS::Check::Config|Net::DNS::Check::Config> class.
With this object you can configure how Net::DNS::Check operates. You can set, for example, which test will be executed during the check phase, set the debug level and several other options. For additional information see L<Net::DNS::Check::Config|Net::DNS::Check::Config>. 

=head2 Test Object 

L<Net::DNS::Check::Test|Net::DNS::Check::Test> is the base class for test objects. A test is the single analysis that you can execute during the checking phase of a domain name. You can create a subclass of L<Net::DNS::Check::Test> class and generate your custom test. For additional information see L<Net::DNS::Check::Test|Net::DNS::Check::Test>.
At present these are the supported tests:

=over 2

=item *

L<host_ip_private|Net::DNS::Check::Test::host_ip_private>

=over 2

Check if the IP addresses found during the hosts resolution do not belong to IP private classes. 

=back

=item *

L<host_ip_vs_ip_orig|Net::DNS::Check::Test::host_ip_vs_ip_orig> 

=over 2

Compare the IP addresses found during the hosts resolution with the IP addresses given with nserver argument (if exists) in method "new". 

=back

=item *

L<host_not_cname|Net::DNS::Check::Test::host_not_cname> 

=over 2

Check if the hosts found are CNAME or not.

=back

=item *

L<host_syntax|Net::DNS::Check::Test::host_syntax> 

=over 2

Verify the correctness of the hosts syntax.

=back

=item *

L<mx_compare|Net::DNS::Check::Test::mx_compare> 

=over 2

Compare the MX RR found. 

=back

=item *

L<mx_present|Net::DNS::Check::Test::mx_present> 

=over 2

Check if the MX RR is present or not.

=back

=item *

L<ns_compare|Net::DNS::Check::Test::ns_compare> 

=over 2

Check if the NS RR are the same in all the authoritative nameservers.

=back

=item *

L<ns_count|Net::DNS::Check::Test::ns_count> 

=over 2

Check if the number of NS RR are within the range set in the configuration object. For additional information see: L<Net::DNS::Check::Config|Net::DNS::Check::Config>.

=back

=item *

L<ns_vs_delegated|Net::DNS::Check::Test::ns_vs_delegated> 

=over 2

Compare the NS RR found with the effectively delegated nameservers (NS RR in the parent zone of the domain name being checked).

=back

=item *

L<soa_expire_compare|Net::DNS::Check::Test::soa_expire_compare> 

=over 2

Compare the expire time of all the authoritative nameservers.

=back

=item *

L<soa_expire_range|Net::DNS::Check::Test::soa_expire_range> 

=over 2

Check if the expire time in the SOA RR is within the range set in the configuration object. For additional information see: L<Net::DNS::Check::Config|Net::DNS::Check::Config>.

=back

=item *

L<soa_master_compare|Net::DNS::Check::Test::soa_master_compare> 

=over 2

Compare the value of the master nameserver specified in the SOA RR of all the authoritative nameservers.

=back

=item *

L<soa_master_in_ns|Net::DNS::Check::Test::soa_master_in_ns> 

=over 2

Check if the NS RR exists for the master nameserver specified in the SOA RR. 

=back

=item *

L<soa_refresh_compare|Net::DNS::Check::Test::soa_refresh_compare> 

=over 2

Compare the refresh time in SOA RR of all authoritative nameservers.

=back

=item *

L<soa_refresh_range|Net::DNS::Check::Test::soa_refresh_range> 

=over 2

Check if the refresh time in the SOA RR is within the range set in the configuration object. For additional information see: L<Net::DNS::Check::Config|Net::DNS::Check::Config>.

=back

=item *

L<soa_retry_compare|Net::DNS::Check::Test::soa_retry_compare> 

=over 2

Compare the retry time in the SOA RR of all the authoritative nameservers.

=back

=item *

L<soa_retry_range|Net::DNS::Check::Test::soa_retry_range> 

=over 2

Check if the retry time in the SOA RR is within the range set in the configuration object. For additional information see: L<Net::DNS::Check::Config|Net::DNS::Check::Config>.

=back

=item *

L<soa_serial_compare|Net::DNS::Check::Test::soa_serial_compare> 

=over 2

Compare the serial number in the SOA RR of all the authoritative nameservers.

=back

=item *

L<soa_serial_syntax|Net::DNS::Check::Test::soa_serial_syntax> 

=over 2

Check if the syntax of the serial number in the SOA RR are in the AAAAMMGGVV format.

=back

=back


=head1 METHODS

=head2 new

This method creates a new Net::DNS::Check object and returns a reference to it. Arguments are passed as hash. The method "new" gives origin to all necessary queries.

=over 2

=item

domain: mandatory argument corresponding to the domain name you want to check 

=item

config: a reference to a L<Net::DNS::Check::Config|Net::DNS::Check::Config> object. This argument is optional and, if not present, the default configuration is used. 

=item

nserver: a string containing the list of all the authoritative nameservers. This argument is mandatory if the domain name to be cheked has not yet been delegated.
The nserver string has a specific format:
nserver_name=IP1,IP2...;nserver2_name=IP1;nserver3_name=IP1,IP2,IP3;...

The IP addresses are mandatory only for the nameservers within a domain name which has not yet been delegated. As many nameservers as necessary cab be typed into the nserver string. 

Examples:

ns.foo.com=10.0.0.1;ns2.foo.com=192.168.1.1,192.168.3.100

ns.amce.com;ns4.foo.com=10.1.1.1


=item

debug: with this argument the required debug level can be set: 

=over 2

=item 

Level 0: no debug information 

=item 

Level 1: print to STDOUT information about executed actions 

=item 

Level 2: as for level 1, but information about query answers are also displayed 

=item 

Level 3: as for previous levels, but debug option of  Net::DNS module is also activated.

=back  

=back  


=head2 check

With this method the check of the domain name starts. You'll get a true value if the check succeded or false otherwise.

=head2 test_summary

This method returns an hash containing the status and number of executed tests in that status.

For example if you have 3 tests in Warning status, 2 in Error status and 5 in OK status an hash like this will be given:

'W' => 3,
'E' => 2,
'OK' => 5

At present 4 different status are supported: OK, Warning (W), Error (E), Ignore (I). For additional information about status see L<Net::DNS::Check::Conf|Net::DNS::Check::Config>.

If an argument containing a specific status is passed, this method returns only the number of executed test in that status.

Examples:

	# $dnscheck is Net::DNS::Check object
	$dnscheck->check();

	# Print the number of test in OK status 
	print $dnscheck->test_summary('OK')


	# Return the hash of all the status
	# ********* ATTENZIONE attualmente riporta un hash reference, 
	# stabilire cosa e' meglio
	my %hash_status = $dnscheck->test_summary();

	foreach my $status ( keys %hash_status ) {
		print "$status: ". $hash_status{$status}."\n";
	}
			

=head2 check_status

This method returns "true" if the check succeede or otherwise "false".  

=head2 nsauth

Returns the list (array) of the authoritative nameservers. Autoritative nameservers correspond to delegated nameservers (NS RR within the zone of the parent domain) or correspond to the nameservers passed with "nserver" argument in the method "new".

=head2 ns_status

This method returns status the information about the nameserver passed as argument. The nameserver must be one of the delegated nameservers.  The status is "false" if no errors are found.  If some problems to resolve the nameserver name are found or some errors are given during the query, this method returns an error string ("true" value):

=item *

NXDOMAIN: the domain name of the nameserver does not exist.

=item *

NOANSWER: some link problems (query time out) 


=head2 error

This method return "false" if no errors are found during the check of the domain name. Otherwise it returns the error string ("true" value):

=item *

NXDOMAIN: the domain name or one of its parents have not yet been delegated (and the "nserver" argument of the method "new" is empty) 

=item *

NOANSWER: some link problems (query time out) 


Note that if this method returns an error ("true" value), the check (called with the "check" method) will never start.

=head2 test_list

This method returns an array containing the name of executed tests or, if the status argument is passed, it returns the array of the test in a specific status. At present 4 different status are supported: OK, Warning (W), Error (E), Ignore (I). For additional information about status see L<Net::DNS::Check::Conf|Net::DNS::Check::Config>.

=head2 test_object

This method returns the reference to L<Net::DNS::Check::Test|Net::DNS::Check::Test> object specified as argument.

=head2 test_status

This method returns the status information about the test name passed as argument. At present there 4 different status are supported: OK, Warning (W), Error (E), Ignore (I). An OK status is returned if the test succeedes. One of the possibile other values, according to the configuration, is returned otherwise. For additional information about status see L<Net::DNS::Check::Config|Net::DNS::Check::Config>.

=head2 test_detail

This method returns detailed information about a test name passed as argument.
It returns an hash in which keys are nameserver names (delegated nserver) and values are an hash point whose keys are "desc" or "status" and values are: for "desc", a text string containing a description of result and for "status" a "true" or "false" value depending on the test results. 

Example of returned hash for 'soa_serial_syntax' test:

	%ret = (
			'ns.foo.com' => {
			'desc'		=> '2005041700', 
			'status' 	=> 1
		},
			'ns.acme.net' => {
			'desc'		=> '20050320', 
			'status' 	=> 0
		},
	);
     

Example:

    foreach my $test_name ( $dnscheck->test_list() ) {

        $result .= "\n$test_name: ".$dnscheck->test_status($test_name) ."\n";
        $result .= "==============================\n";
        my %test_detail = $dnscheck->test_detail($test_name);

        foreach my $ns_name ( keys %test_detail ) {
            if ( defined $test_detail{$ns_name}->{desc} ) {
                my $detail_status   = $test_detail{$ns_name}->{status};
                my $detail_desc     = $test_detail{$ns_name}->{desc};
                $result .= "$ns_name: Status: $detail_status Desc: $detail_desc\n";
            } 
        }

    }

=head2 domain

Returns the domain name passed as argument to the method "new". 

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut
