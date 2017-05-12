#!/usr/bin/perl
package Net::Connection::Sniffer;

use strict;
#use diagnostics;
#use lib qw(blib lib);
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS @ISA);
require DynaLoader;
require Exporter;

$VERSION = do { my @r = (q$Revision: 0.36 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
	gather
);

@EXPORT_OK = qw(
	INITIALIZE
	SEND_listen
	INIT_wFD
	RECV_dns
	SEND_dns
	PRINT_dumptxt
	CLOSE_wFD
	WAS_PURGE
	TERMINATE
	END_RUN
	LISTEN_MSG
	DNS_NEEDED
	DUMP_REQUEST
	DNS_RECEIVE
	PURGE
	check_config
	set_me
	fetch_uv
	inc_sv
	set_uv
	set_nv
	add_nv
	aEQaPLUSbXm
	p2xs_gvars
	xs2p_gvars
	init_hv
	_purge
	_ptrs
	set_globals
	dns_expire
	lcstr
);

%EXPORT_TAGS = (
	timer		=> [qw(_purge _ptrs dns_expire set_globals)],
	check_config	=> [qw(check_config set_me)],
	math		=> [qw(fetch_uv inc_sv set_uv set_nv add_nv aEQaPLUSbXm)],
	init		=> [qw(p2xs_gvars xs2p_gvars init_hv)],
	constants	=> [qw(	INITIALIZE SEND_listen INIT_wFD SEND_dns PRINT_dumptxt
				CLOSE_wFD WAS_PURGE TERMINATE END_RUN LISTEN_MSG 
				DNS_NEEDED DUMP_REQUEST DNS_RECEIVE PURGE RECV_dns)],
);

use Net::Interface 1.007 qw(:afs);
use NetAddr::IP::Util qw(
	sub128
	inet_aton
	inet_ntoa
	ipanyto6
	maskanyto6
);
use Proc::PidUtil qw(
	if_run_exit
	is_running
	get_script_name
	make_pidfile
	zap_pidfile
);
use Net::DNS::Codes qw(  
	T_PTR
	T_SOA
	C_IN
	BITS_QUERY 
	RD
	NS_PACKETSZ
	HFIXEDSZ
	QUERY
	NOERROR
	NXDOMAIN
	SERVFAIL
);
use Net::DNS::ToolKit qw(
	get16
	getIPv4
	gethead
	newhead
	get_ns
);
use Net::DNS::ToolKit::RR;
#use Net::DNS::ToolKit::Debug qw(
#	print_head
#	print_buf
#);
use Sys::Sig qw(TERM KILL USR1);

bootstrap Net::Connection::Sniffer $VERSION;

# File GLOBAL variables

# define LIBNET_ETH_H	0x0e	/* Ethernet header:	14 bytes */
my $ETH_H = 14;
# define LIBNET_IPV4_H	0x14	/* IPv4 header:		20 bytes */
my $IPV4_H = 20;

#define LIBNET_IPV6_H	0x28	/* IPv6 header:		40 bytes */
#my $IPV6_H = 40;
## define LIBNET_TCP_H	0x14	/* TCP header:		20 bytes */
#my $TCP_H = 20;


#my $addr_off	= $ETH_H + 12;		# src address
#my $frag_off	= $ETH_H + 6;

my $minlen	= $ETH_H + $IPV4_H + 4;	# need port numbers at a minimum
my $snaplen 	= $minlen;

my $oneday	= 86400;			# WARNING, set in XS also
my $unique	= $$ -1;			# dns sequence number
my($match,$nomatch,$payoff);

my $af_inet6 = eval { AF_INET6() };
$af_inet6 = 0 if $@;

#################################################
##### global vars reset by HUP
my ($purge,$nxpurge);

##### global vars used in 'collect', 'dump_stats', elsewhere
#### WARNING, these are set in the XS portion also
my ($now, $start, $rate, $bw);

sub set_gvars {
  $now		= time;
  $start	= $now;
  $rate		= 0;				# global
  $bw		= 0;				# global
  p2xs_gvars($now, $start, $rate, $bw);		# reload xs vars from the module, clear 'hup', 'ra', 'ba'
}

##### global vars used in 'collect' or 'daemon'only
my ($dto);

sub set_globals() {
  set_gvars();
  $purge	= \&setpurge;			# starting purge routine
#  $ra		= 0E0;				# intermediate rate accumulator
#  $ba		= 0E0;				# intermediate bw accumulator
  $nxpurge	= 0;
  $dto		= $now + 15;
}

set_globals;

#my %subref;
#foreach(sort keys %Net::Connection::Sniffer::) {
#  my $subref = \&{"Net::Connection::Sniffer::$_"};
#  $Net::Connection::Sniffer::{$_} =~ /[^:]+$/;
#  $subref{$subref} = $&;
#}

my %dispatch = (
	&LISTEN_MSG	=> \&do_listen,
	&DNS_NEEDED	=> \&dns_send,
	&DUMP_REQUEST	=> \&dump_stats,
	&DNS_RECEIVE	=> \&dns_rcv,
	&PURGE		=> \&timer,
);

my $dnslookup = [];
my $stats = {
#       naddr	=> {
#		B	=> 5678,	# bytes accumulated
#		C	=> 1234,	# counts
#		E	=> 124444,	# count epoch
#		N	=> ['hostname',],	# hostname(s) for this IP
#		R	=> 2345,	# rate
#		S	=> 123456,	# count start time
#		T	=> 123455,	# TTL timeout of PTR record
#		W	=> 7890.	# bandWidth
#       },
};

my $dns = {
#	id	=> {
#		TO	=> 123456,	# timeout time
#		IP	=> ipaddr,	# naddr of this query
#	},
};

sub _ptrs() {
  return ($stats,$dns);
}
sub _purge {
  ($now) = @_;
  goto &$purge;
}

 ###### definitions from xs file ################
 #
 #      vector value indicates the              args
 #      "return from" function    
 #      0       initial entry                   run
 #      1       send to dnsFD                   send buffer
 #      2       send to lFD                     msg || undef, 1 dump else 0 no dump
 #      3       initialize wFD                  undef, 1 dump else 0 no dump (for compatibility)
 #      4       receive from dnsFD
 #      5       print wFD request               print buffer
 #      6       close wFD
 #      7       purge return
 #      8       set run = 0
 #
#define INITIALIZE       0
#define SEND_dns        1
#define SEND_listen     2
#define INIT_wFD        3
#define RECV_dns        4
#define PRINT_dumptxt   5
#define CLOSE_wFD       6
#define WAS_PURGE       7
#define TERMINATE       8

 #
 #      first return value indicates            args
 #      the requested perl run operation
 #      0       end, run is zero
 #      1       listen interrupt                sender.naddr, message received
 #      2       dnslookup                       target array pointer
 #      3       dump request
 #      4       dns receive, len, buffer
 #      5       purge interrupt -- dns alarm is checked here in Perl
 #
#define END_RUN         0
#define LISTEN_MSG      1
#define DNS_NEEDED      2
#define DUMP_REQUEST    3
#define DNS_RECEIVE     4
#define PURGE           5

my (	$len,$kpurge,$ipurge,@keys,$nhost,$err,$run,
	$dtrgt,$sniffer,$dnshost,$dnsaddr,%dhash,
	@dhi,@dlo,$dev,$promisc,$net,$netmask,
	$filter_str,$me,$medam,$iaddr,$port,
	@allowed,
);

=head1 NAME

Net::Connection::Sniffer -- gather stats on network connections

=head1 SYNOPSIS

  use Net::Connection::Sniffer;

  gather($config)

=head1 DESCRIPTION

B<Net::Connection::Sniffer> is a perl module to gather connection
statistics by listening to ethernet traffic. Traffic is filtered using
standard BPF notation as described in the C<tcpdump> documentation and
implemented using the standard C<pcap> library to
sniff packets on host network interfaces.

=head1 CONFIGURATION

Create a directory with appropriate permissions for the pid file and the
profile statistics dump file. Typical installation:

  mkdir -p /var/run/nc.sniffer

Edit the B<nc.sniffer.pl.sample> file to change or set the following:

  my $config = {

  # specify the directory for the pid file for this daemon.
  # The directory must exist and have writable permissions.
  # [required]
  #
        piddir  =>  '/var/run/nc.sniffer',

  # specify the directory for the statistics file for this 
  # daemon. The directory must exist and have writable
  # permissions
  # [required]
  #
        sniffer =>  '/var/run/nc.sniffer',

  # BPF filter statement. See examples below.
  # [required]
  #
        bpf     => 'src host myhost.com and tcp port 80',

  # size of the portion of packet to capture, defaults
  # to the minimum size necessary to determine the
  # source and destination IP addresses and port numbers
  # [optional]		ETH_head + IPV4_head + 4

  #	snaplen	=> 38,

  # filter condition: payload must contain this string.
  # case insensitive match of the payload data to this string. 
  # [optional]

  #	match	=> 'somestring',

  # filter condition: payload must NOT contain this string.
  # case insensitive match of the payload data to this string.
  # [optional]

  #	nomatch	=> 'some.other.string',

  # offset of the payload from the packet start
  # typically at least 60 for tcp, 44 for udp
  # [optional]... but [required] for 'match', 'nomatch'
  #
  #	payload	=> 44,

  # UDP listen port to trigger a dump file
  # [optional]
  #
	port	=> 10004,

  # HOST address on which to listen for dump request
  # may be one of a HOSTNAME, IP address, or
  # strings 'INADDR_ANY', 'INADDR_LOOPBACK'
  # [optional] default 127.0.0.1 == INADDR_LOOPBACK
  #
	host	=> 'INADDR_LOOPBACK',

  # ALLOWED connecting host(s)
  # may be HOSTNAME or IP address
  # [optional] default 127.0.0.1
  #
	allowed	=> ['127.0.0.1',],

  };

To generate a web report to STDOUT with or without a cache file, 
edit the B<nc.sniffer.cgi.sample> file to change
or set the configuration parameters. See
L<Net::Connection::Sniffer::Report>::B<web_report> or the sample file for
details.

  Usage: <!--#exec cmd="./nc.sniffer.cgi 0" -->
    or	 <!--#exec cmd="./nc.sniffer.cgi 1" -->

where an argument of "0" produces a report ordered by /24 by usage and an
argument of "1" produces a report ordered by subdomain by usage.

=head1 REMOTE CONFIGURATION, multiple hosts

To configure the reporting function to retrieve statistics from multiple
remote hosts (and localhost) do the following:

        1) read the config section of
           nc.sniffer.coalesce.cgi.sample
        2) read the config section of
           nc.sniffer.dump.pl.sample 

