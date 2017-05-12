#!/usr/bin/perl

package Net::DNSBL::Utilities;
use strict;
#use diagnostics;

use File::SafeDO qw(
	DO
	doINCLUDE
);
use vars qw(
	$VERSION @ISA @EXPORT_OK *UDP 
	$A1271 $A1272 $A1273 $A1274 $A1275 $A1276 $A1277
	$SKIP_POSIX $SKIP_NetAddrIP $AuthBit $RABit
);
$A1271 = $A1272 = $A1273 = $A1274 = $A1275 = 0;
$AuthBit = $SKIP_POSIX = $SKIP_NetAddrIP = 0;
use AutoLoader 'AUTOLOAD';
require Exporter;
@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

*DO = \&File::SafeDO::DO;
*doINCLUDE = \&File::SafeDO::doINCLUDE;

@EXPORT_OK = qw(
        s_response 
        not_found  
        write_stats
	bystat
        statinit
        cntinit
        DO
	doINCLUDE
        open_udpNB
	list2NetAddr
	matchNetAddr
	list2hash
	A1271
	A1272
	A1273
	A1274
	A1275
	A1276
	A1277
	list_countries
	setAUTH
	setRA
);

use Net::DNS::Codes qw(
	BITS_QUERY
	QR
	NXDOMAIN
	C_IN
	AA
	RA
);
use Net::DNS::ToolKit 0.16 qw(
	newhead
);
use Net::DNS::ToolKit::RR;
#use Net::DNS::ToolKit::Debug qw(
#	print_head
#	print_buf
#);

# used a lot, create once per session
*UDP = \getprotobyname('udp');

1;
__END__

=head1 NAME

Net::DNSBL::Utilities - functions for DNSBL daemons

=head1 SYNOPSIS

  use Net::DNSBL::Utilities qw(
        s_response 
        not_found  
        write_stats
	bystat
        statinit
        cntinit
	list2hash
        open_udpNB
        DO
	doINCLUDE
	list2NetAddr
	matchNetAddr
	list_countries
	setAUTH
	setRA
        A1271
        A1272
        A1273
        A1274
        A1275
	A1276
	A1277
  );

  s_response($mp,$resp,$id,$qdcount,$ancount,$nscount,$arcount);
  not_found($put,$name,$type,$id,$mp,$srp);
  write_stats($sfile,$cp,$sinit,$csize,$cache);
  $rv = bystat($cp);
  $timestamp = statinit($Sfile,$cp);
  cntinit($DNSBL,$cp);
  list2hash(\@list,$cp,$val);
  $sock = open_udpNB();
  $rv = DO($file,$nowarnings)
  $rv = doINCLUDE($file,$nowarnings);
  $rv=list2NetAddr(\@inlist,\@NAobject);
  $rv = matchNetAddr($ip,\@NAobject);
  ($countries,$code3s,$names) = list_countries;
  setAUTH(true/false);
  setRA(true/false);
  $netaddr = A1271;
  $netaddr = A1272;
  $netaddr = A1273;
  $netaddr = A1274;
  $netaddr = A1275;
  $netaddr = A1276;
  $netaddr = A1277;

=head1 DESCRIPTION

B<Net::DNSBL::Utilities> contains functions used to build DNSBL
emulator daemons.

=over 4

=item * s_response($mp,$resp,$id,$qdcount,$ancount,$nscount,$arcount);

Put a short response into the message buffer pointed to by $mp by
sticking a new header on the EXISTING received query.

  input:	msg pointer,
 		id of question,
 		qd, an, ns, ar counts
  returns: 	nada

=cut

sub s_response {
  my($mp,$resp,$id,$qdcount,$ancount,$nscount,$arcount) = @_;
  my $newhead;
  my $off = newhead(\$newhead,
	$id,
	BITS_QUERY | $AuthBit | QR | $resp,
	$qdcount,$ancount,$nscount,$arcount,
  );
  substr($$mp,0,$off) = $newhead;
}

=item * not_found($put,$name,$type,$id,$mp,$srp);

Put a new 'not found' response in the buffer pointed to by $mp.

  input:	put,
		name,
		type,
		id,
		message buffer pointer,
		SOA record pointer
  returns:	nothing

=cut

