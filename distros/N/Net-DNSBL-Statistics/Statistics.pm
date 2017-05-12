#!/usr/bin/perl
package Net::DNSBL::Statistics;

use strict;
#use diagnostics;
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	newhead
	gethead
	inet_ntoa
);
use Net::DNS::ToolKit::RR;
use Net::DNS::ToolKit::Utilities qw(
	id
	revIP
);
use Net::DNSBL::Utilities qw(
	DO
	list2NetAddr
	matchNetAddr
);
#use Net::DNS::ToolKit::Debug qw(
#	print_head
#	print_buf
#);

use vars qw(
	$VERSION @ISA @EXPORT_OK
);
require Exporter;
@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.14 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
        run
	plaintxt
	htmltxt
);

# undocumented $DEBUG values
#
#	1	=> return @ip array
#	2	=> return %dnsbls initialization hash
#	3	=> return ($iptr,$regexptr) ignore, regexp ptrs
#	4	=> return %ips union aging hash
#	5	=> return %qc hash
#	other	=> return un-converted %dnsbls hash

=head1 NAME

Net::DNSBL::Statistics - gather DNSBL Statistics

=head1 SYNOPSIS

  use Net::DNSBL::Statistics qw(
        run
	plaintxt
	htmltxt
  );

  %dnsblcounts=run(\%config,$NonBlockSock,$sockaddr_in);
  $text = plaintxt(\%config,\%dnsblscounts);
  $html = htmltxt(\%config,\%dnsblcounts);

=head1 DESCRIPTION

B<Net::DNSBL::Statistics> is the Perl module that collects statistics on the
interrogation success for a list of IP addresses against a list of DNSBL's.
The module is used to implement the reproting script B<dnsblstat>.

=head1 CONFIGURATION FILE

With the addition of a few elements, the configuration file for B<dnsblstat> 
shares a common format with the Mail::SpamCannibal sc_BLcheck.pl script, 
facilitating common maintenance of DNSBL's for your MTA installation. 

The sample configuration file
B<statistics.conf.sample> is heavily commented with the details for each
configuration element.

=head1 SYSTEM SIGNALS

B<dnsblstat> responds to the following system signals:

=over 2

=item * TERM

Script is terminated.

=back

=head1 PERL MODULE DESCRIPTION - Script Implementation

B<Net::DNSBL::Statistics> provides most of the functions that implement
B<dnsblstat> which is a script that collects statistics from a list of IP
address interrogations against a list of DNSBL's

=head1 dnsblstat usage

How to use B<dnsblstat>

  Syntax: dnsblstat path/to/config.file
    or
        dnsblstat -t path/to/config.file
        dnsblstat -w path/to/config.file

Normally dnsblstat prints a sorted list (by count)
of the DNSBL's interrogated with their reply count, 
percentage of the total count, and any comments from
the DNSBL's 'comment' key field in the config file.
The 'comment' field may contain html markup text.

  i.e.
  44 100.0%  TOTAL IP's interrogated
  41  93.2%  UNION of all results   
  34  77.3%  dnsbl.sorbs.net comment
  ........

The -t switch will print a start and stop time.

  i.e.
  # start: Fri Jan  4 17:46:44 2008
  # stop : Fri Jan  4 17:58:21 2008

The -w switch will put the output into an HTML table
without the E<lt>tableE<gt> statement E<lt>/tableE<gt>>., a commment as above
and with an E<lt>a href="..."E<gt>dnsbl nameE<lt>/aE<gt> statement replacing
the dnsbl name if the 'url' key is present in the config file.

  i.e.
  A one line example corresponding to the text line above:

  34  77.3% dnsbl.sorbs.net

  with a 'comment' key of: 127.0.0.2,5,7,8,9,10,12
  and a 'url' key of:      http://www.au.sorbs.net/using.shtml

  <tr class=dnsbl><td align=right>34</td>
    <td align=right>77.3%</td>
    <td align=left><a
     href="http://www.au.sorbs.net/using.shtml">dnsbl.sorbs.net</a></td>
    <td align=left>127.0.0.2,5,7,8,9,10,12</td>
  </tr>

=head1 Net::DNSBL::Statistics FUNCTIONS

=over 4

=item * %dnsblscounts=run(\%config,$NonBlockSock,$sockaddr_in);

Returns the total number of IP's interrogated (IP list less white listed items) and a hash of DNSBL
names and their respective SPAM reply counts or equivalent for 'in-addr.arpa' and GENERIC.

  input:   config pointer,
	   non-blocking socket descriptor,
	   sockaddr_in for local DNS host

  returns: dnsbl count hash