On the remote host(s), install nc.sniffer.dump.pl in an appropriate sandbox
account and install an ssh certificate to permit access to the sandbox ssh
executable as well as the directory from which to rsync the stats file on 
that host.

nc.sniffer.dump.pl should be installed
mode 755 or as appropriate to be accessed remotely by
the ssh -e function.

On the web host, configure nc.sniffer.coalesce.cgi and place the execution
cgi string in your web page to produce the report

nc.sniffer.coalesce.cgi should be SUID to the web user, not root, so that
the web engine can safely execute the script. The ssh certificate must be
generated for the web user and go in the nobody:nogroup/.ssh directory 
(or equivalent web user directory).

  usage: <!--#exec cmd="./nc.sniffer.coalesce.cgi" -->

=head1 OPERATION

Launch the daemon with the command:

	nc.sniffer.pl start

  Syntax: nc.sniffer.pl start
	  nc.sniffer.pl stop
	  nc.sniffer.pl restart
	  nc.sniffer.pl status
	  nc.sniffer.pl dump
	  nc.sniffer.pl config

	  -d switch may be added to
	   redirect output to STDERR

On most systems it will be necessary to wrap a shell script around
nc.sniffer.pl if the path for perl is not in scope during boot.

  #!/bin/sh
  #
  # shell script 'rc.nc.sniffer'
  #
  /path/to/nc.sniffer.pl $*

