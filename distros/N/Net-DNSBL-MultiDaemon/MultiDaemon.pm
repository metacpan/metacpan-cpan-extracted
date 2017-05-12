#!/usr/bin/perl
package Net::DNSBL::MultiDaemon;

use strict;
#use diagnostics;

use vars qw(
	$VERSION @ISA @EXPORT_OK %EXPORT_TAGS *R_Sin
	$D_CLRRUN $D_SHRTHD $D_TIMONLY $D_QRESP $D_NOTME $D_ANSTOP $D_VERBOSE
);
require Exporter;
@ISA = qw(Exporter);

# DEBUG is a set of semaphores
$D_CLRRUN    = 0x1;  # clear run flag and force unconditional return
$D_SHRTHD    = 0x2;  # return short header message
$D_TIMONLY   = 0x4;  # exit at end of timer section
$D_QRESP     = 0x8;  # return query response message
$D_NOTME     = 0x10; # return received response not for me
$D_ANSTOP    = 0x20; # clear run OK flag if ANSWER present
$D_VERBOSE   = 0x40; # verbose debug statements to STDERR

$VERSION = do { my @r = (q$Revision: 0.39 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
        run
        bl_lookup  
	set_extension
);
%EXPORT_TAGS = (
	debug	=> [qw($D_CLRRUN $D_SHRTHD $D_TIMONLY $D_QRESP $D_NOTME $D_ANSTOP $D_VERBOSE uniqueID)],
);
Exporter::export_ok_tags('debug');

my $FATans = 0;		# this causes a response size overflow from some DNSBLS that have
			# many mirrors, so only the local host authority record is returned

sub fatreturn { return $FATans };	# for testing

my $eXT = undef;	# extension code for "Private Use" as defined in outlined in RFC-6195
			# Query types
			# Classes
			# Types

use Socket;
use Net::DNS::Codes qw(
	TypeTxt
	T_A
	T_AAAA
	T_ANY
	T_MX
	T_CNAME
	T_NS
	T_TXT
	T_SOA
	T_AXFR
	T_PTR
	C_IN
	PACKETSZ
	HFIXEDSZ
	QUERY
	NOTIMP
	FORMERR
	NOERROR
	REFUSED
	NXDOMAIN
	SERVFAIL
	BITS_QUERY
	RD
	QR
	CD
);
use Net::DNS::ToolKit 0.16 qw(
	newhead
	gethead
	get_ns
);
use Net::DNS::ToolKit::RR;
#use Net::DNS::ToolKit::Debug qw(
#	print_head
#	print_buf
#);

#use Data::Dumper;

use Net::DNSBL::Utilities 0.07 qw(
        s_response 
        not_found  
	write_stats
	statinit
	A1271
	A1272
	A1274
	A1275
	A1276
	A1277
	list2NetAddr
	matchNetAddr
	setAUTH
	setRA
);

# target for queries about DNSBL zones, create once per session
# this is a global so it can be altered during testing
*R_Sin = \scalar sockaddr_in(53,scalar get_ns());

=head1 NAME

Net::DNSBL::MultiDaemon - multi DNSBL prioritization

=head1 SYNOPSIS

  use Net::DNSBL::MultiDaemon qw(
	:debug
        run
        bl_lookup  
	set_extension
  );

  run($BLzone,$L,$R,$DNSBL,$STATs,$Run,$Sfile,$StatStamp,$DEBUG)
  bl_lookup($put,$mp,$rtp,$sinaddr,$alarm,$rid,$id,$rip,$type,$zone,@blist);

=head1 DESCRIPTION

B<Net::DNSBL::MultiDaemon> is the Perl module that implements the B<multi_dnsbl>
daemon.

B<multi_dnsbl> is a DNS emulator daemon that increases the efficacy of DNSBL
look-ups in a mail system. B<multi_dnsbl> may be used as a stand-alone DNSBL
or as a plug-in for a standard BIND 9 installation. 
B<multi_dnsbl> shares a common configuration file format with the
Mail::SpamCannibal sc_BLcheck.pl script so that DNSBL's can be maintained in
a common configuration file for an entire mail installation.

Because DNSBL usefulness is dependent on the nature and source of spam sent to a
specific site and because sometimes DNSBL's may provide intermittant
service, B<multi_dnsbl> interrogates them sorted in the order of B<greatest
successful hits>. DNSBL's that do not respond within the configured timeout
period are not interrogated at all after 6 consecutive failures, and
thereafter will be retried not more often than once every hour until they
come back online. This eliminates the need to place DNSBL's in a particular order in
your MTA's config file or periodically monitor the DNSBL statistics and/or update
the MTA config file.

In addition to optimizing DNSBL interrogation, B<multi_dnsbl> may be
configured to locally accept or reject specified IP's, IP ranges and to
reject specified countries by 2 character country code. By adding a DNSBL
entry of B<in-addr.arpa>, IP's will be rejected that do not return some kind
of valid reverse DNS lookup. In addition, IP's can be rejected that have a
PTR record that matchs a configurable GENERIC 'regexp' set.

Reject codes are as follows:

  query 2.0.0.127.{zonename}	127.0.0.2
  blocked by configured DNSBL	127.0.0.2
  no reverse DNS		127.0.0.4
  BLOCKED (local blacklist) 	127.0.0.5
  Blocked by Country		127.0.0.6
  Blocked GENERIC		127.0.0.7

=head1 OPERATION

The configuration file for B<multi_dnsbl> contains optional IGNORE (always
pass), optional BLOCK (always reject), and optional BBC (block by country) entries against
which all received queries are checked before external DNSBL's are queried.
IP's which pass IGNORE, BLOCK, and BBC test are then checked against the
prioritized list of DNSBL's to try when looking up an IP address for blacklisting. 
Internally, B<multi_dnsbl> maintains this list in sorted order (including
'in-addr.arpa') based on the number of responses that
resulted in an acceptable A record being returned from the DNSBL query. For
each IP address query sent to B<multi_dnsbl>, a query is sent to each
configured DNSBL sequentially until all DNSBL's have been queried or an
acceptable A record is returned.

Let us say for example that blackholes.easynet.nl (below) will return an A record
and list.dsbl.org, bl.spamcop.net, dynablock.easynet.nl, will not.

		LIST
	9451    list.dsbl.org
	6516    bl.spamcop.net
	2350    dynablock.easynet.nl
	575     blackholes.easynet.nl
	327     cbl.abuseat.org
	309     dnsbl.sorbs.net
	195     dnsbl.njabl.org
	167     sbl.spamhaus.org
	22      spews.dnsbl.net.au
	6       relays.ordb.org
	1       proxies.blackholes.easynet.nl
	0       dsbl.org

A query to B<multi_dnsbl> (pseudo.dnsbl in this example) looks like this

  	QUERY
  1.2.3.4.pseudo.dnsbl
	  |
	  V
  ####################
  #    multi_dnsbl   #
  ####################
   |				      RESPONSE
   +--> 1.2.3.4.list.dsbl.org	      NXDOMAIN
   |
   +--> 1.2.3.4.bl.spamcop.net	      NXDOMAIN
   |
   +--> 1.2.3.4.dynablock.easynet.nl  NXDOMAIN
   |
   +--> 1.2.3.4.blackholes.easynet.nl A-127.0.0.2

The A record is returned to originator of the Query and the statistics count
on blackholes.easynet.nl is incremented by one.

=head1 INSTALLATION / CONFIGURATION / OPERATION

B<multi_dnsbl> can be installed as either a standalone DNSBL or as a plug-in
to a BIND 9 installation on the same host. In either case, copy the
rc.multi_daemon script to the appropriate startup directory on your host and
modify the start, stop, restart scripts as required. Operation of the script
is as follows:

  Syntax: ./rc.multi_dnsbl start    /path/to/config.file
          ./rc.multi_dnsbl start -v /path/to/config.file
          ./rc.multi_dnsbl stop     /path/to/config.file
          ./rc.multi_dnsbl restart  /path/to/config.file

  The -v switch will print the scripts 
  actions verbosely to the STDERR.

=head2 CONFIGURATION FILE

The configuration file for B<multi_dnsbl> shares a common format with the
Mail::SpamCannibal sc_BLcheck.pl script, facilitating common maintenance of
DNSBL's for your MTA installation. 

The sample configuration file
B<multi_dnsbl.conf.sample> is heavily commented with the details for each
configuration element. If you plan to use a common configuration file in a
SpamCannibal installation, simply add the following elements to the
B<sc_BlackList.conf> file:

  MDstatfile     => '/path/to/statistics/file.txt',
  MDpidpath      => '/path/to/pidfiles', # /var/run
  MDzone         => 'pseudo.dnsbl',

  # OPTIONAL
  MDstatrefresh => 300,       # seconds
  MDipaddr      => '0.0.0.0', # PROBABLY NOT WHAT YOU WANT
  MDport        => 9953,
  MDcache       => 10000,     # an entry takes ~400 bytes
                              # default 10000 (to small)
  
### WARNING ### 
  failure to set MDipaddr to a valid ip address will result
  in the authority section return an NS record of INADDR_ANY
  This will return an invalid NS record in stand alone operation

=head2 STANDALONE OPERATION

For standalone operation, simply set B<MDport = 53>, nothing more is
required.

Interrogating the installation will then return the first
match from the configured list of DNSBL servers.

  i.e.  dig 2.0.0.127.pseudo.dnsbl

        .... results

=head2 PLUGIN to BIND 9

B<multi_dnsbl> may be used as a plugin helper for a standard bind 9
installation by adding a B<forward> zone to the configuration file as
follows:

  //zone pseudo.dnsbl
  zone "pseudo.dnsbl" in {
        type forward;
        forward only;
        forwarders { 
            127.0.0.1 port 9953;
        };
  };

You may also wish to add one or more of the following statements with
appropriate address_match_lists to restrict access to the facility.  

        allow-notify {};
        allow-query { address_match_list };
        allow-recursion { address_match_list };
        allow-transfer {};      

=head2 MTA CONFIGURATION

Access to DNSBL lookup is configured in the normal fashion for each MTA.
Since MTA's generally must interrogate on port 53, B<multi_dnsbl> must be
installed on a stand-alone server or as a plugin for BIND 9. 

A typical configuration line for B<sendmail M4> configuration file is shown
below:

  FEATURE(`dnsbl',`pseudo.dnsbl',
  `554 Rejected $&{client_addr} found in http://www.my.blacklist.org')dnl

=head1 SYSTEM SIGNALS

B<multi_dnsbl> responds to the following system signals:

=over 4

=item * TERM

Operations the statistics file is updated with the internal counts and the
daemon then exits.

=item * HUP

Operations are stopped including an update of the optional statistics file,
the configuration file is re-read and operations are restarted.

=item * USR1

The statistics file is updated on the next second tick.

=item * USR2

The statistics file is deleted, internal statistics then a new (empty)
statistics file is written on the next second tick.

=back

=head1 PERL MODULE DESCRIPTION

B<Net::DNSBL::MultiDaemon> provides most of the functions that implement
B<multi_dnsbl> which is an MTA helper that interrogates a list of
DNSBL servers in preferential order based on their success rate.

The following describes the workings of individual functions
used to implement B<multi_dnsbl>.

=over 4

=item * run($BLzone,$L,$R,$DNSBL,$STATs,$Run,$Sfile,$StatStamp,$DEBUG);

This function is the 'run' portion for the DNSBL multidaemon

  input:
	$BLzone	zone name,
	$L	local listen socket object pointer,
	$R	remote socket object pointer,
	$DNSBL	config hash pointer,
	$STATs	statistics hash pointer
	$Run	pointer to stats refresh time,	# must be non-zero
	$Sfile	statistics file path,
	$StatStamp	stat file initial time stamp

  returns:	nothing

=over 2

=item * $BLzone

The fully qualified domain name of the blacklist lookup

=item * $L

A pointer to a UDP listener object

=item * $R

A pointer to a unbound UDP socket 
used for interogation and receiving replies for the multiple DNSBL's

=item * $DNSBL

A pointer to the configuration hash of the form:

  $DNSBL = {
    # Always allow these addresses
	'IGNORE' => [	# OPTIONAL
	   # a single address
	'11.22.33.44',
	   # a range of ip's, ONLY VALID WITHIN THE SAME CLASS 'C'
	'22.33.44.55 - 22.33.44.65',
	   # a CIDR range
	'5.6.7.16/28',
	   # a range specified with a netmask
	'7.8.9.128/255.255.255.240',
	   # you may want these
	'10.0.0.0/8',
	'172.16.0.0/12',
	'192.168.0.0/16',
	   # this should ALWAYS be here
	'127.0.0.0/8',  # ignore all test entries and localhost
	],

    # Do rhbl lookups only, default false
    # all other rejection classes are disabled, IGNORE, BLOCK, BBC, in-addr.arpa
    # RHBL need only be "true" for operation. If OPTIONAL URBL conditioning
    # is needed, then the parameters in the has must be added
	RHBL 	=> {	# optional URBL preparation
	  urblwhite => [
		'/path/to/cached/whitefile',
		'/path/to/local/file'	# see format of spamassassin file
	  ],
	  urblblack => [
		'/path/to/local/blacklist'
	  ],
# NOTE: level 3 tld's should be first before level 2 tld's
	  urbltlds  => [
		'/path/to/cached/tld3file',
		'/path/to/cached/tld2file'
	  ],
	  urlwhite  => [
		'http://spamassasin.googlecode.com/svn-history/r6/trunk/share/spamassassin/25_uribl.cf',
		'/path/to/cached/whitefile'
	  ],
	  urltld3   => [
		'http://george.surbl.org/three-level-tlds',
		'/path/to/cached/tld3file'
	  ],
	  urltld2   => [
		'http://george.surbl.org/two-level-tlds',
		'/path/to/cached/tld2file'
	  ],
  	},

    # Authoratative answers
	'AUTH'	=> 0,

    # Always reject these addresses
	'BLOCK'	=> [	# OPTIONAL
	   # same format as above
	],

    # Always block these countries
	'BBC'	=> [qw(CN TW RO )],

    # Check for reverse lookup failures - OPTIONAL
	'in-addr.arpa'	=> {
	    timeout	=> 15,  # default timeout is 30
	},

    # RBL zones as follows: OPTIONAL
	'domain.name' => {
    # mark this dnsbl to require right hand side domain processing
    # requires URBL::Prepare
# NOT IMPLEMENTED
#	    urbl	=> 1,
	    acceptany	=> 'comment - treat any response as valid',
    # or
	    accept	=> {
		'127.0.0.2' => 'comment',
		'127.0.0.3' => 'comment',
	    },
    # or
    # mask the low 8 bits and accept any true result
	    acceptmask	=> 0x3D,	# accepts 0011 1101

  #	    timeout	=> 30,	# default seconds to wait for dnsbl
	},

	'next.domain' = {
	    etc....
  # included but extracted external to B<run>

	MDzone		=> 'pseudo.dnsbl',
  	MDstatfile	=> '/path/to/statistics/file.txt',
	MDpidpath	=> '/path/to/pidfiles
  # OPTIONAL, defaults shown
  #	MDstatrefresh	=> 300,	# max seconds for refresh
  #	MDipaddr	=> '0.0.0.0', # PROBABLY NOT WHAT YOU WANT
  #	MDport		=> 9953,
  # syslog. Specify the facility, one of: 
  # LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR LOG_WARNING LOG_NOTICE LOG_INFO LOG_DEBUG
  #	MDsyslog	=> 'LOG_WARNING',
  #
  #	cache lookups using the TTL of the providing DNSBL
  #	each cache entry takes about 400 bytes, minimum size = 1000
  #	MDcache		=> 1000,      # 1000 is too small
  };

Zone labels that are not of the form *.*... are ignored, making this hash
table fully compatible with the SpamCannibal sc_Blacklist.conf file.

=item * $STATs

A pointer to a statistics collection array of the form:

  $STATs = {
	'domain.name' => count,
	etc...,
	'CountryCode' => count,
	etc...
  };

Initialize this array with
cntinit($DNSBL,$cp) L<Net::DNSBL::Utilities>/cntinit, then 
list2hash($BBC,$cp) L<Net::DNSBL::Utilities>/list2hash, then
statinit($Sfile,$cp) L<Net::DNSBL::Utilities>/statinit, below.

=item * $Run

A POINTER to the time in seconds to refresh the $STATs backing file. Even if
there is not backing file used, this value must be a positive integer.
Setting this value to zero will stop the daemon and force a restart. It is
used by $SIG{HUP} to restart the daemon.

=item * $Sfile

The path to the STATISTICS backing file.

  i.e.  /some/path/to/filename.ext

If $Sfile is undefined, then the time stamp need not be defined

=item * $StatTimestamp

Normally the value returned by
statinit($Sfile,$cp) L<Net::DNSBL::Utilities>/statinit, below.

=back

=cut

my %AVGs	= ();	# averages
my %CNTs	= ();	# current counts
my $tick	= 0;	# second ticker
my $interval	= 300;	# averaging interval
my $bucket	= 24 * 60 * 60;	# 24 hours for now...
my $weight	= 5;	# weight new stuff higher than old stuff
my $csize	= 0;	# cache size and switch
my $cused	= 0;	# cache in use
my ($now, $next);
my $newstat;		# new statistics flag, used by run

sub average {
  my $STATs = shift;
  my $multiplier = $bucket / ($bucket + (($now + $interval - $next) * $weight));
  $next = $now + $interval;		# next average event
  foreach (keys %$STATs) {
    next unless $_ =~ /\./;		# only real domains
    next unless exists $CNTs{"$_"};
    $AVGs{"$_"} = ($AVGs{"$_"} + ($weight * $CNTs{"$_"})) * $multiplier;
    $CNTs{"$_"} = 0;
  }
}

# increment statistics for "real" DNSBL's
# input:	STATS pointer
#		DNSBL string

sub bump_stats {
  my($STATs, $blist_0) = @_;
  $STATs->{"$blist_0"} += 1;				# bump statistics count
  if (exists $CNTs{"$blist_0"}) {
    $CNTs{"$blist_0"} += 1;
  } else {
    $CNTs{"$blist_0"} = 1;
    $AVGs{"$blist_0"} = 1;
  }
  $newstat = 1 unless $newstat;				# notify refresh that update may be needed
}

sub by_average {
  my($STATs,$a,$b) = @_;;
  if (exists $AVGs{"$b"} && exists $AVGs{"$a"}) {
    return ($AVGs{"$b"} <=> $AVGs{"$a"})
			||
	($STATs->{"$b"} <=> $STATs->{"$a"});
  }
  elsif (exists $AVGs{"$b"}) {
    return 1;
  }
  elsif (exists $AVGs{"$a"}) {
    return -1;
  } else {
    return ($STATs->{"$b"} <=> $STATs->{"$a"});
  }
}

# reverse digits in ipV4 address
#
# input:	ip
# returns:	reversed ip
#
sub revIP {
  join('.',reverse split /\./,$_[0]);
}

# cache takes about 400 bytes per entry
#
my %cache = (
#
#	ip address	=> {
#		expires	=>	time,		now + TTL from response or 3600 minimum
#		used	=>	time,		time cache item was last used
#		who	=>	$blist[0],	which DNSBL caused caching
#		txt	=>	'string',	txt from our config file or empty
#	},
);
my @topurge;			# working array

# for testing
# set now and next, csize return pointers to internal averaging arrays and cache
#
sub set_nownext {
  ($now,$next,$csize) = @_;
  return($interval,\%AVGs,\%CNTs,\%cache,\@topurge);
}

# purge cache when called from "run"

my $prp = -1;			# run pointer, see "mode" below
my $pai;			# array index
my $pnd;			# array end

# piecewise purge of expired cache items performs gnome sort while purging
#
# followed by conditional purge of cache size overrun of oldest touched
# cache items or those that will expire the soonest
#
# input:	nothing
# returns:	mode
#		-1	waiting to be initialized
#		 0	purging expired elements + gnome sort
#		 1	purging cache overrun

sub purge_cache {
  if ($prp == 0) {			# run state to purge expired elements
    my $k1 = $topurge[$pai];
#print STDERR "$pnd, $pai";
    if (exists $cache{$k1}) {
      my $j = $pai +1;
      my $k2 = $topurge[$j];
      if ($cache{$k1}->{expires} < $now) {
	delete $cache{$k1};
	splice(@topurge,$pai,1);	# remove element from cache array
	$pnd--;
#print STDERR " delete k1 = $k1\n";
      }
      elsif (exists $cache{$k2}) {
	if ($cache{$k2}->{expires} < $now) {
	  delete $cache{$k2};
	  splice(@topurge,$j,1);	# remove element from cache array
	  $pnd--;
#print STDERR " delete k2 = $k2\n";
	}
	elsif (	$cache{$k1}->{used} > $cache{$k2}->{used}		# oldest use
		|| ($cache{$k1}->{used} == $cache{$k2}->{used}		# or if equal, 
		    && $cache{$k1}->{expires} > $cache{$k2}->{expires})	# expires soonest
	) {
	  @topurge[$pai,$j] = @topurge[$j,$pai];
	  $pai--;
	  $pai = 0 if $pai < 0;
#print STDERR " swap k1, k2 - $k1 <=> $k2\n";
	}
	else {
	  $pai++;
#print STDERR " k1, k2 ok - $k1  :  $k2\n";
	}
      }
      else {
	splice(@topurge,$j,1);		# remove element from cache array
	$pnd--;
#print STDERR " remove k2 = $k2\n";
      }
    }
    else {
      splice(@topurge,$pai,1);		# remove element from cache array
      $pnd--;
#print STDERR " remove k1 = $k1\n";
    }
    return $prp if $pai < $pnd; 	# reached end?
# done, set next state
    $pnd++;
    $pnd -= $csize;
    if ($pnd > 0) {			# must delete overrun elements
      $prp = 1;
      $pai = 0;
    } else {
      $prp = -1;			# set to initialization state
    }
  }
  elsif ($prp > 0) {			# remove cache over run
    my $k = $topurge[$pai];
    delete $cache{$k} if exists $cache{$k};
    $pai++;
    unless ($pai < $pnd) {
      $prp = -1;
    }
  }
  else {
    return $prp unless $csize;		# not enabled
    $pnd = @topurge = keys %cache;
    $cused = $pnd;			# update amount of cache in use
    return $prp unless $pnd;		# nothing to do
    $pnd--;				# end of array
    $pai = 0;				# array index
    $prp = 0;				# run state sort
  }
  return $prp;
}

# setURBLdom
#
# sets breadcrumbs for stripped domain for URBL's
#
# input:	remote IP or domain
#		remote ID
#		notRHBL
#		ubl method pointer
#		blacklist host array pointer UNUSED
#		remoteThreads ptr
# return:
#    SCALAR	$rid
#    ARRAY	($rid,$whitelistedDomain,$SURBLookupDomain)
#			or false		or false

# $bap is unused

sub setURBLdom {
  my($rip,$rid,$notRHBL,$ubl,$bap,$rtp,$n) = @_;
  if ($notRHBL || ! $ubl) {		# don't even need to check
    return wantarray ? ($rid) : $rid;	# or URBL::Prepare not loaded
  }
  $rid = uniqueID() unless $rid;	# set $rid if it is empty
  $rtp->{$rid} = {} unless exists $rtp->{$rid};

  my $domain = '';
  my $white	= $ubl->urblwhite($rip);
  unless ($white) {
    $domain = $ubl->urbldomain($rip);
  }

  $rtp->{$rid}->{urbl}	= $domain;
  $rtp->{$rid}->{N}	= $n;
  return wantarray ? ($rid,$white,$domain) : $rid;
}

sub run {
  my ($BLzone,$L,$R,$DNSBL,$STATs,$Run,$Sfile,$StatStamp,$DEBUG) = @_;
#open(Tmp,'>>/tmp/multidnsbl.log');
#print Tmp "---------------------------\n";
  local *_alarm = sub {return $DNSBL->{"$_[0]"}->{timeout} || 30};
  $BLzone = lc $BLzone;
  my $myip = $DNSBL->{MDipaddr} || '';
  if ($myip && $myip ne '0.0.0.0') {
    $myip = inet_aton($myip);
  } else {
    $myip = A1271;
  }
  $DEBUG = 0 unless $DEBUG;
  my $ROK = ($DEBUG & $D_CLRRUN) ? 0:1;

  my (	$msg, $t, $targetIP, $cc, $comment,
	$Oname,$Otype,$Oclass,$Ottl,$Ordlength,$Odata,
	$off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount,
	$name,$type,$class,
	$ttl,$rdl,@rdata,
	$l_Sin,$rip,$zone,@blist,
	%remoteThreads,$rid,
	$rin,$rout,$nfound,
	$BBC,@NAignore,@NAblock,
	$notRHBL,$ubl);

  my $LogLevel = 0;
  if ($DNSBL->{MDsyslog}) {		# if logging requested
    require Unix::Syslog;
    import  Unix::Syslog @Unix::Syslog::EXPORT_OK;
    $LogLevel = eval "$DNSBL->{MDsyslog}";
## NOTE, logging must be initiated by the caller
  }

# generate NetAddr objects for addresses to always pass
  if ($DNSBL->{IGNORE} && ref $DNSBL->{IGNORE} eq 'ARRAY' && @{$DNSBL->{IGNORE}}) {
    list2NetAddr($DNSBL->{IGNORE},\@NAignore);
  }

# generate NetAddr objects for addresses to always reject
  if ($DNSBL->{BLOCK} && ref $DNSBL->{BLOCK} eq 'ARRAY' && @{$DNSBL->{BLOCK}}) {
    list2NetAddr($DNSBL->{BLOCK},\@NAblock);
  }

# fetch pointer to Geo::IP methods
  if ($DNSBL->{BBC} && ref $DNSBL->{BBC} eq 'ARRAY' && @{$DNSBL->{BBC}} && eval { require Geo::IP::PurePerl }) {
    $BBC = new Geo::IP::PurePerl;
  } else {
    $DNSBL->{BBC} = '';
  }

# check for caching
  if (exists $DNSBL->{MDcache}) {
    $csize = $DNSBL->{MDcache};
    $csize = 10000 if $DNSBL->{MDcache} < 10000;
  }

# check for right hand side block list operation
  if ($DNSBL->{RHBL}) {
    $notRHBL = 0;
    if (ref $DNSBL->{RHBL} && 
	((exists $DNSBL->{RHBL}->{urbltlds}  && ref($DNSBL->{RHBL}->{urbltlds})  eq 'ARRAY') ||
	 (exists $DNSBL->{RHBL}->{urblwhite} && ref($DNSBL->{RHBL}->{urblwhite}) eq 'ARRAY') ||
	 (exists $DNSBL->{RHBL}->{urblblack} && ref($DNSBL->{RHBL}->{urblblack}) eq 'ARRAY')) &&
	eval {
		no warnings;
		require URBL::Prepare;
	}
  ) {
      $ubl = new URBL::Prepare;
      if (exists $DNSBL->{RHBL}->{urlwhite} && ref($DNSBL->{RHBL}->{urlwhite}) eq 'ARRAY') {
	$ubl->loadcache(@{$DNSBL->{RHBL}->{urlwhite}});		# cache whitelist file
      }
      if (exists $DNSBL->{RHBL}->{urltld3} && ref($DNSBL->{RHBL}->{urltld3}) eq 'ARRAY') {
	$ubl->loadcache(@{$DNSBL->{RHBL}->{urltld3}});		# cache tld3 file
      }
      if (exists $DNSBL->{RHBL}->{urltld2} && ref($DNSBL->{RHBL}->{urltld2}) eq 'ARRAY') {
	$ubl->loadcache(@{$DNSBL->{RHBL}->{urltld2}});		# cache tld2 file
      }
      $ubl->cachetlds($DNSBL->{RHBL}->{urbltlds});
      $ubl->cachewhite($DNSBL->{RHBL}->{urblwhite});
      $ubl->cacheblack($DNSBL->{RHBL}->{urblblack});
    }
  } else {
    $notRHBL = 1;
  }
#select Tmp;
#$| = 1;
#print Tmp "running $$\n";
#select STDOUT;


# set up GENERIC PTR tests
  my($iptr,$regexptr);
  if (	exists $DNSBL->{GENERIC} &&
	ref $DNSBL->{GENERIC} eq 'HASH' &&
	($regexptr = $DNSBL->{GENERIC}->{regexp}) &&
	ref $regexptr eq 'ARRAY' &&
	@$regexptr > 0 ) {
#print Tmp "regexptr setup, @$regexptr\n";
    unless (	$DNSBL->{GENERIC}->{ignore} &&
		'ARRAY' eq ref ($iptr = $DNSBL->{GENERIC}->{ignore}) &&
		@$iptr > 0 ) {
      undef $iptr;
    }
  } else {
#print Tmp "regexptr FAILED\n";
    undef $regexptr;
  }

  my $filenoL = fileno($L);
  my $filenoR = fileno($R);

  $now = time;
  $next = $now + $interval;
  $newstat = 0;				# new statistics flag
  my $refresh = $now + $$Run;		# update statistics "then"

  local $SIG{USR1} = sub {$newstat = 2}; # force write of stats now
  local $SIG{USR2} = sub {		# kill and regenerate statfile
	return unless $Sfile;
	unlink $Sfile;
	foreach(keys %$STATs) {
	  $STATs->{"$_"} = 0;
	  %AVGs = ();
	  %CNTs = ();
	}
	$StatStamp = statinit($Sfile,$STATs);
	syslog($LogLevel,"received USR2, clear stats\n")
		if $LogLevel;
	$newstat = 2;			# re-write on next second tick
  };

  my $SOAptr = [	# set up bogus SOA
	$BLzone,
	&T_SOA,
	&C_IN,
	0,		# ttl of SOA record
	$BLzone,
	'root.'. $BLzone,
	$now,
	86400,
	43200,
	172800,
	3600,		# cache negative TTL's for an hour
  ];

  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  my $numberoftries = 6;

  my %deadDNSBL;
  foreach(keys %$STATs) {
    next unless $_ =~ /\./;					# only real domains
    $deadDNSBL{"$_"} = 1;					# initialize dead DNSBL timers
  }

  do {
    $rin = '';
    vec($rin,$filenoL,1) = 1;					# always listening to local port
    (vec($rin,$filenoR,1) = 1)					# listen to remote only if traffic expected
	if %remoteThreads;
    $nfound = select($rout=$rin,undef,undef,1);			# tick each second
    if ($nfound > 0) {
###################### IF PROCESS REQUEST ########################
      while (vec($rout,$filenoL,1)) {				# process request
	last unless ($l_Sin = recv($L,$msg,PACKETSZ,0));	# ignore receive errors
	if (length($msg) < HFIXEDSZ) {				# ignore if less then header size
	  return 'short header' if $DEBUG & $D_SHRTHD;
	  last;
	}
	($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
		$qdcount,$ancount,$nscount,$arcount)
		= gethead(\$msg);
	if ($qr) {
	  return 'query response' if $DEBUG & $D_QRESP;
	  last;
	}
	$comment = 'no bl';
	setAUTH(0);						# clear authority
	setRA($rd);
# if OPCODE
	if ($eXT && exists $eXT->{OPCODE} && $eXT->{OPCODE}->($eXT,$get,$put,\$msg,
		$off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,$qdcount,$ancount,$nscount,$arcount)) {
	  ; # message updated
	  $comment = 'mdextension opcode';
	} elsif ($opcode != QUERY) {
	  s_response(\$msg,NOTIMP,$id,1,0,0,0);
	  $comment = 'not implemented';
	} elsif (
		$qdcount != 1 || 
		$ancount || 
		$nscount || 
		$arcount
		) {
	  s_response(\$msg,FORMERR,$id,$qdcount,$ancount,$nscount,$arcount);
	  $comment = 'format error 1';
	} elsif (
		(($off,$name,$type,$class) = $get->Question(\$msg,$off)) && 
		! $name) {					# name must exist
	  s_response(\$msg,FORMERR,$id,1,0,0,0);
	  $comment = 'format error 2';
# if CLASS
	} elsif (!($eXT && exists $eXT->{CLASS} && $eXT->{CLASS}->($eXT,$get,$put,$id,$opcode,\$name,\$type,\$class)) &&
		$class != C_IN) {				# class must be C_IN
	  s_response(\$msg,REFUSED,$id,$qdcount,$ancount,$nscount,$arcount);
	  $comment = 'refused';
# if NAME
	} elsif (($eXT && exists $eXT->{NAME} && $eXT->{NAME}->($eXT,$get,$put,$id,$opcode,\$name,\$type,\$class)) ||
		$name !~ /$BLzone$/i) {			# question must be for this zone
	  s_response(\$msg,NXDOMAIN,$id,1,0,0,0);
	  $comment = 'not this zone';
	} else {
# THIS IS OUR ZONE request, generate a thread to handle it

	  print STDERR $name,' ',TypeTxt->{$type},' ' if $DEBUG & $D_VERBOSE;

# if TYPE
	  if ($eXT && exists $eXT->{TYPE} && (my $rv = $eXT->{TYPE}->($eXT,$get,$put,$id,$opcode,\$name,\$type,\$class))) {
	    $msg = $rv;
	    $comment = 'Extension type';
	  } elsif ( $type == T_A ||
	    $type == T_ANY ||
	    $type == T_TXT) {
	    if (( $notRHBL &&
		  $name =~ /^((\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}))\.(.+)/ &&
		  ($rip = $1) &&
		  ($targetIP = "$5.$4.$3.$2") &&
		  ($zone = $6) &&
		  $BLzone eq lc $zone) ||
# check for valid RFC1034 domain name, but allow digits in the first character
		(!$notRHBL &&								# check RHBL zones
###### CHANGE this REGEXP to alter permissible domain name patterns
		  $name =~ /^([a-zA-Z0-9][a-zA-Z0-9\.\-]+[a-zA-Z0-9])\.$BLzone$/ &&	# valid domain name
		  ($rip = $1) &&
		  ($targetIP = '' || 1) &&
		  ($zone = $BLzone))) {
	      my $expires;
# if CACHE
	      if ($eXT && exists $eXT->{CACHE} && (my $rv = $eXT->{CACHE}->($eXT,$get,$put,$id,$opcode,$rip,\$name,\$type,\$class,$ubl))) {
		$msg = $rv;
	      }
# if local white/black lists
	      elsif (!$notRHBL && $ubl && 		# right side checking and local white/black lists
		  do {
			if ($ubl->urblwhite($rip)) {
			  not_found($put,$name,$type,$id,\$msg,$SOAptr);
			  $rv = 'whitelisted';
			}
			elsif ($ubl->urblblack($rip)) {
			  ($msg) = _ansrbak($put,$id,1,$rip,$zone,$type,3600,A1272,$BLzone,$myip,'blacklisted');
			  $rv = 'blacklisted';
			}
		  }
	      ) {
		  $comment = $rv;
	      }
	      elsif ($rip eq '2.0.0.127') {				# checkfor DNSBL test
		($msg) = _ansrbak($put,$id,1,$rip,$zone,$type,3600,A1272,$BLzone,$myip,'DNSBL test response to 127.0.0.2');
		$comment = 'just testing';
	      }
### NOTE, $now does not get updated very often if the host is busy processing in this routine, but at least every 5 minutes.... good enough
	      elsif (	$csize && 					# cacheing enabled
			exists $cache{$rip} &&				# item exists in cache
			($expires = $cache{$rip}->{expires}) > $now ) {	# cache not expired
		$cache{$rip}->{used} = $now;				# update last used time
		my $blist_0 = $cache{$rip}->{who};
		my $txt = $cache{$rip}->{txt};
		$txt = $txt ? $txt . $targetIP : '';
	        ($msg) = _ansrbak($put,$id,1,$rip,$zone,$type,$expires - $now,A1272,$BLzone,$myip,$txt);	# send cached record
		$comment = 'cache record';
		bump_stats($STATs,$blist_0);
	      }
	      elsif ($type == T_TXT) {					# none of the rest of static stuff has TXT records
		not_found($put,$name,$type,$id,\$msg,$SOAptr);
		$comment = 'no TXT';
	      }
	      elsif ($notRHBL && @NAignore && matchNetAddr($targetIP,\@NAignore)) {	# check for IP's to always pass
		not_found($put,$name,$type,$id,\$msg,$SOAptr);		# return unconditional NOT FOUND
		$STATs->{WhiteList} += 1;				# bump WhiteList count
		$comment = 'IGNORE';
	      }
	      elsif ($notRHBL && @NAblock && matchNetAddr($targetIP,\@NAblock)) {	# check for IP's to always block
		($msg) = _ansrbak($put,$id,1,$rip,$zone,$type,3600,A1275,$BLzone,$myip);	# answer 127.0.0.5
		$STATs->{BlackList} += 1;				# bump BlackList count
		$comment = 'BLOCK';
	      }
	      elsif ($notRHBL && $BBC &&				# check for IP's to block by country
		     ($cc = $BBC->country_code_by_addr($targetIP)) &&
		     (grep($cc eq $_,@{$DNSBL->{BBC}}))) {
		($msg) = _ansrbak($put,$id,1,$rip,$zone,$type,3600,A1276,$BLzone,$myip);	# answer 127.0.0.6
		$STATs->{$cc} += 1;					# bump statistics count
		$newstat = 1 unless $newstat;				# notify refresh that update may be needed
		$comment = "block $cc";
	      }
	      else {
#test here for GENERIC
		@blist = ();
		foreach(sort { by_average($STATs,$a,$b) } keys %$STATs) {
		  next unless $_ =~ /\./;				# drop passed,white,black,bbc entries
		  push @blist, $_;
		}
		push @blist, 'genericPTR' if $regexptr;
# add bread crumbs for Extensions if necessary
		$rid = undef;	# trial remote ID
		if ($eXT && exists $eXT->{LOOKUP}) {
		  $rid = uniqueID();
		  $rid = $eXT->{LOOKUP}->($eXT,$get,$put,$rid,$id,$opcode,\$name,\$type,\$class,\%remoteThreads);
		}
		$rid = setURBLdom($rip,$rid,$notRHBL,$ubl,$DNSBL->{$blist[0]},\%remoteThreads,0);	# initialize urbl domain lookup name
		bl_lookup($put,\$msg,\%remoteThreads,$l_Sin,_alarm($blist[0]),$rid,$id,$rip,$type,$zone,@blist);
		send($R,$msg,0,$R_Sin);				# udp may not block
		print STDERR $blist[0] if $DEBUG & $D_VERBOSE;
		last;
	      }
            }
	    elsif ($BLzone eq lc $name && $type != T_TXT) {
	      my $noff = newhead(\$msg,
	      $id,
	      BITS_QUERY | QR,
	      1,1,1,0,
	      );
	      ($noff,my @dnptrs) = $put->Question(\$msg,$noff,	# 1 question
		$name,$type,C_IN);				# type is T_A
	      ($noff,@dnptrs) = $put->A(\$msg,$noff,\@dnptrs,	# 1 answer
		$name,T_A,C_IN,86400,$myip);
	      ($noff,@dnptrs) = $put->NS(\$msg,$noff,\@dnptrs,	# 1 authority
		$name,T_NS,C_IN,86400,$BLzone);
	    }
	    else {
	      not_found($put,$name,$type,$id,\$msg,$SOAptr);
	    }
	  } elsif ($type == T_NS && $BLzone eq lc $name) {	# respond with myip address
	    my $noff = newhead(\$msg,
	    $id,
	    BITS_QUERY | QR,
	    1,1,0,1,
	    );
	    ($noff,my @dnptrs) = $put->Question(\$msg,$noff,	# 1 question
		$name,$type,C_IN);				# type is T_NS
	    ($noff,@dnptrs) = $put->NS(\$msg,$noff,\@dnptrs,	# 1 answer
		$name,T_NS,C_IN,$86400,$BLzone);
	    ($noff,@dnptrs) = $put->A(\$msg,$noff,\@dnptrs,	# 1 additional glue
		$BLzone,T_A,C_IN,86400,$myip);
	  } elsif ($type == T_NS ||				# answer common queries with a not found
		 $type == T_MX ||
		 $type == T_SOA ||
		 $type == T_CNAME ||
		 $type == T_TXT) {
	    not_found($put,$name,$type,$id,\$msg,$SOAptr);
	  } elsif ($type == T_AXFR) {
	    s_response(\$msg,REFUSED,$id,1,0,0,0);
	    $comment = 'refused AXFR';
	  } else {
	    s_response(\$msg,NOTIMP,$id,1,0,0,0);
	    $comment = 'not implemented';
	  }
	}
	send($L,$msg,0,$l_Sin);					# udp may not block on send
	print STDERR " $comment\n" if $DEBUG & $D_VERBOSE;
#print Tmp "$comment\n";
	last;
      }
##################### IF RESPONSE  ###############################
      while (vec($rout,$filenoR,1)) {				# A response
	undef $msg;
	last unless recv($R,$msg,,PACKETSZ,0);			# ignore receive errors
	if (length($msg) < HFIXEDSZ) {				# ignore if less then header size
	  return 'short header' if $DEBUG & $D_SHRTHD;
	  last;
	}
	($off,$rid,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
		$qdcount,$ancount,$nscount,$arcount)
		= gethead(\$msg);
#print Tmp "GOT $rid, rcode=$rcode\n";
	unless (  $tc == 0 &&
		  $qr == 1 &&
		  $opcode == QUERY &&
		  ($rcode == NOERROR || $rcode == NXDOMAIN || $rcode == SERVFAIL) &&
		  $qdcount == 1 &&
		  exists $remoteThreads{$rid}) {			# must not be my question!
	  return 'not me 1' if $DEBUG & $D_NOTME;
	  last;
	}
	($l_Sin,$rip,$id,$type,$zone,@blist) = @{$remoteThreads{$rid}->{args}};
	my $urbldom = exists $remoteThreads{$rid}->{urbl} ? $remoteThreads{$rid}->{urbl} : '';
	($off,$name,$t,$class) = $get->Question(\$msg,$off);
	my($answer,$attl,@generic);
	if ($ancount && $rcode == &NOERROR) {
	  $name =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\.(.+)$/ || $name =~ /^([a-zA-Z0-9][a-zA-Z0-9\.\-]+[a-zA-Z0-9])\.($blist[0])$/;
	  my $z = lc $2;
#print Tmp "RESPONSE U $urbldom, R $rip, One $1, N $name, Z $z\n";
	  $z = ($z eq lc $blist[0]) || ($z eq 'in-addr.arpa' && $blist[0] eq 'genericPTR')
		? 1 : 0;
	  unless (  $z &&					# not my question
	  	    ((!$urbldom && $rip eq $1) ||
		     ($urbldom && $urbldom eq $1)) &&		# not my question
		    ($t == T_A || $t == T_PTR) &&		# not my question
		    $class == C_IN) {				# not my question
	    return 'not me 2' if $DEBUG & $D_NOTME;
	    last;
	  }
	  undef $answer;

	  setAUTH($aa);						# mirror out authority state
	  setRA($rd);

	ANSWER:
	  foreach(0..$ancount -1) {
	    ($off,$name,$t,$class,$ttl,$rdl,@rdata) = $get->next(\$msg,$off);
	    next if $answer;					# throw away unneeded answers
	    if ($t == T_A) {
	      if (exists $DNSBL->{"$blist[0]"}->{acceptany}) {
		$answer = A1272;
		$attl = $ttl;
		last ANSWER;
	      }
	      my $mask = (exists $DNSBL->{"$blist[0]"}->{acceptmask})
		? $DNSBL->{"$blist[0]"}->{acceptmask} : 0;
	      while($answer = shift @rdata) {			# see if answer is on accept list
		my $IP = inet_ntoa($answer);
		if ($mask & unpack("N",$answer) || grep($IP eq $_,keys %{$DNSBL->{"$blist[0]"}->{accept}})) {
		  $answer = A1272;
		  $attl = $ttl;					# preserve TTL of this responder
		  last ANSWER;
		}
		undef $answer;
	      } # end of rdata
	    }
	    elsif ($t == T_PTR && $blist[0] eq 'genericPTR') {	# duplicates in-addr.arpa lookup, inefficient, but does not happen often
#print Tmp "add $rdata[0]\n";
	      push @generic, $rdata[0];
	    }
	  } # end of each ANSWER
	  $ttl = $attl;						# restore responder TTL
	}
	elsif ($t == T_PTR && ($rcode == NXDOMAIN || $rcode == SERVFAIL)) { # no reverse lookup
#print Tmp "PTR w/ NXDOMAIN or SERVFAIL\n";
	  $answer = A1274;
	  $ttl = 3600;
	  $nscount = $arcount = 0;
	}

	if (@generic) {
	  my @names;
	  foreach my $g (@generic) {
	    last if $iptr && grep($g =~ /$_/i, @$iptr);
	    push @names, $g if $g && ! grep($g =~ /$_/i, @$regexptr);
	  }
	  $answer = A1277 unless @names;
	  $ttl = 3600;
	}
	if ($answer) {	# if valid answer
	  my $txt = '';
	  if (	$csize && 			# caching enabled && answer is from a real DSNBL
		($answer == A1272 || $answer == A1274 || $answer == A1277) ) {

# ip address      => {
#         expires =>      time,           now + TTL from response or 3600 minimum
#         used    =>      time,           time cache item was last used   
#         who     =>      $blist[0],      which DNSBL caused caching
#         txt     =>      'string',       txt from our config file or empty
# },
	    $txt = $DNSBL->{$blist[0]}->{error} if exists $DNSBL->{$blist[0]};
	    my $trailer = $notRHBL ? revIP($rip) : '';
	    $txt = $txt ? $txt . $trailer : '';
	    $cache{$rip} = {
		expires => $now + $ttl,		# use responding DNSBL remaining ttl
		used	=> $now,
		who	=> $blist[0],
		txt	=> $txt
	    };
	  }		
	  bump_stats($STATs,$blist[0]);
#	  $STATs->{"$blist[0]"} += 1;				# bump statistics count
#	  if (exists $CNTs{"$blist[0]"}) {
#	    $CNTs{"$blist[0]"} += 1;
#	  } else {
#	    $CNTs{"$blist[0]"} = 1;
#	    $AVGs{"$blist[0]"} = 1;
#	  }
#	  $newstat = 1 unless $newstat;					# notify refresh that update may be needed

	  my($nmsg,$noff,@dnptrs) = ($FATans)				# make proto answer
		? _ansrbak($put,$id,$nscount + $arcount +1,$rip,$zone,$type,$ttl,$answer,$BLzone,$myip,$txt)
		: _ansrbak($put,$id,1,$rip,$zone,$type,$ttl,$answer,$BLzone,$myip,$txt);
## add the ns section from original reply into the authority section so we can see where it came from, it won't hurt anything
  if ($FATans) {
	  foreach(0..$nscount -1) {
	    ($off,$Oname,$Otype,$Oclass,$Ottl,$Ordlength,$Odata)
		= $get->next(\$msg,$off);
	    ($noff,@dnptrs) = $put->NS(\$nmsg,$noff,\@dnptrs,
		$Oname,$Otype,$Oclass,$Ottl,$Odata);
	  }

# add the authority section from original reply so we can see where it came from
	  foreach(0..$arcount -1) {
	    ($off,$Oname,$Otype,$Oclass,$Ottl,$Ordlength,$Odata)
		= $get->next(\$msg,$off);
	    if ($Otype == T_A) {
		($noff,@dnptrs) = $put->A(\$nmsg,$noff,\@dnptrs,
		    $Oname,$Otype,$Oclass,$Ottl,$Odata);
	    } elsif ($Otype == T_AAAA) {
		($noff,@dnptrs) = $put->AAAA(\$nmsg,$noff,\@dnptrs,
		    $Oname,$Otype,$Oclass,$Ottl,$Odata);
	    } else {
		next;		# skip unknown authority types
	    }
	  }
  } # end FATans
# if ANSWER
	  if ($eXT && exists $eXT->{ANSWER} && $eXT->{ANSWER}->($eXT,$get,$put,$rid,$ttl,\$nmsg,\%remoteThreads)) {
	    ; # will update $nmsg
	  }
	  delete $remoteThreads{$rid};
	  $msg = $nmsg;
	  $ROK = 0 if $DEBUG & $D_ANSTOP;
	}
# no answer
	elsif (do {
		print STDERR '+' if $DEBUG & $D_VERBOSE;
#print Tmp "While eliminate $rid $blist[0]\n";
		my $rv = 0;
		while(!$rv) {
		  shift @blist;
		  unless (@blist) {
		    $rv = 1;
		  } else {
		    last unless $deadDNSBL{"$blist[0]"} > $numberoftries; # ignore hosts that don't answer
		  }
		}
		$rv;
	      }) {	# if no more hosts
# if NOTFOUND
	  not_found($put,$rip .'.'. $zone,$type,$id,\$msg,$SOAptr)	# send not found response
		unless $eXT && exists $eXT->{NOTFOUND} && $eXT->{NOTFOUND}->($eXT,$get,$put,$rid,$rip,\$type,\$zone,\$msg,\%remoteThreads);
	  delete $remoteThreads{$rid};
# endif
	  $STATs->{Passed} += 1;
	  $newstat = 1 unless $newstat;					# notify refresh that update may be needed
	} else {
	  $deadDNSBL{"$blist[0]"} = 1;					# reset retry count
#print Tmp "NOTFOUND bl_lookup, R \n";
	  $rid = setURBLdom($rip,$rid,$notRHBL,$ubl,$DNSBL->{$blist[0]},\%remoteThreads,1);	# initialize urbl domain lookup name
	  bl_lookup($put,\$msg,\%remoteThreads,$l_Sin,_alarm($blist[0]),$rid,$id,$rip,$type,$zone,@blist);
	  print STDERR $blist[0] if $DEBUG & $D_VERBOSE;
	  send($R,$msg,0,$R_Sin);					# udp may not block
	  last;
	}
	send($L,$msg,0,$l_Sin);

	if ($DEBUG & $D_VERBOSE) {
	  if ($answer) {
	    print STDERR ' ',inet_ntoa($answer),"\n";
	  } else {
	    print STDERR " no bl\n";
	  }
	}
	last;
      }
    }
##################### TIMEOUT, do busywork #######################
    else {							# must be timeout
      my $prpshadow = $prp;
      $now = time;						# check various alarm status
      unless ($now < $next) {
	average($STATs);
	purge_cache() if $prp < 0;		# initiate cache purge every 5 minutes or so
      }
      purge_cache() unless $prpshadow < 0;	# run cache purge thread unless just initiated
      foreach $rid (keys %remoteThreads) {
	next unless $remoteThreads{$rid}->{expire} < $now;	# expired??

	($l_Sin,$rip,$id,$type,$zone,@blist) = @{$remoteThreads{$rid}->{args}};

	if (++$deadDNSBL{"$blist[0]"} > $numberoftries) {
	  $deadDNSBL{"$blist[0]"} = 3600;			# wait an hour to retry
	  if ($LogLevel) {
	    syslog($LogLevel, "timeout connecting to $blist[0]\n");
	  }
	}

	if ($blist[0] eq 'in-addr.arpa') {			# expired reverse DNS lookup ?
	  delete $remoteThreads{$rid};
	  $deadDNSBL{"$blist[0]"} = 0;				# reset timeout (this one never expires)
	  my $txt = exists $DNSBL->{$blist[0]}
		? $DNSBL->{$blist[0]}->{error}
		: '';
	  $cache{$rip} = {
		expires => $now + 3600,				# always an hour
		used	=> $now,
		who	=> $blist[0],
		txt	=> $txt
	  };
	  bump_stats($STATs,$blist[0]);
#	  $STATs->{"$blist[0]"} += 1;				# bump statistics count
#	  if (exists $CNTs{"$blist[0]"}) {
#	    $CNTs{"$blist[0]"} += 1;
#	  } else {
#	    $CNTs{"$blist[0]"} = 1;
#	    $AVGs{"$blist[0]"} = 1;
#	  }
#	  $newstat = 1 unless $newstat;				# notify refresh that update may be needed
	  ($msg) = _ansrbak($put,$id,1,$rip,$zone,$type,3600,A1274,$BLzone,$myip,$txt);
	  send($L,$msg,0,$l_Sin);
	  print STDERR " expired Rdns\n" if $DEBUG & $D_VERBOSE;
	}
	elsif (do {
		print STDERR '?' if $DEBUG & $D_VERBOSE;
		my $rv = 0;
		while(!$rv) {
		  shift @blist;
		  unless (@blist) {
		    $rv = 1;
		  } else {
		    last unless $deadDNSBL{"$blist[0]"} > $numberoftries; # ignore hosts that don't answer
		  }
		}
		$rv;
	      }) {	# if no more hosts
# if NOTFOUND
	  not_found($put,$rip .'.'. $BLzone,$type,$id,\$msg,$SOAptr)	# send not found response
		unless $eXT && exists $eXT->{NOTFOUND} && $eXT->{NOTFOUND}->($eXT,$get,$put,$rid,$rip,\$type,\$BLzone,\$msg,\%remoteThreads);
	  delete $remoteThreads{$rid};
# endif
	  $STATs->{Passed} += 1;				# count messages that pass thru this filter
	  $newstat = 1 unless $newstat;				# notify refresh that update may be needed
	  send($L,$msg,0,$l_Sin);
	  print STDERR " no bl\n" if $DEBUG & $D_VERBOSE;
	} else {
#print Tmp "second NOTFOUND\n";
	  bl_lookup($put,\$msg,\%remoteThreads,$l_Sin,_alarm($blist[0]),$rid,$id,$rip,$type,$zone,@blist);
	  send($R,$msg,0,$R_Sin);				# udp may not block
	  print STDERR $blist[0] if $DEBUG & $D_VERBOSE;
	}
      }
      foreach(keys %deadDNSBL) {				# eventually retry dead DNSBL
	--$deadDNSBL{"$_"} if $deadDNSBL{"$_"} > $numberoftries;
      }
      if ($newstat > 1 ||
	  ($refresh < $now && $newstat)) {			# update stats file
	write_stats($Sfile,$STATs,$StatStamp,$csize,$cused);
	$refresh = $now + $$Run;
	$newstat = 0;
      }
      return 'caught timer' if $DEBUG & $D_TIMONLY;
    }
  } while($$Run && $ROK);
  write_stats($Sfile,$STATs,$StatStamp,$csize,$cused) if $newstat;	# always update on exit if needed
}

# answer back prototype
#
# input:	$put,$id,$arcount,$rip,$zone,$type,$ttl,$answer,$BLzone,$myip,$withtxt,$CD
# returns:	$message,$off,@dnptrs
#
sub _ansrbak {
  my($put,$id,$arc,$rip,$zone,$type,$ttl,$ans,$BLzone,$myip,$withtxt,$CD) = @_;
  my $haveA = ($type == T_A || $type == T_ANY) ? 1 : 0;
  my $haveT = (($type == T_ANY || $type == T_TXT) && $withtxt) ? 1 : 0;
  $CD = $CD ? 0 : CD;
  my $nmsg;
  my $nans = $haveA + $haveT;
  my $noff = newhead(\$nmsg,
	$id,
	BITS_QUERY | QR,
	1,$nans,1,$arc,
  );
  ($noff,my @dnptrs) = $put->Question(\$nmsg,$noff,	# 1 question
	$rip .'.'. $zone,$type,C_IN);			# type is T_A or T_ANY or T_TXT
  if ($haveA) {
    ($noff,@dnptrs) = $put->A(\$nmsg,$noff,\@dnptrs,	# add 1 answer
	$rip .'.'. $zone,T_A,C_IN,$ttl,$ans);
  }
  if ($haveT) {
    ($noff,@dnptrs) = $put->TXT(\$nmsg,$noff,\@dnptrs,
	$rip .'.'. $zone,T_TXT,C_IN,$ttl,$withtxt);
  }
  ($noff,@dnptrs) = $put->NS(\$nmsg,$noff,\@dnptrs,	# 1 authority
	$zone,T_NS,C_IN,86400,$BLzone);
  ($noff,@dnptrs) = $put->A(\$nmsg,$noff,\@dnptrs,	# 1 additional glue
	$BLzone,T_A,C_IN,86400,$myip);		# show MYIP
  return($nmsg,$noff,@dnptrs)
}

=item * bl_lookup($put,$mp,$rtp,$sinaddr,$alarm,$rid,$id,$rip,$type,$zone,@blist);

Generates a query message for the first DNSBL in the @blist array. Creates
a thread entry for the response and subsequent queries should the first one fail.

  input:	put,
		message pointer,
		remote thread pointer,
		sockinaddr,
		connection timeout,
		remote id or undef to create
		id of question,
		reverse IP address in text
		type of query received, (used in response)
		ORIGINAL zone (case preserved),
		array of remaining DNSBL's in sorted order
  returns:	nothing, puts stuff in thread queue

  extra:	if URBL processing is required,
		$remoteThreads{$rid}->{urbl}
		is set to the domain to look up

=cut

# This function returns an integer between 1 -> 65535 in a pseudo-random
# repeatable order. Seeds with $$ by default, can be seeded with any integer;
#

my $id = $$;

sub uniqueID {
  $id = $_[0] ? ($_[0] % 65536) : $id;
  $id = 1 if $id < 1 || $id > 65534;
  $id++;
}

sub bl_lookup {
  my($put,$mp,$rtp,$sinaddr,$alarm,$rid,$id,$rip,$type,$zone,@blist) = @_;
  $rid = uniqueID unless $rid;
  my $off = newhead($mp,
	$rid,
	BITS_QUERY | RD,
	1,0,0,0,
  );
  my $blist = ($blist[0] eq 'genericPTR')
	? 'in-addr.arpa'
	: $blist[0];

  my $Qtype = ($blist eq 'in-addr.arpa')
	? &T_PTR
	: &T_A;

# send conditioned URBL request if that is what is needed
  if ($rtp->{$rid}->{urbl}) {
    $put->Question($mp,$off,$rtp->{$rid}->{urbl}.'.'. $blist,$Qtype,C_IN);
  } else {
    $put->Question($mp,$off,$rip .'.'. $blist,$Qtype,C_IN);
  }
  $rtp->{$rid} = {} unless exists $rtp->{$rid};
  $rtp->{$rid}->{args}   = [$sinaddr,$rip,$id,$type,$zone,@blist];
  $rtp->{$rid}->{expire} = time + $alarm;
#print Tmp "$blist => ",Dumper($rtp);
}

=item * set_extension($pointer);

This function sets a pointer to user defined extensions to
Net::DNSBL::MultiDaemon.

Pointer is of the form:

	$Extension ->{
		OPCODE	 => value,
		CLASS	 => subref->($Extension,internal args),
		NAME	 => subref->($Extension,internal args),
		TYPE	 => subref->($Extension,internal args),
		LOOKUP	 => subref->($Extension,internal args),
		ANSWER	 => subref->($Extension,internal args),
		NOTFOUND => subref->($Extension,internal args)
	};

The pointer should be blessed into the package of the caller if the calling
package needs to store persistant variables for its own instance. The subref
will be called with the first argument of $Extension.

Care should be taken to NOT instantiate a %remoteThreads in the CLASS, NAME,
TYPE section unless it is know that it will be found and expired/deleted.

Read the code if you wish to add an extension

=back

=cut

sub set_extension {
  $eXT = shift;
}

=head1 DEPENDENCIES

  Unix::Syslog
  Geo::IP::PurePerl [conditional for country codes]
  NetAddr::IP
  Net::DNS::Codes
  Net::DNS::ToolKit

=head1 EXPORT_OK

        run
        bl_lookup  

=head1 EXPORT_TAGS :debug

  DEBUG is a set of semaphores for the 'run' function

  $D_CLRRUN    = 0x1;  # clear run flag and force unconditional return
  $D_SHRTHD    = 0x2;  # return short header message
  $D_TIMONLY   = 0x4;  # exit at end of timer section
  $D_QRESP     = 0x8;  # return query response message
  $D_NOTME     = 0x10; # return received response not for me
  $D_ANSTOP    = 0x20; # clear run OK flag if ANSWER present
  $D_VERBOSE   = 0x40; # verbose debug statements to STDERR 

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 COPYRIGHT

Copyright 2003 - 2014, Michael Robinton & BizSystems
This program is free software; you can redistribute it and/or modify
it under the terms as Perl itself or the GNU General Public License 
as published by the Free Software Foundation; either version 2 of 
the License, or  (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 SEE ALSO

L<URBL::Prepare>, L<Geo::IP::PurePerl>, L<Net::DNSBL::Utilities>, L<Net::DNS::Codes>, L<Net::DNS::ToolKit>, L<Mail::SpamCannibal>

=cut

1;
