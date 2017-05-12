package Net::DNS::Check::Config;

use vars qw($VERSION $AUTOLOAD);

use strict;
use Carp;

sub new {
	my ($pkg, %param) = @_;

	my $self = {};

	bless $self, $pkg;

	# Definizione rootnameservers 
	$self->{rootservers} = [ qw(
		198.41.0.4
		128.9.0.107
		192.33.4.12
		128.8.10.90
		192.203.230.10
		192.5.5.241
		192.112.36.4
		128.63.2.53
		192.36.148.17
		192.58.128.30
		193.0.14.129
		198.32.64.12
		202.12.27.33 )
	];


	$self->{debug_default} 		= 0; 


	# Intervallo di tempo per la  ritrasmissione delle query
	$self->{query_retrans} 		= 5;

	# Numero di tentativi nelle fare le query 
	$self->{query_retry}		= 2;

	# Time out delle connessioni di tipo TCP (default a 120)
	$self->{query_tcp_timeout}	= 30;

	# Time out delle connessioni di tipo UDP (default undef)
	$self->{query_udp_timeout}	= undef;

	# Abilita disabilita le query per i RR::AAAA 
	$self->{query_AAAA}			= undef;

	# $self->{predefined_hosts}->{'dns.nic.it'} 	= ['193.205.245.5'];
	# $self->{predefined_hosts}->{'dns2.nic.it'} 	= ['193.205.245.8'];
	# $self->{predefined_hosts}->{'dns3.nic.it'} 	= ['193.205.245.66'];

	# list of all available Check (test)
	# if you add a new Check you should add it to this list 
	$self->{test_list} = [ qw(
		mx_compare
		mx_present
		ns_compare
		ns_vs_delegated
		ns_count
		soa_expire_compare
		soa_expire_range
		soa_refresh_compare
		soa_refresh_range
		soa_retry_compare
		soa_retry_range
		soa_serial_compare
		soa_serial_syntax
		soa_master_compare
		soa_master_in_ns
		host_syntax
		host_not_cname
		host_ip_vs_ip_orig
		host_ip_private
	) ];



	$self->{test_level}->{OK} = 'OK';
	$self->{test_level}->{E} = 'Error';
	$self->{test_level}->{W} = 'Warning';
	$self->{test_level}->{I} = 'Ignore';
	$self->{test_level}->{F} = 'Fatal';

	$self->{ok_status} = 'OK';
	$self->{error_status} = [qw{E F}];
	$self->{default_status} = 'E'; 

	# List of all configured test. This is an hash ref containg
	# all test used. Default use all available tests. 
	# Default level E (Error) 
	$self->{test_configured} = { map { $_ => 'E' } @{ $self->{test_list} } }; 

	# $self->{test_configured}->{soa_serial_syntax} = 'W';
	# $self->{test_configured}->{soa_serial_compare} = 'W';
	# $self->{test_configured}->{soa_refresh_range} = 'W';
	# $self->{test_configured}->{soa_refresh_compare} = 'W';
	# $self->{test_configured}->{soa_retry_range} = 'W';
	# $self->{test_configured}->{soa_retry_compare} = 'W';


	# If value is '0'
	$self->{ns_min_count} 		= 2;
	$self->{ns_max_count} 		= 0; 	# no max limit 

	$self->{soa_min_retry} 		= 1800;
	$self->{soa_max_retry} 		= 28800;

	$self->{soa_min_refresh} 	= 1800;
	$self->{soa_max_refresh} 	= 86400;

	$self->{soa_min_expire} 	= 86400;
	$self->{soa_max_expire} 	= 0; 	# no max limit

	$self->{ip_private} = [ qw(
    	10
    	127
    	172.16
    	172.17
    	172.18
    	172.19
    	172.20
    	172.21
    	172.22
    	172.23
    	172.24
    	172.25
    	172.26
    	172.27
    	172.28
    	172.29
    	172.30
    	172.31
    	192.168 )
	];

	return $self;
}

sub test_level {
	my ($self) = shift;
	my ($level) = shift;;

	if ( $level ) {
		return $self->{test_level}->{$level};
	} else {
		return $self->{test_level};
	}
}