A sample shell script is included in the distribution as B<rc.nc.sniffer>

To run multiple copies of nc.sniffer for data collection on various ports
or IP's at the same time, name them:

	nc.sniffer1.pl
	nc.sniffer2.pl
	etc...

  start		start daemon if not running, write pid file
  stop		stop a running daemon
  restart	do stop, then start
  status	report if daemon running or not
  dump		refresh/write statistics file
  config	print configuration to STDOUT

=head1 SIGNALS

The statistics information will be written to the file specified in the
configuration upon receipt of a SIG USR1

	SIG	TERM		write stats file, terminate
	SIG	HUP		write stats file, start over
	SIG	USR1		write statistics file

=head1 UDP listener -- statistics file dump

If the nc.sniffer daemon is configured for a UDP listen port, sending a
message B<dump> will produce the same result as B<SIG USR1>. The daemon will
respond B<OK timestamp>, but this is NOT syncronized with the file dump and
only indicates that the statistics file should not have a timestamp earlier
that the epoch value returned. When either a B<dump> or B<SIG USR1> is issued,
you must check the ctime of the file to determine if it has been updated.

=head1 BUGS / RESTRICTIONS

B<Net::Connection::Sniffer> uses B<libpcap>.
The data collection is accomplished using a selectable capture device which is NOT
SUPPORTED on Windows and some older BSD platforms. The next two paragraphs are from the pcap library
and describe the platform limitations.

Some C<BPF> ...devices do not support select() or poll() 
(for example, regular network devices on FreeBSD 4.3 and 4.4, and 
Endace DAG devices)...

...On most versions of most BSDs (including Mac OS X), select()
and poll() do not work correctly on BPF devices. C<While a BPF file descriptor
will be returned>  ...on most of those versions (the exceptions being 
FreeBSD 4.3 and 4.4), a simple select() or poll() will not
return even after a... C<specified timeout> expires...
...In FreeBSD 4.6 and later, select() and poll() work correctly on BPF
devices...

=head1 EXAMPLES

=head2 BPF examples

The B<bpf> entry in the configuration hash uses the standard language
documented in detail in the B<tcpdump> man(1) page. The B<bpf> statement
must contain at a minimum, 'host somename [or IP address]'. The host
specification must be for a single unique IP address and be the first such
specification if there are multiple src/dest host specifications in the
statment.

Capture all traffic to/from a particular host:

  bpf	=> 'host particular.host.com',

Capture traffic to/from your mail server:

  bpf	=> 'host my.mx.com and tcp port 25',

Capture request traffic arriving at your DNS server:

  bpf	=> 'dst host my.dns.com and udp port 53',