The dnsbl count hash will have two added keys:

	TOTAL	the total number of interrogations less whitelist
	UNION	the total number of spam 'hits'

  HINTs:   use Net::NBsocket qw( open_udbNB sockaddr_in );
	   use Net::DNS::ToolKit qw( get_ns );

	   my $sock = open_udpNB();
	   my $sockaddr_in = sockaddr_in(53, scalar get_ns());

=cut

my $w = 0;
my @w = qw( \ | / - );
sub whirl {
  return;
  print STDERR "\r",$w[$w],"\r";
  $w = 0 if ++$w > $#w;
}

sub run {
  my($conf,$Usock,$U_Sin,$DEBUG) = @_;
  my %ips;
  return () unless $conf->{FILES};
  my @files = (ref $conf->{FILES}) ? @{$conf->{FILES}} : ($conf->{FILES});

  local *F;
  foreach (@files) {
    next unless -e $_ && open F, $_;
    foreach (<F>) {
      next unless $_ =~ /\S/;
      next if $_ =~ /^\s*#/;
      next unless $_ =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
      $ips{"$1"} = undef;
    }
    close F;
  }
  my @ips = keys %ips;
  %ips = ();

  return @ips if $DEBUG && $DEBUG == 1;

  my @NAignor;
  if ($conf->{IGNORE}) {
    list2NetAddr($conf->{IGNORE},\@NAignor);
  }

############## configure %dnsbl has for accumulating stats ###############
  my @DNSBLs	= grep( $_ =~ /^[0-9a-z]+\.[0-9a-z]/i && $_ !~ /in-addr/i, keys %{$conf});

  my %dnsbls;

  foreach(@DNSBLs) {
    $dnsbls{"$_"} = {
	C	=> 0,		# count
	TO	=> 0,		# timeouts
    };
  }

#### %dnsbls configuration complete, configure maximum union timeout
  my $uto = 0;
  foreach(keys %dnsbls) {
    next unless exists $conf->{"$_"} &&
		exists $conf->{"$_"}->{timeout};
    next if $conf->{"$_"}->{timeout} < $uto;
    $uto = $conf->{"$_"}->{timeout};
  }    

  my($iptr,$regexptr);
  my $needPTR = 0;
  if ($conf->{'in-addr.arpa'}) {
    $dnsbls{'in-addr.arpa'} = { C => 0 };
    $needPTR = $conf->{'in-addr.arpa'}->{timeout} || 30;
  }
  if ($conf->{GENERIC}) {
    $dnsbls{GENERIC} = { C => 0 };
    $needPTR = ($conf->{GENERIC}->{timeout} || 30)
	unless $needPTR;
    undef $regexptr unless ($regexptr = $conf->{GENERIC}->{regexp}) &&
			ref $regexptr eq 'ARRAY' && @$regexptr > 0;
    undef $iptr unless ($iptr = $conf->{GENERIC}->{ignore}) &&
			ref $iptr eq 'ARRAY' && @$iptr > 0;
  }
### adjust $uto to account for generic retries and in-addr.arpa timeouts
  $uto = $needPTR
	if $uto < $needPTR;
  $uto = 30 unless $uto;
#### maximum $uto = 2x max delay + a little
  $uto *= 2;
  $uto += 5;

  return %dnsbls if $DEBUG && $DEBUG == 2;

  return ($iptr,$regexptr) if $DEBUG && $DEBUG == 3;

  my %qc = (
	'in-addr'	=> 0,
	'regular'	=> 0,
# retries below
	'generic'	=> 0,
	'retry-r'	=> 0,
  );

  my %queue;
  my $fileno = fileno($Usock);
  my $vin = '';
  vec($vin,$fileno,1) = 1;
  my $Run = 1;
  local $SIG{TERM} = sub {$Run = 0};

  my $qsize = keys %dnsbls;
  my $then = time;
  my $uage = $then;		# union aging every 5 seconds
  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
  my($rin,$rout,$win,$wout,$ip,$packet,$name,$id,$msg,$bl,$now,$revIP,$nfound,$answer,$ttl,$rdl,@rdata,@sndQ);

LOOP:
  while ($Run) {
    my $Q = keys %queue;
    if ($qsize > $Q && ($ip = shift @ips)) {	# run results for next IP if queue is not double full
      next if matchNetAddr($ip,\@NAignor);
      ++$dnsbls{TOTAL}->{C};
      $now = time;
      $revIP = revIP($ip);
      if ($needPTR) {
	$id = makid(\%queue);
	$name =  $revIP .'.in-addr.arpa';
	$packet = makequery($put,$id,$name,T_PTR());
	$queue{$id} = {
		B	=> 'in-addr.arpa',
		Q	=> $packet,
		T	=> $now + $needPTR,	# timeout
		R	=> 0,			# retry
		X	=> $revIP,
	};
	push @sndQ, $packet;
	++$qc{'in-addr'};
      }
    
      foreach $bl (@DNSBLs) {
	next if $dnsbls{"$bl"}->{TO} > 5;	# ignore this BL if it timed out to many times
	$id = makid(\%queue);
	$name = $revIP .'.'. $bl;
	$packet = makequery($put,$id,$name,T_A());
	$queue{$id} = {
		B	=> "$bl",
		Q	=> $packet,
		T	=> $now + ($conf->{"$bl"}->{timeout} || 30),
		R	=> 0,
		X	=> $revIP,
	};
	push @sndQ, $packet;
	++$qc{regular};
      }
    }

# wait for some responses
    $rin = $vin;
    if (@sndQ) {
      $win = $vin;
    } else {
      $win = '';
    }
    $nfound = select($rout=$rin,$wout=$win,undef,0.5);	# tick each second
    if ($nfound > 0) {
      while (vec($wout,$fileno,1) && @sndQ) {
	$packet = shift @sndQ;
#print STDERR "WRITE\n";
#print_buf(\$packet);
#print STDERR "\n";
	send($Usock,$packet,0,$U_Sin);
	whirl() if $DEBUG;
      }
      if (vec($rout,$fileno,1)) {
	undef $msg;
	next unless recv($Usock,$msg,,PACKETSZ,0);	# ignore receive errors
	next unless length($msg) > HFIXEDSZ;		# ignore short packets
#print STDERR "RECEIVE\n";
#print_buf(\$msg);
#print STDERR "\n";
	my($off,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,$qdcount,$ancount,$nscount,$arcount);
	($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,$qdcount,$ancount,$nscount,$arcount)= gethead(\$msg);
	next unless
	  $tc == 0 &&
	  $qr == 1 &&
	  $opcode == QUERY &&
	  ($rcode == NOERROR || $rcode == NXDOMAIN || $rcode == SERVFAIL) &&
	  $qdcount == 1 &&
	  exists $queue{$id};

	($off,my($name,$t,$class)) = $get->Question(\$msg,$off);
	next unless $class == C_IN;			# not my question

	$bl = $queue{$id}->{B};
	$revIP = $queue{$id}->{X};
	delete $queue{$id};
	$dnsbls{"$bl"}->{TO} = 0			# reset timeout count
	  unless $bl eq 'in-addr.arpa';
	if ($ancount && $rcode == &NOERROR) {		# if good response
	  $name =~ /(?:\d+\.\d+\.\d+\.\d+\.)/i;
	  next unless lc $bl eq lc $' &&
		($t == T_A || $t == T_PTR);

	  undef $answer;
	  my @generic;
	ANSWER:
	  foreach(0..$ancount-1) {
	    ($off,$name,$t,$class,$ttl,$rdl,@rdata) = $get->next(\$msg,$off);
	    if ($t == T_A) {
	      while($answer = shift @rdata) {
		$ip = inet_ntoa($answer);
		if (grep($ip eq $_,keys %{$conf->{"$bl"}->{accept}})) {
		  ++$dnsbls{"$bl"}->{C};		# bump dnsbl count
		  union(\%dnsbls,\%ips,$revIP,$now + $uto);
#print STDERR "FAILED $name $ip\n";
		  next LOOP;
		}
	      }
	    }
	    elsif ($needPTR && $t == T_PTR && exists $dnsbls{GENERIC}) {
# positive in-addr.arpa responses are ignored
	      push @generic, $rdata[0];
	      next ANSWER;
	    }
	  }
	  if (@generic) {
	    foreach my $g (@generic) {
	      next LOOP if $iptr && grep($g =~ /$_/i, @$iptr);
	      next LOOP if $g && ! grep($g =~ /$_/i, @$regexptr);
	    }
	    ++$dnsbls{GENERIC}->{C};			# bump GENERIC count
	    union(\%dnsbls,\%ips,$revIP,$now + $uto);
#print STDERR "FAILED $name GENERIC\n";
	  }
	}
	elsif ($t == T_A) {
	  next LOOP;					# tis a lookup failure or no response... ignore
	}
	elsif ($needPTR && $t == T_PTR && exists $conf->{'in-addr.arpa'}) {
	  ++$dnsbls{'in-addr.arpa'}->{C};
	  union(\%dnsbls,\%ips,$revIP,$now + $uto);
#print STDERR "FAILED $name ERROR\n";
	  next LOOP;
	}
      }
    }
######################################################################
    else {		# timeout
      $now = time;
      next unless $now > $then;
      $then = $now;
      my @queue = sort {$queue{$a}->{T} <=> $queue{$b}->{T}} keys %queue;
      foreach $id (@queue) {				# check for DNSBL timeouts
	last if $now < $queue{$id}->{T};
	$bl = $queue{$id}->{B};
	if ($bl eq 'in-addr.arpa') {
	  if (exists $conf->{'in-addr.arpa'}) {
	    $revIP = $queue{$id}->{X};
	    delete $queue{$id};
	    ++$dnsbls{'in-addr.arpa'}->{C};
	    union(\%dnsbls,\%ips,$revIP,$now + $uto);
#print STDERR "FAILED $revIP.in-addr.arpa timeout\n";
	  }
	  elsif (exists $dnsbls{GENERIC}) {
	    unless ($queue{$id}->{R}) {
	      $queue{$id}->{R} = 1;			# retry generic queries
	      $queue{$id}->{T} = $now + $needPTR;
	      push @sndQ, $queue{$id}->{Q};
	      ++$qc{generic};
	    }
	    else {
	      delete $queue{$id};
	    }
	  }
	}
	else {		# regular DNSBL
	  unless ($queue{$id}->{R}) {
	    $queue{$id}->{R} = 1;
	    $queue{$id}->{T} = $now + ($conf->{"$bl"}->{timeout} || 30);
	    push @sndQ, $queue{$id}->{Q};
	    ++$qc{'retry-r'};
	  }
	  else {
	    $revIP = $queue{$id}->{X};
	    delete $queue{$id};
	    ++$dnsbls{"$bl"}->{TO};
	  }
	}
      }
      last LOOP unless @ips || keys %queue;		# run through all IP's and remaining queue items
      next unless $uage < $now;
      $uage = $now + 5;
      @_ = sort {$ips{"$a"} <=> $ips{"$b"}} keys %ips;
      foreach (@_) {
	last if $ips{"$_"} > $now;
	delete $ips{"$_"};
      }
    } # else nfound
  } # while ($Run)

  close $Usock unless $DEBUG;

  if ($DEBUG) {
    return %ips if $DEBUG == 4;
    return %qc if $DEBUG == 5;
    return %dnsbls;		# for any other debug value
  }
  else {
    foreach(keys %dnsbls) {
      $dnsbls{$_} = $dnsbls{$_}->{C};
    }
  }
  return %dnsbls;
}

