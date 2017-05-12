# TFTP.pm
#
# Copyright (c) 1998 G. S. Marzot <gmarzot@baynetworks.com>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package TFTP;

require 5.001;

use strict;
use vars qw(@ISA $VERSION);

use Socket 1.3;
use Time::localtime;

$VERSION = 1.00;

my $TftpPort = 69;

my $RRQ = 1;
my $WRQ = 2;
my $DATA = 3;
my $ACK = 4;
my $ERR = 5;
my @OPS = ('NA','RRQ','WRQ','DATA','ACK','ERR');

my $ErrUndef = 0;
my $ErrFileNotFound = 1;
my $ErrAccessViolation = 2;
my $ErrDiskFull = 3;
my $ErrIllegalOperation = 4;
my $ErrUnknownPort = 5;
my $ErrFileExists = 6;
my $ErrNoSuchUser = 7;

my $ModeNetAscii = 'NETASCII';
my $ModeOctet = 'OCTET';
my $ModeMail = 'MAIL';
my %decode = ("\012" => "\012", "\0" => "\015");
my %encode = ("\012" => "\012", "\015" => "\0");

my $TftpDataSize = 512;
my $TftpBufSize = $TftpDataSize + 4;

my $Timeout = 2;
my $MaxTimeout = 8;
my $Retries = 3;

sub new
{
    my $pkg  = shift;
    my $peer = shift;
    my %arg = @_;
    my $tftp = {};

    socket(SOCKET, PF_INET, SOCK_DGRAM, getprotobyname('udp')) or
	$tftp->{errstr} = "Could not create socket:$!\n", return undef;
    $tftp->{'sock'} = \*SOCKET;

    $tftp->{'host'} = $peer || 'localhost'; # Remote hostname
    $tftp->{'port'} = $arg{Port} || $TftpPort; # Remote port
    $tftp->{'mode'} = $arg{Mode} || $ModeNetAscii;
    $tftp->{'timeout'} = $arg{Timeout} || $Timeout;
    $tftp->{'max_timeout'} = $arg{MaxTimeout} || $MaxTimeout;
    $tftp->{'retries'} = $arg{Retries} || $Retries;
    $tftp->{'errstr'} = '';
    $tftp->{'debug'}= $arg{Debug};
    bless($tftp,$pkg);
}

sub DESTROY { shift->quit }

sub timeout
{
    my $self = shift;
    my $retry = shift;
    my $timeout = $self->{'timeout'};

    $timeout *= ($retry+1);
    return ($timeout > $MaxTimeout ? $MaxTimeout : $timeout);
}

##
## User interface methods
##

sub netascii  { shift->mode($ModeNetAscii); }
sub ascii  { shift->mode($ModeNetAscii); }
sub octet { shift->mode($ModeOctet); }
sub binary { shift->mode($ModeOctet); }

sub mode
{
    my $tftp = shift;
    my $mode = shift;
    my $oldval = $tftp->{'mode'};

    $tftp->{'mode'} = $mode if defined $mode;

    $oldval;
}