Capture response traffic leaving your DNS server:

  bpf	=> 'src host my.dns.com and udp port 53',

=head2 Content MATCH/NOMATCH examples

The B<match> and B<nomatch> configuration entries can be used to further discriminate
which packets to sniff. When the B<match> entry is set, only packets which meet the
BPF criteria AND have matching data within the packet capture buffer are selected for
analysis. Conversely, when the B<nomatch> entry is set, packets which meet the BPF criteria
and match the B<nomatch> string are unconditionally dropped. B<match> and B<nomatch> may 
both be set.

NOTE: that matches are made on a case insensitive basis.

Capture request traffic arriving at the DNS port with a query for
C<somedomain.com>. From RFC1035, we know that a datagram might
need to use the domain names F.ISI.ARPA,
FOO.F.ISI.ARPA, ARPA, and the root.  Ignoring the other fields of the
message, these domain names might be represented as:

       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    20 |      decimal 1        |           F           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    22 |      decimal 3        |           I           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    24 |           S           |           I           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    26 |      decimal 4        |           A           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    28 |           R           |           P           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    30 |           A           |           0           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    40 |      decmial 3        |           F           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    42 |           O           |           O           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    44 | 1  1|            decimal 20                   |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    64 | 1  1|            decimal 26                   |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    92 |      decimal 0        |                       |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

Our examples B<somedomain.com> would be represented in the datagram
as follows:

       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    20 |      decimal 10       |           s           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    22 |           o           |           m           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    24 |           e           |           d           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    26 |           o           |           m           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    28 |           a           |           i           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    30 |           n           |      decimal 3        |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+             
    30 |           c           |           o           |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+             
    30 |           m           |      decimal 0        |
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+             

This translates to the perl string:

	where 10 becomes hex \x{a}

  $string = "\x{a}somedomain\x{3}com"

The offset of the query QUESTION is:

  ETH header	16
  IP header	20
  UDP header	8
  Query head	12
		--
		54

and the snaplen needs to be long enough to alway capture the domain name.
There, our example configuration becomes:

  bpf	  => 'dst host my.dns.com and udp port 53',
  match	  => "\x{a}somedomain\x{3}com",
  snaplen => 90,
	# eth head + ip head + udp head + query head
  payload => 54,

=head1 DUMP FILE FORMAT