sub test_conf {
	my ($self) = shift;
	my (%param) = @_;

	return unless $param{test};

	# We should verify if test exists and if level is one of that supported
	if ($param{level}) {
		$self->{test_configured}->{$param{test}} = uc $param{level};
	} 

	if (defined $self->{test_configured}->{$param{test}} ) {
		return $self->{test_configured}->{$param{test}};
	} 
}


sub AUTOLOAD {
	my ($self) = @_;  

	my ($name) = $AUTOLOAD =~ m/^.*::(.*)$/;

	unless (exists $self->{$name}) {
		Carp::carp(<<"AMEN");

***
***  WARNING!!! Param Doesn't exist 
***  $AUTOLOAD
***

AMEN
		return;
	}

	no strict q/refs/;

	# Build a method in the class.
	*{$AUTOLOAD} = sub {
		my ($self, $new_val) = @_;

		if (defined $new_val) {
			$self->{$name} = $new_val;
		}

		return $self->{$name};
	};

	# And jump over to it.
	goto &{$AUTOLOAD};
}


sub DESTROY {};
1;

__END__

=head1 NAME

Net::DNS::Check::Config - 

=head1 SYNOPSIS

 use Net::DNS::Check::Config;

 my $config = new Net::DNS::Check::Config();
 $config->test_conf( test => 'soa_refresh_range', level => 'I');
 $config->debug(0);


=head1 DESCRIPTION

A Config object is an instance of the Net::DNS::Check::Config class.
With this object you can configure how Net::DNS::Check operates. You can set, for example, which tests will be executed during the check phase, set the debug level and several other options. 

One of the main configurations that you can do with Net::DNS::Check::Config are about which tests will be executed and how to consider "succeeded" or "failed" anwsers from them. For this purpose is important to explain what it means when we talk about "status" or "status level". Every executed tests returns always an answer that can be "true" or "false" or if you prefer "succeeded" or "failed". 
The Net::DNS::Check::Config class define at present 4 different status level that can be associated to "succeeded" or "failed" answer returned from executed tests: OK, E (Error), W (Warning), I (Ignore).