sub get
{
    my($tftp,$remote,$local) = @_;
    my($loc,$inlen,$inbuf,$outlen,$outbuf,$data,$lastcr);
    my($rin,$rout,$eout,$remote_iaddr,$remote_paddr,$last_paddr,$port,$host);
    my($count, $op, $block, $expected_block, $retry, $err);
    local *FD;
    # setup and open local file if needed
    if (ref($local)) {
	$loc = $local;
    } else {
	($local = $remote) =~ s!.*/!! unless defined $local;
	unless (open(FD,">$local")) {
	    $tftp->{'errstr'} = "Cannot open local file:$local:$!\n";
	    return undef;
	}
	$loc = \*FD;
    }
    # set binary mode if needed
    my $mode = $tftp->mode;
    if ($mode eq $ModeOctet and !binmode($loc)) {
	$tftp->{'errstr'} = "Cannot binmode Local file $local:$!";
	goto GET_ERR;
    }
    # fetch socket check that socket is defined
    my $sock = $tftp->{'sock'};
    unless (defined $sock) {
	$tftp->{'errstr'}="Socket closed: cannot initiate transfer";
	goto GET_ERR;
    }
    # make request packet
    my $flen = length($remote) + 1;
    my $mlen = length($mode) + 1;
    $outbuf = pack("na${flen}a${mlen}", $RRQ, $remote, $mode);
    # set up destination addr
    $remote_iaddr = inet_aton($tftp->{'host'});
    unless ($remote_iaddr) { $tftp->{'errstr'} = "Unknown host"; goto GET_ERR }
    $remote_paddr = sockaddr_in($tftp->{'port'}, $remote_iaddr);
    # send request packet
    $outlen = send($sock, $outbuf, 0, $remote_paddr);
    print STDERR "sent:$OPS[$RRQ]:$remote:$mode:$outlen\n" if $tftp->{'debug'};
    # prepare to wait for DATA
    print STDERR "fileno($sock) = ", fileno($sock),"\n"  if $tftp->{'debug'};
    vec($rin='', fileno($sock),1) = 1;
    $inlen = 0; $block = 0; $expected_block = 1; $retry = 0;
    while (1) {
       # wait for packet, or exception, or timeout
       $count = select($rout=$rin, undef, $eout=$rin, $tftp->timeout($retry));
       # abort after too many retries
       $tftp->{'errstr'} = "Transfer timeout", last
	   if $retry >= $tftp->{'retries'};
       # retry if timeout or exception
       $retry++, goto DO_GET_SEND
	   unless vec($rout,fileno($sock),1) and !vec($eout,fileno($sock),1);
       # recieve incoming packet
       print STDERR "trying recv:select returned $count:$!\n" if $tftp->{'debug'};
       $remote_paddr = recv($sock, $inbuf, $TftpBufSize,0);
       # check source, ignore if not from original source address
       ($port, $remote_iaddr) = sockaddr_in($remote_paddr);
       next if $last_paddr and $last_paddr ne $remote_paddr;
       $last_paddr ||= $remote_paddr;
       ($op,$block,$data) = unpack("nna*",$inbuf);
       $inlen = length($data);
       if ($tftp->{'debug'}) {
	   $host = gethostbyaddr($remote_iaddr, AF_INET);
	   print STDERR "recvd:$host:$port:$OPS[$op]:$block:$inlen:$!\n";
       }
       # check packet type
       if ($op == $ERR) { $tftp->{'errstr'} = $data; last } # abort on ERR
       next unless $op == $DATA; # ignore other non DATA packets
       # check block number of responses
       if ($block == $expected_block or $block == $expected_block-1) {
	  if ($mode eq $ModeNetAscii) {
	      # prepend cr from previous packet if there was one
	      substr($data,0,0) = $lastcr if $lastcr;
	      # decode cr lf => lf, cr nul => cr, and strip trailing cr
	      $data =~ s/\015([\012\0])(\015\Z(?!\n))?/$decode{$1}/sge;
#	      $data =~ s/\015([\012\0])(\015\Z(?!\n))?/($1?$1:\015)/sge;
              # save trailing cr if there was one
	      $lastcr = $2;
	  }
	  # write data to output file
	  syswrite($loc,$data,length($data)) 
	      if length($data) and $block == $expected_block;
          # prepare to ACK
          $outbuf = pack("nn",$ACK,$block); # ACK current block
          $expected_block = $block + 1; # expect the next one
          $retry = 0; # we are back on track sending good new ACKs
DO_GET_SEND:
	  # (re)send pending ACK (or RRQ)
          $outlen = send($sock, $outbuf, 0, $remote_paddr);
          print STDERR "sent:",$OPS[unpack("n",$outbuf)],":$block:$outlen:$!\n" if $tftp->{'debug'};
       } else {
	   $tftp->{'errstr'} = "Bad block:$block:expected:$expected_block";
	   last;
       }
       # done if not-first packet and packet size less than expected
       last if $inlen < $TftpDataSize and $block;
    } # while
GET_ERR:
    close($loc) unless ref($local); # close file unless filhandle passed in
    unlink($local) if $tftp->{'errstr'} and !ref($local); # delete file if err
    return ($tftp->{'errstr'} ? undef : $local);
}