sub makequery {
  my($put,$id,$name,$type) = @_;
  my $buf;
  my $off = newhead(\$buf,
	$id,
	BITS_QUERY | RD,
	1,0,0,0,
  );
  $off = $put->Question(\$buf,$off,$name,$type,C_IN);
  return $buf;
}

sub makid {
  my $qp = shift;
  my $id;
  do {
	$id = id()
  } while exists $qp->{$id};
  return $id;
}

sub union {
  my($dnsbls,$union,$rip,$expire) = @_;
  $expire += 30;			# union cache expiration is alway longer than timeouts
  if (exists $union->{"$rip"}) {
    $union->{"$rip"} = $expire
	if $expire > $union->{"$rip"};
  } else {
    $union->{"$rip"} = $expire;
    ++$dnsbls->{UNION}->{C};
  }
}

=item * $text = plaintxt($config,\%dnsbls);

Generate a plain text report of the form:

  44 100.0%  TOTAL IP's interrogated
  41  93.2%  UNION of all results
  34  77.3%  dnsbl.sorbs.net comment
  22  50.0%  GENERIC comment
  13  29.5%  in-addr.arpa comment
  11  25.0%  cbl.abuseat.org comment
  9   20.5%  list.dsbl.org comment
  2    4.5%  dnsbl.njabl.org comment
  1    2.3%  bl.spamcannibal.org comment
  0    0.0%  dynablock.njabl.org comment

  input:	configuration pointer,
		dnsbl count hash pointer
  returns:	text buffer