Usually a "succeeded" answer from a test is associated to "OK" status level (you can change this association with "ok_status" function) and the association is made for all tests and is not possibile to set it test by test. 
The status associated to a "failed" answer can be set test by test using "test_conf" function (if don't use "test_conf" function all test inside "test_list" are set to "default_status" status value). 


=head1 METHODS

=head2 new

This method create a new Net::DNS::Check object and returns a reference to it. Arguments are not available. 

	use Net::DNS::Check::Config;

	my $config = new Net::DNS::Check::Config();


=head2 rootservers

With this method you can get or set the ip addresses of the root nameservers used by L<Net::DNS::Resolver::Recurse>. The root nameservers list is stored or returned as an array reference.

	# Get
	print join(' ', @{ $config->rootservers() } );

	# Set
	$config->rootservers([qw( 198.41.0.4 128.9.0.107) ]);


=head2 debug_default

With this method you can get or set the default debug level. You can set the debug level with debug argument of the method "new" of L<Net::DNS::Check> object and if the debug level is not specified the "debug_default" value, of L<Ne::DNS::Check::Config> object, will be used.

At present 4 debug levels are supported:

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

The default value of "debug_default" is 0 (debug disabled).

	# Set
	$config->debug_default(2);

=head2 query_retrans 

Get or set the retransmission interval used in the L<Net::DNS::Resolver> object. The default value is 5.

=head2 query_retry 

Get or set the number of times to try the query in the L<Net::DNS::Resolver>. The default value is 2.

=head2 query_tcp_timeout 

Get or set the default timeout in seconds for TCP queries (L<Net::DNS::Resolver> 
tcp_timeout argument). 

=head2 query_udp_timeout 

Not yet implemented.

=head2 predefined_hosts 

Working in progress.

=head2 test_conf (funzione)

This method is used to set the association for a "failed" answer from a test. This function support two arguments passed as hash: "test" and "level". 
The "test" argument is mandatory and contains the name of the test for which you want set or get the status level information. 
If you omit the "level" argument, this method return the status information about the test specified with the "test" argument.

	# Set the Warning status level for test "soa_expire_range"
	$config->test_conf( test => 'soa_expire_range', level => 'W' ); 

	# Get the status information about the test "soa_refresh_range"
	$config->test_conf( test => 'soa_refresh_range' ); 

=head2 ok_status

Get or set the "good" status. The default "good" status is "OK".

=head2 error_status

Get or set the list of status considered as "not good" or error status. The list is stored or returned as an array reference. The default "not good" status is: "E" (Error).

=head2 default_status

Get or Set the default status for a test. If a status is not specified for a test, the default status is used. The default value is "E" (Error).

=head2 test_list

Get or set the list of all the available tests (sublcass of Net::DNS::Check::Test). The list is stored or returned as an array reference. For additional information about available tests please see L<Net::DNS::Check::Test> class.

	my @list = @{ $config->test_list() };
	push (@list, 'new_test');
	$config->test_list(\@list);

Every test inside the "test_list" are initialized to the "default_status" value. If you want to change the status level of a specific test you must use "test_conf" function: 

	$config->test_list([qw( mx_compare mx_present ns_compare ns_vs_delegated ns_count]);
	# For all this tests a default_status is set.
	# If you want change the status of a specific test use test_conf function.
	# For example this set for "mx_present" test a "warning" (W) level.
	$config->test_conf( test => 'mx_present', level => 'W' );


=head2 test_level

This method is used to query Net::DNS::Check::Conf for supported status levels. It can be used to know either the list of all supported status levels (returned as an hash) or to translate from short status name to long status name (example from "W" to "Warning"). o

	$config->test_level();
	# Return an hash containing the list of all supported status level:
	# 'W' => 'Warning', 'OK' => 'OK', 'E' => 'Error', 'I' => 'Ignore'

	$config->test_level('W');
	# Return 'Warning'


=head2 ns_min_count

Get or set the minimun number of NS RR for the domain you want to check. This number is used in the L<Net::DNS::Check::Test::ns_count> test.  The default value is 2.

	$config->ns_min_coung(3);


=head2 ns_max_count

Get or set the maximum number of NS RR for the domain you want to check. This number is used in the L<Net::DNS::Check::Test::ns_count> test.  The default value is 0, so there is no maximum limit.

	$config->ns_max_count(7);


=head2 soa_min_retry 

Get or set the minimum value required for the retry time in the SOA record. This number is used in the L<Net::DNS::Check::Test::soa_retry_range> test.  The default value is 1800.

=head2 soa_max_retry 

Get or set the maximum value required for the retry time in the SOA record. This number is used in the L<Net::DNS::Check::Test::soa_retry_range> test.  The default value is 28800. A value of 0 disable the maximum limit for the retry time.

=head2 soa_min_refresh 

Get or set the minimum value required for the refresh time in the SOA record. This number is used in the L<Net::DNS::Check::Test::soa_refresh_range> test.  The default value is 1800. 

=head2 soa_max_refresh 

Get or set the minimum value required for the refresh time in the SOA record. This number is used in the L<Net::DNS::Check::Test::soa_refresh_range> test.  The default value is 1800. A value of 0 disable the maximum limit for the refresh time.

=head2 soa_min_expire 

Get or set the minimum value required for the expire time in the SOA record. This number is used in the L<Net::DNS::Check::Test::soa_expire_range> test.  The default value is 86400. 

=head2 soa_max_expire 

Get or set the maximum value required for the expire time in the SOA record. This number is used in the L<Net::DNS::Check::Test::soa_expire_range> test.  The default value is 0 so there is not maximum limit for the expire time.

=head2 ip_private

Get or set the list of the private IP addresses (see RFC1597 ). The list is stored or returned as an array reference. This list is used in the L<Net::DNS::Check::Test::host_ip_private> test. The default values are:

=over 4

10 127 172.16 172.17 172.18 172.19 172.20 172.21 172.22 172.23 172.24 172.25 172.26 172.27 172.28 172.29 172.30 172.31 192.168

=back

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