sub put
{
    my($tftp,$local,$remote) = @_;
    my($loc,$inlen,$inbuf,$outlen,$outbuf,$localfd,$data,$c,$nextc);
    my($rin,$rout,$eout,$remote_iaddr,$remote_paddr,$last_paddr,$port,$host);
    my($op,$block,$expected_block,$retry,$count,$err);
    local *FD;

    # setup and open local file if needed
    if (ref($local)) {
	$loc = $local;
    } else {
	($remote = $local) =~ s!.*/!! unless defined $remote;
	unless (open(FD,"<$local")) {
	    $tftp->{'errstr'} = "Cannot open local file:$local:$!\n";
	    return undef;
	}
	$loc = \*FD;
    }
    # set binary mode if needed
    my $mode = $tftp->mode;
    if ($mode eq $ModeOctet and !binmode($loc)) {
	$tftp->{'errstr'} = "Cannot binmode Local file $local:$!";
	goto PUT_ERR;
    }
    # fetch socket check that socket is defined
    my $sock = $tftp->{'sock'};
    unless (defined $sock) {
	$tftp->{'errstr'}="Socket closed: cannot initiate transfer";
	goto PUT_ERR;
    }
    # make request packet
    my $flen = length($remote) + 1;
    my $mlen = length($mode) + 1;
    $outbuf = pack("na${flen}a${mlen}", $WRQ, $remote, $mode);
    # set up destination addr
    $remote_iaddr = inet_aton($tftp->{'host'});
    unless ($remote_iaddr) { $tftp->{'errstr'} = "Unknown host";goto PUT_ERR; }
    $remote_paddr = sockaddr_in($tftp->{'port'}, $remote_iaddr);
    # send request packet
    $outlen = send($sock, $outbuf, 0, $remote_paddr);
    print STDERR "sent:$OPS[$WRQ]:$remote:$mode:$outlen:$!\n" if $tftp->{'debug'};
    # prepare to wait for ACK
    vec($rin='', fileno($sock), 1) = 1;
    $inlen = 0; $block = 0; $expected_block = 0; $retry = 0;
    while (1) {
       # wait for packet, or exception, or timeout
       $count = select($rout=$rin, undef, $eout=$rin, $tftp->timeout($retry));
       # abort after too many retries
       $tftp->{'errstr'} = "Transfer timeout", last
	   if $retry >= $tftp->{'retries'};
       # retry if timeout or exception
       $retry++, goto DO_PUT_SEND
	   unless vec($rout,fileno($sock),1) and !vec($eout,fileno($sock),1);
       # recieve incoming packet
       print STDERR "trying recv:select returned $count:$!\n" if $tftp->{'debug'};
       $remote_paddr = recv($sock, $inbuf, $TftpBufSize,0);
       # check source, ignore if not from original source address
       ($port, $remote_iaddr) = sockaddr_in($remote_paddr);
       next if $last_paddr and $last_paddr ne $remote_paddr;
       $last_paddr ||= $remote_paddr;
       ($op,$block,$data) = unpack("nna*",$inbuf);
       $inlen = length($data);
       if ($tftp->{'debug'}) {
	   $host = gethostbyaddr($remote_iaddr, AF_INET);
	   print STDERR "recvd:$host:$port:$OPS[$op]:$block:$inlen:$!\n";
       }
       if ($op == $ERR) { $tftp->{'errstr'} = $data; last } # abort on ERR
       next unless $op == $ACK; # ignore other non ACK packets
       if ($block == $expected_block) {
           # done if not-first packet and packet size less than expected
	   last if $outlen < $TftpBufSize and $block;
	   # prepare to send DATA
	   if ($mode eq $ModeNetAscii) {
	       for ($outlen = 0; $outlen < $TftpDataSize; $outlen++) {
		   $data .= $nextc, undef($nextc), next if defined $nextc;
		   last unless $c = getc($loc);
		   $c = "\015" if defined($nextc = $encode{$c});
		   $data .= $c;
	       }
	   } else {
	       $outlen = sysread($loc,$data,$TftpDataSize);
	   }
	   $expected_block = $block + 1;
	   $outbuf = pack("nna${outlen}",$DATA,$expected_block,$data);
	   $retry = 0; # we are back on track sending good new DATA
DO_PUT_SEND:
	  # (re)send pending DATA (or WRQ)
	   $outlen = send($sock, $outbuf, 0, $remote_paddr);
	   print STDERR "sent:",$OPS[unpack("n",$outbuf)],":$expected_block:$outlen\n" if $tftp->{'debug'};
       } elsif ($block == $expected_block - 1) {
           print STDERR "duplicate ACK:$block\n" if $tftp->{'debug'};
	   next; # ignore duplicate ACK to avoid "sorcerer's apprentice"
       } else {
	   print STDERR "bad block:expected block:$expected_block\n" if $tftp->{'debug'};
	   $tftp->{'errstr'} = "Bad block:$block:expected:$expected_block";
	   last;
       }
    } # while
PUT_ERR:
    close($loc) unless ref($local); # close file if ours
    return ($tftp->{'errstr'} ? undef : $local);
}