sub not_found {
  my($put,$name,$type,$id,$mp,$srp) = @_;
  my $off = newhead($mp,
	$id,
	BITS_QUERY | $AuthBit | QR | NXDOMAIN,
	1,0,1,0,
  );
  my @dnptrs;
  ($off,@dnptrs) = $put->Question($mp,$off,$name,$type,C_IN);
#  ($off,@dnptrs) = 
  $put->SOA($mp,$off,\@dnptrs,@$srp);
}

=item * write_stats($sfile,$cp,$sinit,$csize,$cache);

Write out the contents of the accumulated statistics buffer to the STATs file.

  input:	statistics file path,
		pointer to count hash,
		initial timestamp line text
		cache flag/max size
		current cache size
  returns:	nothing

=cut

sub write_stats {
  my($sfile,$cp,$sinit,$csize,$cache) = @_;
  if ($sfile) {         # record sfile on DNSBL lookups
    if (open(S,'>'. $sfile .'.tmp')) {
      print S '# last update '. localtime(time) ."\n";
      print S $sinit;
      if ($csize) {	# if cacheing
	print S "# cache allocated: $csize, used: $cache\n";
      }
      my $total = 0;
      foreach(sort {
		bystat($cp); 
	  } keys %$cp) {
	next if $_ =~ /^(White|Passed)/;
	$total += $cp->{"$_"};
	print S $cp->{"$_"}, "\t$_\n";
      }
      print S "# $total\ttotal rejects\n#\n";
      foreach(qw(WhiteList Passed)) {
	print S $cp->{$_},"\t$_\n" if exists $cp->{$_};
      }
      close S;
    }
    rename $sfile .'.tmp', $sfile;
  }
}

=item * $rv = bystat($cp);

Return sort value +-1 or 0 for stat sort

  input:	$a,$b sort values
		pointer to count hash
  returns:	sort decision value

=cut

sub bystat {
  my $cp = shift;
	  if ($a =~ /\./ && $b !~ /\./) {		# sort domains to top
	    -1;
	  }
	  elsif ($a !~ /\./ && $b =~ /\./) {
	    1;
	  }
	  elsif ($a =~ /Black|White|Pass/ &&		# sort White/Black/Passed to bottom
		 $b !~ /Black|White|Pass/) {
	    1;
	  }
	  elsif ($a !~ /Black|White|Pass/ &&
		 $b =~ /Black|White|Pass/) {
	    -1;
	  }
	  else {					# sort by value, then alpha
	    ($cp->{$b} <=> $cp->{$a}) || $a cmp $b;
	  }
}

=item * $timestamp = statinit($Sfile,$cp);

Initialize the contents of the statistics hash with the file contents
of $Sfile, if $Sfile exists and there are corresponding entries in 
the statistics hash. i.e. the statistics hash keys must first be
initialized with the DNSBL (or LABEL) names.

  input:	statistics file path,
		pointer to count hash
  returns:	timestamp line for file
		or undef on failure

=cut

