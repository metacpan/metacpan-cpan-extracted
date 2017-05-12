#!/usr/bin/perl
package Net::Connection::Sniffer::Report;

use strict;
#use diagnostics;

use Net::NBsocket 0.16 qw(
	open_udpNB
	sockaddr_in
	inet_ntoa
	inet_aton
	dyn_bind
);
use Sys::Hostname::FQDN qw(
	fqdn
);

# pack sockaddr_in
# 0     pfinet  2
# 1             0
# 2     port    0
# 3             1
# 4     naddr   0
# 5             1
# 6             2
# 7             3
# 8     pad     0
# 9     to      0
# 10    16      0
# 11    bytes   0
# 12            0
# 13            0
# 14            0
# 15            0
#      $sin = pack('C2na4L2',$pf_inet,0,$2,inet_aton($1),0,0)

use NetAddr::IP::Util qw(
	inet_any2n
	sub128
	hasbits
);
use Net::Connection::Sniffer::Util;

use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = do { my @r = (q$Revision: 0.13 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

*dyn_bind = \&Net::NBsocket::dyn_bind;

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(
	read_stf
	by_cidr24
	by_name
	report
	presync
	sync
	chkcache
	get_lock
	chk_wconf
	rem_wchk
	rqst_dump
	web_report
	my_time
	dyn_bind
	xhandle
	rem_dump
	rem_update
	chk_lock
	rem_report
);

=head1 NAME

Net::Connection::Sniffer::Report -- network profiling reports

=head1 SYNOPSIS

  use Net::Connection::Sniffer::Report qw(
	read_stf
	by_cidr24
	by_name
	report
	presync
	sync
	chkcache
	get_lock
	chk_wconf
	rem_wchk
	rqst_dump
	web_report
	my_time
	dyn_bind
	xhandle
	rem_dump
	rem_update
	chk_lock
	rem_report
  };

=head1 DESCRIPTION

B<Net::Connection::Sniffer::Report> consolidates the dump file produced
by B<Net::Connection::Sniffer>.

  ($stats,$head) = read_stf($filepathname);
  ($byc24,$rate,$bw) = by_cidr24($stats);
  ($byname,$rate,$bw) = by_name($stats,$byc24);
   $rv = report(*HANDLE,$file,$type);
   $rv = presync($filepathname);
   $rv = sync($filepathname,$oldtime,$timeout);
   $rv = chkcache($filepathname,$age);
  ($lock,$file) = get_lock($filepathname,$timeout,$umask);
   $rv = chk_wconf($conf);
   $rv = rem_wchk($conf);
   $rv = rqst_dump($sin,$file,$age,$updto);
   web_report($wconf);
   $timestring = my_time($epoch_seconds);
   $port = dyn_bind($sock,$netaddr);
   $handle = xhandle($program_string);
   $rv = rem_dump($conf);
   $rv = rem_update($config);
   rem_report($wconf);

=over 4

=item * ($stats,$head) = read_stf($filepathname);

Read the B<Net::Connection::Sniffer> status file and return a reference to
its contents.

  input:	file path
  returns:	undef or empty array on failure
			[$@ is set with error]
    or scalar
		reference to status hash
    or array
		(status ref, $header)

Where the $header content is extracted from the B<Net::Connection::Sniffer>
status file.

=cut

sub read_stf {
  local *F;
  my $file = shift;
  eval {
    die "no status file '$file'"
	unless $file && -e $file && -r $file && -s $file &&
	open (F,$file);
  };
  if ($@) {
    return wantarray ? () : undef;
  }

  my $header = '';
  while (($_ = <F>) =~ /^#/ || $_ !~ /\S/) {
    $header .= $_;
  }
  local $/ = undef;
  $_ .= <F>;
  close F;

  return eval "$_"
	unless wantarray;
  return (eval "$_", $header);
}

=item * ($byc24,$rate,$bw) = by_cidr24($stats);

Return a reference to the composite of the status hash with usage grouped by cidr/24

  input:	reference to $stats
  returns:	$composite,	# reference to composite hash
		$rate,		# calculated queries per hour
		$bw		# calculated bytes per hour
		

  $composite = {
     number  => {		# number is for administrative use only
	R	=> 12345,	# composite queries / hour
	W	=> 45678,	# composite bytes / hour
	A	=> ['ip1','ip2','...'], # ip addr's in cidr/24
	E	=> 12345,	# last update timestamp
     },
     another number => {	and so on...

=cut

sub by_cidr24 {
  my $s = shift;
  my $bandwidth = 0;
  my $rate = 0;
  my($ln,$r,$w,$e,$nip);
  my($ce,$cr,$cw,$cn,$key);
  my $num = 0;
  my $composite = {};
  foreach $_ (sort keys %$s) {
    $nip = newcidr24 Net::Connection::Sniffer::Util(inet_any2n($_));
    $r = $s->{$_}->{R};
    $w = $s->{$_}->{W};
    $e = $s->{$_}->{E};
    unless ($ln) {		# first time through
      $cr = $r;
      $cw = $w;
      $ce = $e;
      $ln = $nip;
      $key = [$_];
    }
    elsif ($nip->within($ln)) {
      $cr += $r;
      $cw += $w;
      $ce = $e if $e > $ce;
      push @{$key}, $_;
    } else {
      $ln = $nip;
      $composite->{$num}->{R} = $cr;
      $composite->{$num}->{W} = $cw;
      $composite->{$num}->{E} = $ce;
      @_ = sort {		# put ip's in numeric order
	inet_aton($a) cmp inet_aton($b)
      } @$key;
      $composite->{$num}->{A} = [@_];
      $rate += $cr;
      $bandwidth += $cw;
      $num++;
      $cr = $r;
      $cw = $w;
      $ce = $e;
      $key = [$_];
    }
  }
  if ($nip->equal($ln)) {
    $composite->{$num}->{R} = $cr;
    $composite->{$num}->{W} = $cw;
    $composite->{$num}->{E} = $ce;
    @_ = sort {		# put ip's in numeric order
      inet_aton($a) cmp inet_aton($b)
    } @$key;
    $composite->{$num}->{A} = [@_];
    $rate += $cr;
    $bandwidth += $cw;
  }
  return ($composite,$rate,$bandwidth);
}

=pod

=item * ($byname,$rate,$bw) = by_name($stats,$byc24);

Further groups the composite statistics by primary sub domains.

  input:	reference to statistics hash,
		reference to cidr24 grouping
  returns:	$byname,	# reference to composite hash
		$rate,		# calculated queries per hour
		$bw		# calculated bytes per hour

  $byname = {
     rev_subdomain => {		# text for administrative use
	R	=> 12345,	# composite queries / hour
	W	=> 45678,	# composite bytes / hour
	A	=> ['ip1','ip2','...	# and so on...
	E	=> 12345,	# last update timestamp
    },
    another rev subdomain => {	and so on...

=cut

sub by_name {
  my($s,$bc) = @_;
  my $byname = {};
  my $lastdom = '';
  my $rate = 0;
  my $bw = 0;
  foreach(sort {
	my $A = $bc->{$a}->{A}->[0];	# use the first IP address to get a host name
	my $B = $bc->{$b}->{A}->[0];
	(lc $s->{$A}->{N}->[0] || '') cmp (lc $s->{$B}->{N}->[0] || '')
    } keys %$bc) {
    my $ip = $bc->{$_}->{A}->[0];
    my $name = reverse split('',lc $s->{$ip}->{N}->[0]);
    my $ndm;
    if ($name =~ /^[\w-]{2}\.[\w-]{3}\.[\w-]+/) {	# of the form 'name.(net|com|org).countrycode'
      $ndm = $&;
    }
    elsif ( $name =~ /^[\w-]+\.[\w-]+/) {		# of the form 'name.ext'
      $ndm = $&;
    } else {
      $ndm = $name;					# don't know what it is, leave it
    }
    if ($lastdom eq $ndm) {
      if ($bc->{$_}->{E} > $byname->{$ndm}->{E}) {
	$byname->{$ndm}->{E} = $bc->{$_}->{E};
      }
      $byname->{$ndm}->{R} += $bc->{$_}->{R};
      $byname->{$ndm}->{W} += $bc->{$_}->{W};
      push @{$byname->{$ndm}->{A}},@{$bc->{$_}->{A}};
    } else {	# new entry
      $lastdom = $ndm;					# new, update
      $byname->{$ndm}->{E} = $bc->{$_}->{E};
      $byname->{$ndm}->{R} = $bc->{$_}->{R};
      $byname->{$ndm}->{W} = $bc->{$_}->{W};
      @{$byname->{$ndm}->{A}} = @{$bc->{$_}->{A}};
    }
    $rate += $bc->{$_}->{R};
    $bw += $bc->{$_}->{W};
  }
  return ($byname,$rate,$bw);
}

=pod

=item * $rv = report(*HANDLE,$file,$type);

Generate a statistics usage report ordered from highest to lowest bandwidth
usage.

Two types of reports are created:

  1) grouped by cidr24 [default], $type = false
  2) grouped by sub domain, $type = true

  input:	*HANDLE,	# file or *STDOUT
		$file		# path/to/statistics_file
		$type,		# true/false
  returns:	returns false on success
		or the error
  prints:	to the file handle

=cut

sub report {
  my($handle,$file,$type) = @_;
  my($stats,$head) = read_stf($file);
  return $@ if $@;
  my($composite,$rate,$bandwidth) = by_cidr24($stats);

  if ($type) {
    ($composite,$rate,$bandwidth) = by_name($stats,$composite);
    $type = 'SUB DOMAIN';
  }
  else {
    $type = 'CIDR/24';
  }
  print $handle $head,
		 "\nComposite report, $type ordered by BANDWIDTH\n";
  my $title	="\n   IP addr\t    host name".
		 "\n qrys/mn -- bytes/sec -- #IP's\tlast contact time\n\n";
  print $handle $title;

  foreach my $key (sort {
	     (int ($composite->{$b}->{W}/3600) <=> int($composite->{$a}->{W}/3600))
						||
	 inet_aton($composite->{$a}->{A}->[0]) cmp inet_aton($composite->{$b}->{A}->[0])
	} keys %$composite) {
    foreach (sort {		# sort into ascending ip address order
	inet_aton($a) cmp inet_aton($b)
      } @{$composite->{$key}->{A}}) {
      my $name = join("\n\t\t",@{$stats->{$_}->{N}});
      printf $handle ("%s\t%s\n",$_,$name);
    }
    printf $handle (" %6.0f\t -- %.0f\t -- %d\t%s\n",$composite->{$key}->{R} /60,$composite->{$key}->{W} /3600,scalar @{$composite->{$key}->{A}},my_time($composite->{$key}->{E}));
  }
  print $handle $title;
  printf $handle ("rate\t\t= %.0f connections per minute\nbandwidth\t= %.0f bytes per second\nusers\t\t= %d\n",$rate /60,$bandwidth /3600,scalar keys %$stats);
  return undef;
}

=item * $rv = presync($filepathname);

Wait up to one second for the file to be older than now.

  input:	$fpn,	# path to file
  returns:	$ctime	# file ctime
	    or	0 if the file does not yet exist
	    or	undef on error (ctime in future)

=cut

# return at beginning of next second
#
sub _next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

# return file ctime
#
sub _ctime {
  return (stat($_[0]))[10];
}

sub presync {
  my ($file) = @_;
  return undef unless -e $file && -r $file;
  my $now = time;
  my $ctime = _ctime($file);
  return $ctime if $ctime < $now;
  $now = _next_sec($now);
  return undef if $ctime > $now;	# error if someone messes with ctime
  $ctime;
}

=item * $rv = sync($filepathname,$oldtime,$timeout);

Wait for file ctime to update, fail on timeout.

  input:	$fpn,	# path to file
		$old,	# original ctime or
			# 0 if the file will be created
		$to,	# timeout in seconds
			# [default 30 seconds]
  returns:	$ctime	# file ctime
	    or	undef on failure

  Sets $@ on timeout;

Sets $@ on timeout. If the file is not initially found, sync will wait for
the timeout period if the directory is present and readable.

=cut

sub sync {
  my($file,$old,$to) = @_;
  $old = 0 unless $old;
  $to = 30 unless $to;
  $file =~ m|[^/]+$|;
  return undef unless -d $` && -r $`;		# directory must exist and be readable
  my $ctime = (-e $file)
	? _ctime($file)
	: 0;
  return $ctime if $old && $ctime > $old;
  eval {
	local $SIG{ALRM} = sub {die "'$file' timeout"};
	alarm $to;
	while (1) {
	  last if $ctime && $ctime > $old;
	  select(undef,undef,undef,0.1);
	  $ctime = _ctime($file);
	}
	alarm 0;
  };
  return undef if $@;
  return $ctime;
}

=item * $rv = chkcache($filepathname,$age);

Check if a file is older than 'age'

  input:	file	# path to file
		age	# maximum age in seconds
			# [default = 300 seconds]
  return:	ctime if not too old
		undef if too old or missing

=cut

sub chkcache {
  my($file,$age) = @_;
  return undef unless -e $file && -r $file;
  $age = 300 unless $age;
  my $ctime = _ctime($file);
  return undef if ($ctime + $age) < time;
  $ctime;
}

=item * ($lock,$file)=get_lock($filepathname,$timeout,$umask);

Return an exclusive file handle.

  input:	$file,		# path to file
		$to,		# timeout in seconds
				# [default 15 seconds]
		$umask		# [default 0117]
  returns:	($lock,$file)	# handles
	    or	() on error

  Sets $@ on error.
  NOTE: the file path must be prechecked!

Remember to close both the FILE and the LOCKFILE.

=cut

sub get_lock {
  my($file,$to,$umask) = @_;
  $to = 15 unless $to;
  $umask = 0117 unless $umask;
  require Fcntl;
  import Fcntl qw(:DEFAULT :flock);
  local(*LOCK,*FILE);
  my $lock;
  eval {
      local $SIG{ALRM} = sub {die "can not lock $file"};
      alarm $to;
      umask $umask;
      while (1) {
	die "could not open lock file '${file}.lock'"
		unless sysopen LOCK, $file .'.lock', &O_RDWR|&O_CREAT|&O_TRUNC;
	unless (flock LOCK, &LOCK_EX) {
	  close LOCK;
	  select(undef,undef,undef,1);		# sleep a second, don't use 'sleep'
	  next;
	}
# lock achieved
	unless (sysopen FILE, $file, &O_RDWR|&O_CREAT) {
	  close LOCK;
	  die "could not open '$file' after lock"
	}
	alarm 0;
	last;
      }
  };
  return $@ ? () : (*LOCK,*FILE);
}

=item * $rv = chk_wconf($conf);

Check the syntax and content of the web configuration hash.

  input:	hash reference
  returns:	false on success or error text

=cut

sub chk_wconf {
  my $wc = shift;
  return 'required statistics file specification missing'
	unless exists $wc->{stats};
  $wc->{stats} =~ m|[^/]+$|;
  my $dir = $` || './';
  return "stats directory missing or not readable: '$dir'"
	unless -d $dir && -r $dir;
  if (exists $wc->{cache}) {
    $wc->{cache} =~ m|[^/]+$|;
    $dir = $` || './';
    return "cache directory not writable: '$dir'"
	unless -d $dir && -w $dir;
    if (-e $wc->{cache}) {
      return "invalid permissions on '$wc->{cache}': not writable"
	unless -w $wc->{cache};
    }
  }
  if (exists $wc->{updto} && $wc->{updto}) {
    return "invalid characters in update timeout: '$wc->{updto}'"
	if $wc->{updto} =~ /\D/;
  }
  else {
    $wc->{updto} = 15;		# default
  }
  if (exists $wc->{refresh} && $wc->{refresh}) {
    return "invalid characters in refresh: '$wc->{refresh}'"
	if $wc->{refresh} =~ /\D/;
  }
  else {
    $wc->{refresh} = 300;		# default
  }
  if (exists $wc->{update}) {
    if ($wc->{update} =~ /([\w.-]+)\:(\d+)/) {	# host + port	
      return "invalid characters in host address: '$1'"
	unless (my $netaddr = inet_aton($1));
      $wc->{update} = sockaddr_in($2,$netaddr);
    }
    elsif ($wc->{update} =~ /^\d+$/) {		# only digits
      $wc->{update} = sockaddr_in($&,&Socket::INADDR_LOOPBACK);
    }
    else {
      return "invalid update specification '$wc->{update}'";
    }
  }	# else it is disabled, must use kill -USR1
  return '';
}

=item * $rv = rem_wchk($conf);

Check the remote fetch configuration file.

Note: ignores missing 'update' entry if localhost is not
specified for update.

  input:	hash reference
  returns:	false on success or error text

=cut

sub rem_wchk {
  my ($c) = @_;
  return 'missing cache file entry'
	unless $c->{cache};
  $c->{stats} = $c->{cache}		# fudge stats entry for conf check if no localhost entry
	unless exists $c->{update} && $c->{update};
  goto &chk_wconf;
}

=item * $rv = rqst_dump($sin,$file,$age,$updto);

Request a stats dump from the daemon

  input:	sockaddr_in,	# address dump rqst host
		path/to/statsfile,
		age,		# in seconds i.e. 300
		update timeout

  returns:	false on success or error text

If $sin is false, not dump is performed

If age if false, dump is requested unconditionally

=cut

sub rqst_dump {
  my($theirsin,$file,$age,$updto) = @_;
# pre-sync the stats file
  my $ctime = presync($file) || 0;	# ignore errors if file is not yet present
  my $tmp = '';
  if  ($theirsin && (! $age || ($ctime + $age) < time)) {
    my $sock = open_udpNB();
    unless ($sock) {
      $tmp = 'could not open UDP socket';
      last;
    }
    while (1) {
      my $name = fqdn();
      unless (dyn_bind($sock,inet_aton($name))) {
	$tmp = "could not bind socket to $name, $!";
	last;
      }
      $tmp = 'dump';
      send($sock,$tmp,0,$theirsin);	# udp may not block
# wait for stats update
      $ctime = sync($file,$ctime,$updto);
      if ($@) {
	$tmp = $@;					# probably a timeout error
	last;
      }
      if (defined recv($sock,$tmp,256,0) &&		# retrieve response if we can
	$tmp =~ /OK\s*(\d+)/ &&			# good receive response
	$1 > $ctime) {				# weird timing error
	$tmp = "statistics update error OK $1 > file $ctime";
      } else {
	$tmp = '';
      }
      last;
    }
    close $sock;
  }
  return $tmp;
}

=item * web_report($wconf);

Print a report to STDOUT. Takes the type of report from the first argument.

  usage: <!--#exec cmd="./nc.sniffer.cgi 0" -->
    or	 <!--#exec cmd="./nc.sniffer.cgi 1" -->

where an argument of "0" produces a report ordered by /24 by usage and an
argument of "1" produces a report ordered by subdomain by usage.

  input:	config pointer
  returns:	prints to STDOUT

where $wconf = {

  # location of statistics file
  # [REQUIRED]
  #
	stats	=> '/var/run/nc.sniffer/nc.sniffer.stats',

  # location of web cache file, this must exist
  # and be writable by the web daemon
  # [RECOMMENDED]
  #
	cache	=> './tmp/sniffer.cache',

  # statstistics update timeout
  # [OPTIONAL] default 15 seconds
  #
	updto	=> 15,

  # cache or stats (if cache not activated above)
  # refresh every nnn seconds
  # default is 300 seconds
  # [OPTIONAL]
  #
	refresh	=> 300,

  # update host:port
  #
  # format:
  #	port
  #   or
  #	host:port
  #   or
  #	ipaddr:port
  #
  # host defaults to 'localhost', 127.0.0.1
  # [REQUIRED]
  #
	update	=> '127.0.0.1:10004',

  };

=cut


sub web_report {
  my $wconf = shift;
  my $type = $ARGV[0] ? 1 : 0;
  my $txt = 'failed: nothing processed';
  while (1) {
    last if ($txt = chk_wconf($wconf));	# exit on bad config file
    my $sin = $wconf->{update} || 0;
    if ($wconf->{cache}) {		# if cache exists, it has been checked
      my $cfile = $wconf->{cache} .'.'. $type;
      if (chkcache($cfile,$wconf->{refresh})) {
	eval {
		local *CACHE;
		local $/ = undef;
		open(CACHE,$cfile) or die "could not open cache '$cfile'";
		$txt = <CACHE>;
		close CACHE;
	};
        $txt = $@ if $@;
       last;
      }
      elsif ($sin) {	# dump enabled
	$txt = 'unknown dump request response';
# sync stats file and unconditionally request a dump
	last if ($txt = rqst_dump($sin,$wconf->{stats},0,$wconf->{updto}));
# lock cache file
	my($lock,$file) = get_lock($cfile .'.tmp',$wconf->{updto},0117);
	if ($@) {						# punt if lock error
	  $txt = $@;
	  last;
	}
	$txt = report($file,$wconf->{stats},$type);	# write report to cache
	close $file;
	if ($txt) {					# there was an error
	  close $lock;
	  last;
	}
	rename $cfile .'.tmp', $cfile;			# atomic move
	close $lock;
      }
      else {
	;	# DUMP is not enabled, do we want an error code? maybe they used SIG USR1
      }
      local *REPORT;
      if (open(REPORT,$cfile)) {
	foreach(<REPORT>) {
	  print $_;					# print to STDOUT
	}
	close REPORT;
      } else {
	$txt = "could not open '$cfile'";
      }
      last;
    }
    elsif ($sin) {	# cache file not configured, generate report directly from stats file
      last if ($txt = rqst_dump($sin,$wconf->{stats},$wconf->{refresh},$wconf->{updto}));
    } else {
      ;		# DUMP is not enabled, do we want an error code? maybe they used SIG USR1
    }
    $txt = report(*STDOUT,$wconf->{stats},$type);	# report to stdout
    last;
  } # end while(1)
  print $txt,"\n" if $txt;	# spit out any errors
}

=item * $timestring = my_time($epoch_seconds);

Convert seconds since the epoch into a formated local time string
of the form:

  Month-text day hh::mm::ss

  input:	seconds since the epoch
  returns:	local time string

=cut

my @months = qw(jan feb mar apr may jun jul aug sep oct nov dec);

sub my_time {
  my($time) = shift;
  my ($sec,$min,$hour,$mday,$mon) = localtime($time);
  return sprintf("%s %02d %02d:%02d:%02d",$months[$mon],$mday,$hour,$min,$sec);
}
 
=item * $port = dyn_bind($sock,$netaddr);

	re-exported from Net::NBsocket

Attempt to bind a socket to the IP address and randomly assigned
port number, in the range 49152 through 65535. Fails after 100 attempts

  input:	socket
		netaddr as returned by inet_aton
  returns:	port number or undef


=item * $handle = xhandle($program_string);

Open a program string for read and return handle.

  input:	program string
  returns:	handle or undef on failure to open

=cut

sub xhandle {
  local *xHandle;
  if (open(xHandle,$_[0] .'|')) {
    return *xHandle;
  } else {
    return undef;
  }
}

=item * $rv = rem_dump($conf);

Dump and retrieve stats files from remote hosts and localhost if present.

  input:	hash pointer to config
  returns:	true on success

=cut

# subroutine to dump stats files on remote (and local) hosts
#
# input:	config hash
# returns:	true on success
#
sub rem_dump {
  my $wconf = shift;
  my $ssh = $wconf->{ssh} .' ';
  my $rsync = $wconf->{rsync} .' -utz -e '. $ssh .' ';
  $wconf->{cache} =~ m|[^/]+$|;
  my $dir = $` || './';
  my %src;
  local(*SDTERR);		# redirect error messages from rsync and ssh
  open STDERR, '>/dev/null';
  foreach (keys %{$wconf->{src}}) {
    $src{$_} = xhandle($ssh . $_ .' '. $wconf->{src}->{$_}->{exec});
  }
  if (exists $wconf->{update}) {
    rqst_dump($wconf->{update},$wconf->{stats},$wconf->{refresh},$wconf->{updto});
  }
  my $debugtxt = '';
  foreach (keys %src) {		# wait for ssh completion
    my $xhndl = $src{$_};
    next unless $xhndl;
    undef local $/;
    $debugtxt .= <$xhndl>;
    close $xhndl;
  }
  foreach (keys %src) {
    $src{$_} = xhandle($rsync . $_ .':'. $wconf->{src}{$_}->{fetch} .' '. $dir .'/'. $_ . '.stats');
  }
  foreach (keys %src) {		# wait for rsync completion
    my $xhndl = $src{$_};
    next unless $xhndl;    
    undef local $/;
    $debugtxt .= <$xhndl>;    
    close $xhndl;    
  }
  return 1;
}

=item * $rv = rem_update($config);

Update the composite stats report

  input:	hash pointer to config
  returns:	true on success

=cut

sub rem_update {
  require Data::Dumper;
  my $c = shift;
  my $cache = $c->{cache};
  return undef unless $cache =~ m|/[\w\.\-]+$|;
  $c->{cache} =~ m|[^/]+$|;
  my $dir = $` || './';
  $cache .= '.1';		# unconditionally type1
  my $comp = $dir .'composite.stats';
  my @files;
  foreach (keys %{$c->{src}}) {
    push @files, $dir .'/'. $_ .'.stats';
  }
  if (exists $c->{update}) {	# update local host if configured
    push @files, $c->{stats};
  }
#               B => 5678,	    # bytes accumulated
#               C => 1234,	    # counts
#               E => 124444,	    # count epoch
#               N => ['hostname',], # hostname(s) for this IP
#               R => 2345,	    # rate
#               S => 123456,	    # count start time
#               T => 123455,	    # TTL timeout of PTR record
#               W => 7890,	    # bandWidth

  my $hits = 0;
  my $bytes = 0;
  my $users = 0;
  my $txt = '';
  my $stats = {};
  my $loadavg;
  if ( eval { require Sys::LoadAvg} ) {
    $loadavg = \&Sys::LoadAvg::loadavg;
  }
  foreach (@files) {
    my($sf,$ft) = read_stf($_);
    $hits += $1 if $ft =~ /hits:\s+(\d+)/;
    $bytes += $1 if $ft =~ /bytes:\s+(\d+)/;
# some users may be in all hosts, this is not a reasonable sum
#    $users += $1 if $ft =~ /users:\s+(\d+)/;
    $txt .= $ft;
    foreach (keys %$sf) {
      if ($loadavg) {			# quench CPU usage if it is high
	my @la = &$loadavg;
	if ($la[0] > 0.7) {
	  sleep 1;
	}
      }
      if (exists $stats->{$_}) {
        $stats->{$_}->{B} += $sf->{$_}->{B};
        $stats->{$_}->{C} += $sf->{$_}->{C};
        $stats->{$_}->{E} = $sf->{$_}->{C}
		if $stats->{$_}->{E} < $sf->{$_}->{C};
        $stats->{$_}->{R} += $sf->{$_}->{R};
        $stats->{$_}->{W} += $sf->{$_}->{W};
	my $ipk = $_;
	foreach my $n (@{$sf->{$ipk}->{N}}) {
	  unless (grep(/$n/,@{$stats->{$ipk}->{N}})) {
	    push @{$stats->{$ipk}->{N}}, $n;
	  }
	}
      }
      else {
        $stats->{$_} = $sf->{$_};
      }
    }
  }

  local *CACHE;
  open (CACHE,'>'. $comp .'.tmp');
  print CACHE $txt;
  print CACHE qq|
# grand total all hosts
# hits: \t$hits per minute
# bytes:\t$bytes per second
|;
  print CACHE 'my ',&Data::Dumper::Dumper($stats);
  close CACHE;
  rename $comp .'.tmp', $comp;

  open (CACHE,'>'. $cache .'.tmp');
  print report(*CACHE,$comp,1),"\n";
  close CACHE;
  rename $cache .'.tmp', $cache;
}

=item * $rv = chk_lock ($lockfile);

  input:	lockfile name
  return:	0	lock released
		1	lock expired, 2 min

=cut

sub chk_lock {
  my $lockf = shift;
  return 0 unless -e $lockf;
  local *F;
  return 0 unless open F, $lockf;
  (my $otherid = <F>) =~ s/\s+//;
  close F;
  my $wait = 120;		# wait a couple of minutes if necessary
  while ($wait > 0 && kill 0, $otherid) {
    sleep 1;
    $wait--;
  }
  return $wait ? 0 : 1;
}

=item * rem_report($wconf);

Similar to sub 'web_report' above but retrieves and assembles a composite report
from multiple hosts running nc.sniffer

HOWTO setup this operation.

	1) read the config section of 
	   nc.sniffer.coalesce.cgi.sample
	2) read the config section of
	   nc.sniffer.dump.pl.sample

On the remote host, install nc.sniffer.dump.pl in an appropriate sandbox
account and install an ssh certificate to permit access to the sandbox ssh
executable as well as the directory from which to rsync the stats file on
that host.

nc.sniffer.dump.pl should be installed
mode 755 or as appropriate to be accessed remotely by
the ssh -e function.

On the web host, configure nc.sniffer.coalesce.cgi and place the execution
cgi string in your web page to produce the report

  usage: <!--#exec cmd="./nc.sniffer.coalesce.cgi" -->

=cut

sub rem_report {
  my $wconf = shift;
  my $txt = '';
  my $type = 1;			# unconditional for remote reports
  while (1) {
    last if ($txt = rem_wchk($wconf));	# exit on bad config file
    my $cfile = $wconf->{cache} .'.'. $type;
    my $lockf = $cfile .'.lock';
    chk_lock($lockf);			# check if another process is doing the same thing
    if (chkcache($cfile,$wconf->{refresh})) {
	eval {
		local *CACHE;
		local $/ = undef;
		open(CACHE,$cfile) or die "could not open cache '$cfile'";
		$txt = <CACHE>;
		close CACHE;
	};
        $txt = $@ if $@;
	last;
    }
    local *LOCK;
    if ( open (LOCK,'>'. $lockf) ) {	# should never fail
      print LOCK $$;
      close LOCK;
    }    
    unless (rem_dump($wconf)) {
      $txt = 'could not dump remotes';
      last;
    }
    unless (rem_update($wconf)) {
      $txt = 'could not update composite stats';
      last;
    }
    local *REPORT;
    if (open(REPORT,$cfile)) {
      foreach(<REPORT>) {
        print $_;			# print to STDOUT
      }
      close REPORT;
    } else {
      $txt = "could not open '$cfile'";
    }
    unlink $lockf;
    last;
  } # end while(1)
  print $txt,"\n" if $txt;		# spit out any errors
}

=pod

=back

=head1 EXPORT_OK

	read_stf
	by_cidr24
	by_name
	report
	presync
	sync
	chkcache
	get_lock
	chk_wconf
	rem_wchk
	rqst_dump
	web_report
	my_time
	dyn_bind
	xhandle
	rem_dump
	rem_update
	chk_lock
	rem_report

=head1 COPYRIGHT

Copyright 2006 - 2013, Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License (except as noted
otherwise in individuals sub modules)  published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=cut

1;