sub quit
{
    my $tftp = shift;

    close($tftp->{'sock'});
    delete $tftp->{'sock'};
}

1;

__END__

=head1 NAME

TFTP - TFTP Client class

=head1 SYNOPSIS

    use TFTP;

    $tftp = new TFTP("some.host.name");
    $tftp->get("that.file");
    $tftp->octet;
    $tftp->put("this.file");
    $tftp->quit;

=head1 DESCRIPTION

C<TFTP> is a class implementing a simple TFTP client in Perl as
described in RFC783.

=head1 OVERVIEW

TFTP stands for Trivial File Transfer Protocol.

=head1 CONSTRUCTOR

=over 4

=item new (HOST [,OPTIONS])

This is the constructor for a new TFTP object. C<HOST> is the
name of the remote host to which a TFTP connection is required.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<Port> - The port number to connect to on the remote machine for the
TFTP connection

B<Mode> - Set the transfer mode [NETASCII, OCTET] (defaults to NETASCII)

B<Timeout> - Set the timeout value before retry (defaults to 2 sec)

B<MaxTimeout> - Set the maximum timeout value before retry (defaults to 8 sec)

B<Retries> - Set the number of retries (defaults to 3 with arithmetic backoff)

=back

=head1 METHODS

=over 4

=item mode (TYPE)

This method will set the mode to be used with the remote TFTP server to
specify the type of data transfer. The return value is the previous
value.

=item netascii, ascii, octet, binary

Synonyms for C<mode> with the first argument set accordingly

=item get ( REMOTE_FILE [, LOCAL_FILE ] )

Get C<REMOTE_FILE> from the server and store locally. C<LOCAL_FILE> may be
a filename or a filehandle. If not specified the the file will be stored in
the current directory with the same leafname as the remote file.

Returns C<LOCAL_FILE>, or the generated local file name if C<LOCAL_FILE>
is not given.

=item put ( LOCAL_FILE [, REMOTE_FILE ] )

Put a file on the remote server. C<LOCAL_FILE> may be a name or a filehandle.
If C<LOCAL_FILE> is a filehandle then C<REMOTE_FILE> must be specified. If
C<REMOTE_FILE> is not specified then the file will be stored in the current
directory with the same leafname as C<LOCAL_FILE>.

Returns C<REMOTE_FILE>, or the generated remote filename if C<REMOTE_FILE>
is not given.

=item quit

Close the current socket and release any resources. A more complete way to release resources is to call 'undef $tftp;' on the session object.

=back

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.
It may be difficult for me to reproduce the problem as almost every setup
is different.

A small script which yields the problem will probably be of help. It would
also be useful if this script was run with the extra options C<debug => 1>
passed to the constructor, and the output sent with the bug report. If you
cannot include a small script then please include a Debug trace from a
run of your program which does yield the problem.

=head1 AUTHOR

G. S. Marzot <gmarzot@baynetworks.com>

=head1 SEE ALSO

tftp(1), tftpd(8), RFC 783
http://info.internet.isi.edu:80/in-notes/rfc/files/rfc783.txt

Copyright (c) 1998 G. S. Marzot. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