The 'comment' comes from the config file 'comment' key field for each
specified DNSBL or is blank if there is no 'comment' key.

=cut

# return 'comment' and 'url' if present
# input:  $conf, $bl, $nbsp
# output: if  $nbsp	($comment,$url)
#	  if !$nbsp	$comment
#
sub cmurl {
  my($conf,$bl,$nbsp) = @_;
  if ($bl eq 'TOTAL') {
    if ($nbsp) {
      return (q|IP's interrogated|,'');
    } else {
      return q|IP's interrogated|;
    }
  } elsif ($bl eq 'UNION') {
    if ($nbsp) {
      return (q|of all results|,'');
    } else {
      return q|of all results|;
    }
  }
  my $comment = (exists $conf->{"$bl"}->{comment} && $conf->{"$bl"}->{comment})
	? $conf->{"$bl"}->{comment}
	: ($nbsp) ? '&nbsp;' : '';
  return $comment unless $nbsp;
  my $url = (exists $conf->{"$bl"}->{url} && $conf->{"$bl"}->{url})
	? q|<a href="|. $conf->{"$bl"}->{url} .q|">|
	: '';
  return ($comment,$url);
}
  
sub plaintxt {
  my($conf,$dnsbls) = @_;
  return "# ERROR list is empty\n" 
        unless keys %$dnsbls && $dnsbls->{TOTAL};
  my $txt = '';
  my $tot = $dnsbls->{TOTAL}/100;
  my $len = length($dnsbls->{TOTAL});
  foreach(sort{$dnsbls->{"$b"} <=> $dnsbls->{"$a"}
				||
			    $a cmp $b } keys %$dnsbls) {
    my $comment = cmurl($conf,$_);
    $txt .= sprintf("% ${len}u% 6.1f%% %s %s\n",$dnsbls->{"$_"},$dnsbls->{"$_"}/$tot,$_,$comment);
  }
  return $txt;
}

=item * $html = htmltxt($config,\%dnsbls);

Generate a report as above but with E<lt>trE<gt>E<lt>tdE<gt>E<lt>/tdE<gt>E<lt>/trE<gt> table markup. The
E<lt>tableE<gt>E<lt>/tableE<gt> tags are not generated. If there is a 'url' key field in the
respective DNSBL config entry, the DNSBL name is provide with E<lt>a href="url"E<gt>DNSBLE<lt>/aE<gt>
tags with the specified 'url' as the 'href' value.

  input:	configuration pointer,
		dnsbl count hash pointer
  returns:	html text buffer

A one line example corresponding to the text line above:

  34  77.3% dnsbl.sorbs.net 

  with a 'comment' key of: 127.0.0.2,5,7,8,9,10,12
  and a 'url' key of:      http://www.au.sorbs.net/using.shtml

  <tr class=dnsbl><td align=right>34</td>
    <td align=right>77.3%</td>
    <td align=left><a 
     href="http://www.au.sorbs.net/using.shtml">dnsbl.sorbs.net</a></td>
    <td align=left>127.0.0.2,5,7,8,9,10,12</td>
  </tr>

=back

=cut

sub htmltxt {
  my($conf,$dnsbls) = @_;
  return "<!-- ERROR list is empty -->\n"
	unless keys %$dnsbls && $dnsbls->{TOTAL};
  my $html = '';
  my $tot = $dnsbls->{TOTAL}/100;
  my $len = length($dnsbls->{TOTAL});
  foreach(sort{$dnsbls->{"$b"} <=> $dnsbls->{"$a"}
				||
			    $a cmp $b } keys %$dnsbls) {
    my($comment,$url) = cmurl($conf,$_,1);
    my $aa = $url ? '</a>' : '';
    my $count = $dnsbls->{"$_"};
    $html .= '<tr class=dnsbl><td align=right>'. 
	$count .'</td><td align=right>'.
	sprintf("%.1f",$count/$tot) .'%</td><td align=left>'.
	$url . $_ . $aa .'</td><td align=left>'. $comment .'</td></tr>'."\n";
  }
  return $html;
}

=head1 Statistics Web Page HOWTO

Read the C<contrib/HOWTO> document that describes the scripts used with
'cron' to auto generate web pages for the statistics reports

=head1 EXPORT_OK

        run
	plaintxt
	htmltxt

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 COPYRIGHT

Copyright 2008-2014, Michael Robinton.
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

L<Mail::SpamCannibal>,
L<Net::DNS::Codes>,
L<Net::DNS::ToolKit>,
L<Net::DNSBL::MultiDaemon>

=cut

1;