The dump file is written in a format compatible with that produced by
B<Data::Dumper>. It may be imported for analysis using Perl's 'do' or by
using B<File::SafeDO>.

  # start:	  1145923212,     Mon Apr 24 17:00:12 2006
  # current:      1145923334,     Mon Apr 24 17:02:14 2006
  # hits:         3832 per minute
  # bytes:        5927 per second
  # users:	  1234 users now
  # device:       eth1:1  non-promiscuous
  # bpf:          dst host my.host.com
  # [optional if match/nomatch present]
  # fragment:	nn -- mm
  # contains:	match.string
  # excludes:	nomatch.string
  {
    my $dump = {
       '69.3.95.131'     => {
                B       => 240,
                C       => 4,
                E       => 1145760699,
		N	=> ['hostname1','hostname2','...'],
                R       => 723,
                S       => 1145757331,
		T	=> 1145790478,
                W       => 43359,
        },
  }

=over 4

=item * start:

The start time of this data collection in seconds since the epoch and local
time.

=item * current:

The time the file was written in seconds since the epoch and local time.

=item * hits:

The connections per minute collected by this filter configuration.

=item * bytes:

The bandwidth in bytes per second collected by this filter configuration.

=item * users:

The total number of discreet hosts logged at this instant

=item * device:

The network device being sniffed and whether or not the device is in
promiscuous mode.

=item * bpf:

The bpf statment used for data collection

=item * value hash pointer for one or more IP addresses.

Time values are seconds since the epoch.

  Hash pointer = {

      IP address => {
	  B	=> incremental byte count
	  C	=> incremental connection count
	  E	=> last update time
	  N	=> ['hostname1','hostname2','...'],
	  R	=> connections / hour
	  S	=> start time this data set
	  T	=> TTL expiration for hostname
	  W	=> bytes / hour
      },

      next IP address => {
	...

NOTE: if the hostname lookup results in an NXDOMAIN return, the hostname
will be parsed from the SOA record and presented prefixed with a colon

  i.e.	':soahost.com'

=back

=head1 EXPORTS

Only one function is exported by Sniffer.pm. This function is called in the
nc.sniffer.pl.sample script to launch the B<nc.sniffer> daemon.

=over 4

=item gather($config);

Launch the nc.sniffer daemon.

  input:	config hash
  returns:	nothing (exits)

=back

=cut

sub gather  {
  die "arg 1 of gather must be a hash\n"
	unless ref $_[0] eq 'HASH';
  my $pidfile = &check_run;	# check for another running daemon
  &check_config;		# verify that config array is correct and populated
  clean_child();  		# double fork a child
  make_pidfile($pidfile,$$)
	or die "could not make pidfile '$pidfile' for $$\n";
  @_ = ();
  goto &daemon;
}

sub usage {	# tested by hand
  $me = $0 unless $me;
  print STDERR $_[0],"\n" if $_[0];
  print STDERR qq|
Syntax:	$me start
	$me stop
	$me restart
	$me status
	$me dump
	$me config

	-d switch may be added to
	   redirect output to STDERR

|;
  exit 1;
}

sub kill_job {
  my($pidfile) = @_;
  my $pid = is_running($pidfile);
  if ($pid) {
    kill &TERM, $pid;
    eval {
	local $SIG{ALRM} = sub {die "waitpid timeout"};
	alarm 15;
	waitpid($pid,0);
	alarm 0;
    };
    if ($@) {
      kill &KILL, $pid;
      sleep 1;
    }
  } else {
    print STDERR "$me: not running\n";
  }
}

sub bad_config {
  my($msg) = @_;
  print STDERR 'config: ',$msg,"\n";
  exit 1;
}

sub set_me {
  $me = get_script_name();
  $medam = ($me =~ /\.pl$/)
	? $`
	: $me;
  $0 = $medam;
}

# returns $pidfile if successful or exits
#
sub check_run {
  my($c) = @_;
  unless ($c->{piddir} && -d $c->{piddir} && -w $c->{piddir}) {
    print STDERR "pid directory not specified or not writable\n";
    exit 0;
  }
  set_me();
  usage('missing command argument(s)') if
	(grep($_ eq '-d',@ARGV) && @ARGV < 2) ||
	@ARGV < 1;

  if (grep($_ eq '-d',@ARGV)) {
    usage('to many command arguments')
	if @ARGV > 2;
  }
  else {
    usage('to many command arguments')
	if @ARGV > 1;
  }

  my $pidfile = $c->{piddir} .'/'. $medam .'.pid';
  foreach(@ARGV) {
    if ($_ eq 'start') {
      if_run_exit($c->{piddir},"already running\n");
    }
    elsif ($_ eq 'stop') {
      kill_job($pidfile);
      exit 0;
    }
    elsif ($_ eq 'restart') {
      kill_job($pidfile);
    }
    elsif ($_ eq 'status') {
      my $pid = is_running($pidfile);
      if ($pid) {
	print STDERR "$pid $medam is running\n";
      } else {
	print STDERR "$medam not running\n";
      }
      exit 0;
    }
    elsif ( $_ eq 'dump' ) {
      my $pid = is_running($pidfile);
      if ($pid) {
	kill &USR1, $pid;
      } else {
	print STDERR "$medam not running\n";
      }
      exit 0;
    }
    elsif ( $_ eq '-d' ) {
      $c->{sniffer} = 'STDERR',
    }
    elsif ( $_ eq 'config' ) {
      print 'my $config = {';
      foreach (sort keys %{$_[0]}) {
	if (ref $_[0]->{$_}) {
	  print "\n\t$_\t=> [";
	  foreach my $ar (@{$_[0]->{$_}}) {
	    print " '$ar',";
	  }
	  print ' ],';
	} else {
	  print "\n\t$_\t=> '$_[0]->{$_}',";
	}
      }
      print "\n};\n";
      exit 0;
    }
    else {
      usage("unknown command argument '$_'\n");
    }
  }
  return $pidfile;
}

### validate and set configuration defaults
#
# set: $nhost, $dev, $promis
#
sub check_config {
# BPF
  my($c) = @_;
  unless (($filter_str = $c->{bpf}) && $filter_str =~ /host\s+([\w.-]+)/i) {
    bad_config('missing hostname in bpf string');
  }
  else {
    bad_config("bad hostname '$1' in bpf filter string")
	unless ($nhost = inet_aton($1));
    ($dev,$promisc) = get_if($nhost);
    bad_config("could not find interface for '$1' in bpf string")
	unless $dev;
  }
# sniffer directory
  unless ($sniffer = $c->{sniffer} || '') {
    bad_config('sniffer directory missing from configuration');
  }
  unless ($sniffer eq 'STDERR') {
    bad_config("sniffer directory '$sniffer' missing or not writable")
	unless ($sniffer && -d $sniffer && -w $sniffer);
# sniffer file
    $sniffer .= '/'. $medam .'.stats';
    if (-e $sniffer) {
      bad_config("'$sniffer' not writable")
	unless -w $sniffer;
    }
  }
# snaplen
  $snaplen = $c->{snaplen}
	if $c->{snaplen};
  $snaplen = 65535 if $snaplen > 65535;
# payload, match/nomatch
  $match = $c->{match} ? lc $c->{match} : undef;
  $nomatch = $c->{nomatch} ? lc $c->{nomatch} : undef;
  $payoff = $c->{payload};
  if ($match || $nomatch) {
    bad_config("invalid payload length")
	unless $payoff && $payoff < $snaplen;
  }

# UDP dump port
  if ($port = $c->{port}) {
    bad_config("invalid port number '$c->{port}'")
	unless $port =~ /\d/ && $port !~ /\D/;
    if ($iaddr = $c->{host}) {
      if ($iaddr eq 'INADDR_LOOPBACK') {
	$iaddr = '127.0.0.1';
      }
      elsif ($iaddr eq 'INADDR_ANY') {
	$iaddr = '0.0.0.0';
      }
    } else {
      $c->{host} = $iaddr = '127.0.0.1';
    }
    bad_config("bad dump host '$c->{host}'")
	unless defined ($iaddr = inet_aton($iaddr));
    if ($c->{allowed} && @{$c->{allowed}}) {
      foreach (0..$#{$c->{allowed}}) {
	my $con = inet_aton($c->{allowed}->[$_]);
	bad_config("invalid 'allowed' host or IP '". $c->{allowed}->[$_] ."'")
		unless $con;
	push @allowed, $con;
      }
    } else {
      push @allowed, inet_aton('127.0.0.1');
    }
  }
}

sub clean_child() {
  my $pid = fork;
  if ($pid) {
    waitpid($pid,0);
    exit 0;
  }

  chdir '/';			# allow root dismount
  open STDIN, '/dev/null' or die "Can't dup STDIN to /dev/null: $!";
  open STDOUT, '>/dev/null' or die "Can't dup STDOUT to /dev/null: $!";
#open(STDOUT,">&STDERR");
#select STDERR;
#$| = 1;
#select STDOUT;
#$| = 1;
  exit 0 if $pid = fork;	# double fork to release instantiating terminal
}

#
# input:	ipv4 or ipv6 network address
# returns:	interface,
#		need promiscious [t/f]

sub get_if($) {
  my $naddr = ipanyto6(shift);
  my %net;
  my @ifs = interfaces Net::Interface ();
IF:
  foreach my $if (@ifs) {
    my @addrs = $if->address(AF_INET());
    my @netms = $if->netmask(AF_INET());
    if ($af_inet6) {
      push @addrs, $if->address($af_inet6);
      push @netms, $if->netmask($af_inet6);
    }
    foreach (0..$#addrs) {
      my $iddr = ipanyto6($addrs[$_]);
      my $name = $if->name();
      if ($naddr eq $iddr) {
	$match = $name;
	last IF;
      }
      my $mask = maskanyto6($netms[$_]);
      my $net = $iddr & $mask;
      my $bcst = $iddr | ~$mask;
      $name = $1 if $name =~ /(.+)\:/;			# for linux, fix aliases
      $net{$name} = $iddr
	if sub128($naddr,$net) && sub128($bcst,$naddr);	# within CIDR
    }
  }
  @_ = sort keys %net;
  my $pmsc = @_;
  if (!$match && $pmsc) {
    $match = shift @_;
  }
  return (wantarray)
	? ($match,$pmsc)
	: $match;
}

#			  ETHERNET HEADER
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |       Ethernet destination address (first 32 bits)            |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# | Ethernet dest (last 16 bits)  |Ethernet source (first 16 bits)|
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |       Ethernet source address (last 32 bits)                  |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |        Type code              |                               |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |  IP header, then TCP header, then your data                   |
# |                                                               |
#     ...
# |                                                               |
# |   end of your data                                            |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |                       Ethernet Checksum                       |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

#			      IPV4 HEADER
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |Version|  IHL  |Type of Service|          Total Length         |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |         Identification        |Flags|      Fragment Offset    |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |  Time to Live |    Protocol   |         Header Checksum       |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |                       Source Address                          |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |                    Destination Address                        |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

#			     TCP HEADER
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#    0                   1                   2                   3   
#    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |          Source Port          |       Destination Port        |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |                        Sequence Number                        |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |                    Acknowledgment Number                      |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |  Data |           |U|A|P|R|S|F|                               |
# | Offset| Reserved  |R|C|S|S|Y|I|            Window             |
# |       |           |G|K|H|T|N|N|                               |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |           Checksum            |         Urgent Pointer        |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |                    Options                    |    Padding    |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |                             data                              |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

#			      UDP HEADER
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#    0                   1                   2                   3  
#    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |          Source Port          |       Destination Port        |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |            Length             |          Checksum             |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

sub setpurge() {
  return undef if $nxpurge && $nxpurge > $now;# setup if '0'
  $kpurge = @keys = sort keys %$stats;	# set purge values and count
  $ipurge = 0;				# set starting purge index
  $nxpurge = time + $oneday;
  $purge = \&dopurge;
}

sub dopurge() {
  return unless @keys;
  my $key = $keys[$ipurge];			# get key value
  if ($stats->{$key}->{E} + $oneday < $now) {	# if last epoch is more than a day old
    delete $stats->{$key};			# delete the entry
  }
  $purge = \&setpurge
	unless ++$ipurge < $kpurge;
}

sub dns_expire {
  ($now) = @_;
  my @dnsthreads = sort keys %$dns;
  foreach(@dnsthreads) {
    if ($dns->{$_}->{TO} < $now) {
      delete $dns->{$_};				# delete expired dns threads
    }
  }
  return $now + 15;
}

sub timer {
  ($now,my $dump) = @_;
  return(&INIT_wFD,"",1) if $dump;
  $dto = dns_expire($now)
	if $dto < $now;
  &$purge;
  return (&WAS_PURGE);
}

# unescape 'escape' characters
# in the form \x{hex}
#
sub sunescape {
  my @string = split('',$_[0]);
  foreach(0..$#string) {
    my $o = ord $string[$_];
    if ($o < 0x20 ||
        $o > 0xfe ||
        ($o > 0x7e && $o < 0xa8)) {
      $string[$_] = sprintf("\\x{%x}",$o);
    }
  }
  join('',@string);
}

sub dump_stats {
  my($hup,$init) = @_;
  if ($init) {
    unless (@dhi = sort keys %{$stats}) {
      return(&TERMINATE) if $hup < 0;
      set_globals() if $hup > 0;	# re-init globals
      return(&CLOSE_wFD);
    }
    ($now,$start,$rate,$bw) = xs2p_gvars();	# get vars from xs
#print STDERR "now=$now, start=$start, rate=$rate, bw=$bw\n";
    @dlo = ();
    $init = time;
    $init =	"\n# ". __PACKAGE__ . " version $VERSION".
	 	"\n# start:\t$start,\t". (scalar localtime($start)) .		
		"\n# current:\t$init,\t".  (scalar localtime($init)) .
	sprintf("\n# hits:\t\t%.0f per minute",$rate /60).
	sprintf("\n# bytes:\t%.0f per second",$bw /3600).
		"\n# users:\t". (scalar keys %$stats).
		"\n# device:\t$dev\t". (($promisc) ? 'promiscuous':'non-promiscuous') .
		"\n# bpf:\t\t$filter_str";
    if ($match || $nomatch) {
      $init .= 	"\n# fragment:\t$payoff - $snaplen";
      if ($match) {
	$init .="\n# contains:\t". sunescape($match);
      }
      if ($nomatch) {
	$init .="\n# excludes:\t". sunescape($nomatch);
      }
    }
    $init .= 	"\n{\n  my \$dump = {\n";
    return(&PRINT_dumptxt,$init);
  }
  unless (@dlo) {
    while ($dtrgt = shift @dhi) {
      last if exists $stats->{$dtrgt};	# skip deleted entries
    }
    unless ($dtrgt) {
      %dhash = ();		# minimize
      return(&TERMINATE) if $hup < 0;
      if ($hup > 0) {
	%$stats = ();
	set_globals;		# re-init globals
      }
      return(&CLOSE_wFD);	# done
    }
    %dhash = %{$stats->{$dtrgt}};		# static values during dump
    @dlo = sort keys %dhash;
    my $ip = inet_ntoa($dtrgt);
    $ip = (length($ip) > 13)
	? $ip . "' "
	: $ip . "'\t";
    return(&PRINT_dumptxt,"\t'". $ip ."=> {\n");
  }
  my $key = shift @dlo;
  my $txt;
  if ($key eq 'N') {
    $txt = "\t\t$key\t=> [";
    foreach(@{$dhash{$key}}) {
      $txt .= "'$_',";
    }
    $txt .= "],\n";
  } else {
    $txt = sprintf("\t\t%s\t=> %.0f,\n",$key,$dhash{$key});
  }
  unless (@dlo) {
    if (@dhi) {
      $txt .= "\t},\n";
    } else {
      $txt .= "\t},\n  };\n}\n";
    }
  }
  return(&PRINT_dumptxt,$txt);
}

sub get_unique {
  my($seed) = @_;
  $unique = $seed if $seed; 
  $unique = 1 if ++$unique > 65535;
  return $unique;	# return an ascending number or the PID if just invoked
}

sub dns_send {		# tested by hand
  my $naddr = shift @$dnslookup;
  $stats->{$naddr}->{T} = time + $oneday;	# retry in a day if no answer
#print STDERR "dns_send, ", $stats->{$naddr}->{T},"\n";
  my @ip = split(/\./,inet_ntoa($naddr));
  @_ = reverse @ip;
  my $name =  join('.',@_,'in-addr.arpa');
  my $id = get_unique();
  my $buffer;
  my $offset = newhead(\$buffer,
	$id,
	BITS_QUERY | RD,		# query, recursion desired
	1,0,0,0,			# one question
  );
  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
  $offset = $put->Question(\$buffer,$offset,$name,T_PTR,C_IN);
  return unless $buffer;
  $dns->{$id} = {
	TO	=> time + 300,		# DNS timeout is 5 minutes
	IP	=> $naddr,
  };
# UDP may not block
  return(&SEND_dns,$buffer);
}

sub dns_rcv {		# tested by hand
#print STDERR "dns_rcv: ";
  my($len,$msg) = @_;
  return (&RECV_dns) if $len < HFIXEDSZ;			# short message
  my ($off,$id,$qr,$opcode,$aa,$tc,$rd,$raa,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$msg);

  return (&RECV_dns) unless
	$tc == 0 &&
	$qr == 1 &&
	$opcode == QUERY &&
	$qdcount == 1 &&
	$rcode != SERVFAIL &&
	(($rcode == NOERROR && $ancount > 0) || ($rcode == NXDOMAIN && $nscount > 0)) &&
#	$opcode == QUERY &&
#	($rcode == NOERROR || $rcode == NXDOMAIN || $rcode == SERVFAIL) &&
#	$qdcount == 1 &&
#	$ancount > 0 &&
	exists $dns->{$id};
  my $naddr = $dns->{$id}->{IP};				# originating thread
  delete $dns->{$id};						# remove dns query thread
  return (&RECV_dns)
	unless exists $stats->{$naddr};
  return (&RECV_dns) unless $len > HFIXEDSZ;		# no message
  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
  my($name,$t,$type,$class,$ttl,$rdl,@rdata);
  ($off,$name,$type,$class) = $get->Question(\$msg,$off);
  my @answers;
  return (&RECV_dns) unless
	$type == T_PTR &&
	$class == C_IN;
  if ($rcode == &NOERROR) {
    foreach(0..$ancount -1) {
      ($off,$name,$t,$class,$ttl,$rdl,@rdata) = $get->next(\$msg,$off);

      if ($t == T_PTR) {
	push @answers,@rdata;
      }
    }
  }
  elsif ($rcode == &NXDOMAIN) {
    foreach(0..($ancount -1)) {
      $get->next(\$msg,$off);					# flush any answers and NS records
    }
    foreach(0..$nscount -1) {
      my $mname;
      ($off,$name,$t,$class,$ttl,$rdl,$mname,@rdata) = $get->next(\$msg,$off);
      if ($t == T_SOA) {
	push @answers, ':'. $mname;
	last;
      }
    }
  }
  if (@answers) {
    $stats->{$naddr}->{T} = time + $ttl;		# use last ttl retrieved
    @_ = grep($_ !~ /in-addr.arpa/i,@answers);  
    @_ = @answers unless @_;
    @{$stats->{$naddr}->{N}} = @_;
#print STDERR $stats->{$naddr}->{T}," @_";
  }
#print STDERR "\n";
  return (&RECV_dns);
}

# enter with timeout in seconds or '0' for normal operation
#
sub daemon {
  $run = shift || -1;
  die "could not get local dns host\n"
	unless $dnshost = get_ns();
  xs_daemon_init($sniffer,$stats,$dnslookup,$nhost,$dnshost,$port,$iaddr,$filter_str,$dev,$snaplen,$promisc,0);
  match_init($match,$nomatch,$payoff,$snaplen);
  if ($sniffer ne 'STDERR') {
    open STDERR, '>/dev/null' or die "Can't dup STDERR to /dev/null: $!";
  }
  my @args = (&INITIALIZE,$run);
  my $function = 1;
  while (1) {
    ($function,@args) = xs_while(@args);
    last unless exists $dispatch{$function};
#print STDERR $subref{$dispatch{$function}},"\n";
    @args = $dispatch{$function}->(@args);
  }
}

sub do_listen {
  ($now,my($sender,$msg)) = @_;
  return (&SEND_listen,undef,0) unless grep($sender,@allowed);
  $msg = ' '. $msg;				# always a string, even if crap
  if ($msg =~ /^ dump/) {
    return(&SEND_listen,'OK '. $now,1);
  } else {
    return(&SEND_listen,'??',0);
  }
}

=head1 PREREQUISITES

The C<pcap> library (C<libpcap>) which is part of C<tcpdump> and is
included in most *nix distributions. Available from:

  http://sourceforge.net/projects/libpcap/

L<NetAddr::IP::Util> which is part of distribution L<NetAddr::IP>

L<Net::Interface>

L<Net::DNS::Codes>

L<Net::DNS::ToolKit>

L<Net::NBsocket>

L<Proc::PidUtil>

L<Sys::Hostname::FQDN>

L<Sys::Sig>

=head1 BUGS

There is a memory leak when run under Perl 5.0503 that has not yielded to debug
attempts. This leak is not present in Perl 5.0601. Not tested in other
versions. From reading through the Changes file for the transition between
versions 5.005 and 5.6, I'm reasonably sure it is a scalar leak in Perl
itself that was corrected with the updates to 5.6. 

My recommend fix for now when running with Perl versions older than 5.6 is
to restart the daemon daily to prevent excessive memory consumption.

=head1 COPYRIGHT 2004 - 2014

Michael Robinton <michael@bizsystems.com>

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the

        Free Software Foundation, Inc.
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA

or visit their web page on the internet at:

        http://www.gnu.org/copyleft/gpl.html.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 SEE ALSO

	man (1) tcpdump
	man (3) pcap

L<Net::Connection::Sniffer::Report>

=cut

1;