sub statinit {
  my($Sfile,$cp) = @_;
  my $sti = '# stats since '. localtime(time) ."\n";
  if ($Sfile) {							# stats entry??
    if ( -e $Sfile) {						# old file exists
      if (open(S,$Sfile)) {					# skip if bad open
	foreach(<S>) {
	  $sti = $_ if $_ =~ /# stats since/;		# use old init time if present
	  next unless $_ =~ /^(\d+)\s+(.+)/;
	  $cp->{"$2"} = $1 if exists $cp->{"$2"}		# add only existing dnsbls
	}
	close S;
	return $sti;
      }
    }
    elsif ($Sfile =~ m|[^/]+$| && -d $`) {			# directory exists, no file yet
      return $sti;						# ok to proceed
    }
  }
  return undef;
}

=item * cntinit($DNSBL,$cp);

Initialize the statistics count hash with DNSBL keys and set the counts to zero.

For compatibility with other applications, LABEL names other than the
DNSBL's must NOT contain '.' Only the keys in the DNSBL hash that contain
'.'s are added to the count hash.

The count hash is first emptied if it is not null to begin with.

  input:	pointer to DNSBL hash,
		pointer to counts hash
  returns:	nothing

=cut

sub cntinit {
  my ($DNSBL,$cp) = @_;
  %$cp = ();
  foreach(keys %$DNSBL) {
    next unless $_ =~ /.+\..+/; 				# skip non-dnsbl entries
    $cp->{"$_"} = 0;	   					# set up statistics counters for preferential sort
  }
  $cp->{WhiteList} = 0;					# add entries for known good/bad guys
  $cp->{BlackList} = 0;
  $cp->{Passed} = 0;
}

=item * list2hash(\@list,$cp,$val);

Add a list of names as keys to the statistics count hash and set the hash
value to $val or zero if $val is not present.

For compatibility with other applications, the labels in "list" must not
contain the character '.'

  input:	pointer to list of labels,
		pointer to counts hash,
		value [optional]
  returns:	nothing

=cut

sub list2hash {
  my ($lp,$cp,$val) = @_;
  return unless $lp;
  $val = 0 unless $val;
  foreach(@$lp) {
    $cp->{"$_"} = $val;
  }
}

=item * $rv = DO($file,$nowarnings);

This is a fancy 'do file'. It first checks that the file exists and is
readable, then does a 'do file' to pull the variables and subroutines into
the current name space.

See the documentation L<File::SafeDO>

  input:	file/path/name
  returns:	last value in file
	    or	undef on error
	    prints warning

=item * $rv = DO($file,$nowarnings);

This is a fancy 'do file'. It first checks that the file exists and is
readable, then does a 'do file' to pull the variables and subroutines into
the current name space.

See the documentation L<File::SafeDO>

  input:	file/path/name
  returns:	last value in file
	    or	undef on error
	    prints warning

=item * $sock = open_udpNB();

Open and return a non-blocking UDP socket object

  input:	none
  returns:	pointer to socket object
		or undef on failure

=cut

sub open_udpNB {
#  my $proto = getprotobyname('udp');
  _loadSocket() unless $A1271;
  unless ($SKIP_POSIX) {
    require POSIX;
    $SKIP_POSIX = 1;
  }
  my $flags;
  local *SOCKET;
  return undef unless socket(SOCKET,&Socket::PF_INET,&Socket::SOCK_DGRAM,$UDP);
  return *SOCKET if (($flags = fcntl(SOCKET,&POSIX::F_GETFL(),0)) || 1) &&
		     fcntl(SOCKET,&POSIX::F_SETFL(),$flags | &POSIX::O_NONBLOCK());
  close SOCKET;
  return undef;
}

=item * $rv=list2NetAddr(\@inlist,\@NAobject);

Build of NetAddr object structure from a list of IPv4 addresses or address
ranges. This object is passed to B<matchNetAddr> to check if a given IP
address is contained in the list.

  input:	array reference pointer
		to a list of addresses

  i.e.		11.22.33.44
		11.22.33.0/24
		11.22.33.0/255.255.255.0
		11.22.33.20-11.22.33.46
		11.22.33.20 - 11.22.33.46

  output:	Number of objects created
		or undef on error

The NAobject array is filled with NetAddr::IP::Lite object references.

=cut

sub list2NetAddr {
  my($inref,$outref) = @_;
  return undef 
	unless ref $inref eq 'ARRAY'
	&& ref $outref eq 'ARRAY';
  unless ($SKIP_NetAddrIP) {
    require NetAddr::IP::Lite;
    $SKIP_NetAddrIP = 1;
  }
  @$outref = ();
  my $IP;
  no strict;
  foreach $IP (@$inref) {
    $IP =~ s/\s//g;
	# 11.22.33.44
    if ($IP =~ /^\d+\.\d+\.\d+\.\d+$/o) {
      push @$outref, NetAddr::IP::Lite->new($IP), 0;
    }
	# 11.22.33.44 - 11.22.33.49
    elsif ($IP =~ /^(\d+\.\d+\.\d+\.\d+)\s*\-\s*(\d+\.\d+\.\d+\.\d+)$/o) {
      push @$outref, NetAddr::IP::Lite->new($1), NetAddr::IP::Lite->new($2);
    }
	# 11.22.33.44/63
    elsif ($IP =~ m|^\d+\.\d+\.\d+\.\d+/\d+$|) {
      push @$outref, NetAddr::IP::Lite->new($IP), 0;
    }
	# 11.22.33.44/255.255.255.224
    elsif ($IP =~ m|^(\d+\.\d+\.\d+\.\d+)/(\d+\.\d+\.\d+\.\d+)$|o) {
      push @$outref, NetAddr::IP::Lite->new($1,$2), 0;
    }
# ignore un-matched IP patterns
  }
  return (scalar @$outref)/2;
}

=item * $rv = matchNetAddr($ip,\@NAobject);

Check if an IP address appears in a list of NetAddr objects.

  input:	dot quad IP address,
		reference to NetAddr objects
  output:	true if match else false

=cut

sub matchNetAddr { 
  my($ip,$naref) = @_;
  return 0 unless $ip && $ip =~ /\d+\.\d+\.\d+\.\d+/;
  $ip =~ s/\s//g;
  $ip = new NetAddr::IP::Lite($ip);
  my $i;
  for($i=0; $i <= $#{$naref}; $i += 2) {
    my $beg = $naref->[$i];
    my $end = $naref->[$i+1];
    if ($end) {
      return 1  if $ip >= $beg && $ip <= $end;
    } else {
      return 1 if $ip->within($beg);
    }
  }  
  return 0;
}

=item * ($countries,$code3s,$names) = list_countries;

The function returns the list of 2 character, 3 character and country code
names from the Geo::IP::PurePerl module if it is installed.

  input:	none
  returns:	\@countries,\@code3s,\@names
		blessed into callers namespace

NOTE: this process is very inefficient and should not be called in a
repetitive fashion.

If Geo::IP::PurePerl is not installed, the function returns and empty array
and sets $@;

=cut

sub list_countries {
  eval {
    require Geo::IP::PurePerl or die "could not find need module Geo::IP::PurePerl\n";
  };
  return () if $@;
  my $key = 'Geo/IP/PurePerl.pm';
  my $file = $INC{$key};
  my $stuff;
  open(S,$file);
  while ($stuff = <S>) {
    last if $stuff =~ /countries\s+=\s+\(/;
  }
  while ($stuff .= <S>) {
    last if (@_ = $stuff =~ /;/g) >= 3;
  }
  close S;
  my($countries,$code3s,$names) = ([],[],[]);
  $stuff =~ s/my\s+\@/\@\$/g;

  eval "$stuff";

  my $caller = caller;
  bless $countries, $caller;
  bless $code3s, $caller;
  bless $names, $caller;
  return ($countries,$code3s,$names);
}

=item * setAUTH(true/false);

Set the Authoratitive Answer bit true or false for all replys

  input:	true/false
  returns:	nothing

=cut

sub setAUTH {
  if ($_[0]) {
    $AuthBit = AA();
  } else {
    $AuthBit = 0;
  }
}

=item * setRA(true/false);

Set the Recursion Allowed bit true or false for all replys

  input:	true/false
  returns:	nothing

=cut

sub setRA {
  if ($_[0]) {
    $RABit = RA();
  } else {
    $RABit = 0;
  }
}

=item * $netaddr = A127x

Functions A1271, A1272, A1273, etc..., return the packed network address for
127.0.0.1, 127.0.0.2, etc.... respectively

=back

=cut

sub _loadSocket {
  require Socket;
  import Socket(@Socket::Export);
  $A1271 = inet_aton('127.0.0.1');
  $A1272 = inet_aton('127.0.0.2');
  $A1273 = inet_aton('127.0.0.3');
  $A1274 = inet_aton('127.0.0.4');
  $A1275 = inet_aton('127.0.0.5');
  $A1276 = inet_aton('127.0.0.6');
  $A1277 = inet_aton('127.0.0.7');
}

sub A1271 {
  _loadSocket unless $A1271;
  $A1271;
}

sub A1272 {
  _loadSocket unless $A1272;
  $A1272;
}

sub A1273 {
  _loadSocket unless $A1273;
  $A1273;
}

sub A1274 {
  _loadSocket unless $A1274;
  $A1274;
}

sub A1275 {
  _loadSocket unless $A1275;
  $A1275;
}

sub A1276 {
  _loadSocket unless $A1276;
  $A1276;
}

sub A1277 {
  _loadSocket unless $A1277;
  $A1277;
}

=head1 DEPENDENCIES

	Net::DNS::Codes
	Net::DNS::ToolKit

=head1 EXPORT_OK

	s_response 
	not_found  
	write_stats
	bystat
	statinit
	cntinit
	list2hash
	open_udpNB
	DO
	list2NetAddr
	matchNetAddr
	list_countries
	setAUTH
	setRA
	A1271
	A1272
	A1273
	A1274
	A1275
	A1276
	A1277

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 COPYRIGHT

Copyright 2003 - 2007, Michael Robinton & BizSystems
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 SEE ALSO

L<Net::DNS::Codes>, L<Net::DNS::ToolKit>, L<Mail::SpamCannibal>

=cut

1;
