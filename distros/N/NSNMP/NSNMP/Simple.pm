use strict;
package NSNMP::Simple;
# Copyright (c) 2003-2004 AirWave Wireless, Inc.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:

#    1. Redistributions of source code must retain the above
#    copyright notice, this list of conditions and the following
#    disclaimer.
#    2. Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#    3. The name of the author may not be used to endorse or
#    promote products derived from this software without specific
#    prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
use IO::Socket;
use NSNMP;
use NSNMP::Mapper;
use vars qw($error $error_status $socket);
# these are negative so as not to collide with SNMP protocol error numbers,
# which count up from 1
use constant noResponse => -1;
use constant badHostName => -2;

=head1 NAME

NSNMP::Simple - simple interface to get and set synchronously

=head1 SYNOPSIS

    my $sysnameoid = '1.3.6.1.2.1.1.5.0';
    my $hostname = NSNMP::Simple->get('127.0.0.1', $sysnameoid);
    die $NSNMP::Simple::error unless defined $hostname;
    NSNMP::Simple->set('127.0.0.1', $sysnameoid, NSNMP::OCTET_STRING, 
        'thor.cs.cmu.edu', community => 'CMUprivate') 
      or die $NSNMP::Simple::error;
    my %sysoids = NSNMP::Simple->get_table('127.0.0.1', '1.3.6.1.2.1');

=head1 DESCRIPTION

NSNMP::Simple lets you get or set a single OID via SNMP with a single
line of code.  It's easier to use, and roughly an order of magnitude
faster, than L<Net::SNMP|Net::SNMP> 4.1.2, but Net::SNMP is still much
more mature and complete.  I don't presently recommend using
NSNMP::Simple in production code.

=head1 MODULE CONTENTS

=cut

# some speed costs on my 500MHz PIII laptop:
# it takes:
# 3 microseconds to do a function call and return
# 2 microseconds to do a hash lookup on a 20char string
# 50 microseconds in the kernel to send a packet and receive a response
# 600 microseconds to encode the packet, send it, and receive and
# decode the response (in user time) (getsysname-lots.pl)
# 150 microseconds to do the socket, address, timeout, and error-status
#   checking
# this module does
# another 40 microseconds to do the request_id handling (in the normal case: 
# request ID matches)
# a negligible amount of time to handle retry logic
# encoding and decoding of non-OCTET_STRING values
# all in all: about 1250 microseconds per request-response pair with this 
#   module
# although I still haven't implemented traps, v2 and v3, and handling of
# failure to socket; all of these will slow this module down more.

# XXX refactor this a little more

my ($nfound, $timeleft);
sub _read_timeout {
  my ($fh, $timeout) = @_;
  my $rin = '';
  vec($rin, fileno($fh), 1) = 1;
  return select($rin, undef, undef, $timeout);
}

sub _remember_error {
  my ($response_decoded) = @_;
  $error_status = $response_decoded->error_status;
  my $error_name = NSNMP->error_description($error_status);
  $error = "Received $error_name($error_status) error-status at error-index "
    . $response_decoded->error_index;
  return undef;
}

my $request_id = 'aaaa';

my $response;
sub _synchronous_request_response {
  my ($host, %args) = @_;
  $socket ||= IO::Socket::INET->new(Proto => 'udp');  # XXX error check
  my $port = 161;  # XXX test
  $port = $1 if $host =~ s/:(\d+)\z//;
  my $iaddr = Socket::inet_aton($host);
  if (not defined $iaddr) {
    $error = "Unable to resolve destination address '$host'";
    $error_status = badHostName;
    return undef;
  }

  # This method of picking request IDs has the following nice properties:
  # - there are 450 000 request IDs available
  # - they're always positive, so if they get sign-extended, it's always 
  #   with 0s
  # - they can never be represented in less than 4 bytes
  # - it's relatively fast
  $request_id++;
  $request_id = substr($request_id, 1) if length($request_id) > 4;

  my $tries = 1 + (exists $args{retries} ? $args{retries} : 1);
 try: while ($tries--) {
    send $socket, NSNMP->encode(request_id => $request_id, %args), 0,
      scalar Socket::sockaddr_in($port, $iaddr); # XXX err handling: bad port?

    my $timeout = (exists $args{timeout} ? $args{timeout} : 5);
    for (;;) {
      # perldoc -f select says, "Most systems do not bother to return
      # anything useful in $timeleft."  Well, Linux 2.4 does; so if
      # you're using something that doesn't, upgrade.
      ((my $success), $timeout) = _read_timeout($socket, $timeout);
      next try unless $success;

      $socket->recv($response, 65536, 0); # XXX error handling?
      my $resp_decoded = NSNMP->decode($response);
      if (not $resp_decoded or $resp_decoded->request_id ne $request_id
	  and $resp_decoded->request_id !~ /\A\0+\Q$request_id\E\z/) {
	# ignore it
	next;
      }
      return _remember_error($resp_decoded) if $resp_decoded->error_status;
      ($error, $error_status) = (undef, undef);
      return $resp_decoded;
    }
  }
  ($error, $error_status) =
    ("No response from remote host '$host'", noResponse);
  return undef;
}

sub decode_int {
  my ($intstr) = @_;
  my $padchar = ("\0" eq ($intstr & "\x80")) ? "\0" : "\377";
  $intstr = substr($intstr, length($intstr) - 4) if length($intstr) > 4;
  my $padded = $padchar x (4 - length($intstr)) . $intstr;
  my $num = unpack "N", $padded;
  $num -= 4294967296 if $padchar ne "\0";  # unpack gave us unsigned
  return $num;
}

my %decoders = (
  NSNMP::INTEGER => \&decode_int,
  NSNMP::Counter32 => \&decode_int,
  NSNMP::Gauge32 => \&decode_int,
  NSNMP::TimeTicks => \&decode_int,
  NSNMP::OCTET_STRING => sub { $_[0] },
  NSNMP::IpAddress => sub { join '.', unpack "C*", $_[0] },
  NSNMP::OBJECT_IDENTIFIER => sub { NSNMP->decode_oid($_[0]) },
);

sub encode_int {
  my ($int) = @_;
  my $rv = pack "N", $int;
  return "\0$rv" if $int >= 0 and (($rv & "\x80") ne "\00");
  return $rv;
}

my %encoders = (
  NSNMP::INTEGER => \&encode_int,
  NSNMP::Counter32 => \&encode_int,  # XXX test
  NSNMP::Gauge32 => \&encode_int,
  NSNMP::TimeTicks => \&encode_int,  # XXX test
  NSNMP::OCTET_STRING => sub { $_[0] },
  NSNMP::IpAddress => sub { pack "C*", split /\./, $_[0] },
  NSNMP::OBJECT_IDENTIFIER => sub { NSNMP->encode_oid($_[0]) },  # XXX test
);

=head2 NSNMP::Simple->get($agent, $oid, %args)

Returns the value of C<$oid> on the SNMP agent at C<$agent>, which can
be a hostname or an IP address, optionally followed by a colon and a
numeric port number, which defaults to 161, the default SNMP port.

C<%args> can contain any or all of the following:

=over

=item C<version =E<gt> $ver>

$ver is an SNMP version number (1 or 2 --- 3 isn't yet supported ---
see L</BUGS>).  Default is 1.

=item C<community =E<gt> $comm>

Specifies the community string.  Default is C<public>.

=item C<retries =E<gt> $retries>

Specifies retries.  Default is 1 --- that is, two tries.  Retries are
evenly spaced.

=item C<timeout =E<gt> $timeout>

Specifies a timeout in (possibly fractional) seconds.  Default is 5.0.

=back

Translates the value of C<$oid> into a Perlish value, so, for example,
an INTEGER OID whose value is 1 will be returned as "1", not "\001".
IpAddresses are translated to dotted-quad notation, integer-like types
are translated to integers, and OCTET STRINGS, OPAQUES, and
NsapAddresses are left alone.

It doesn't return the type of the value at all.

In case of failure, it returns C<undef> and sets
C<$NSNMP::Simple::error> to a string describing the error in English,
in the same format as Net::SNMP's error messages.

=cut

# Note that I wanted to put that list of %args first in the text, as a
# bulleted list.  But pod2html barfed on the required blank line after
# the =item * line, so I gave up on bulleted lists in POD.  Yick.

sub get {
  my ($class, $host, $oid, %args) = @_;
  my $response_decoded = 
    _synchronous_request_response($host, 
				  type => NSNMP::GET_REQUEST,
				  varbindlist => [[NSNMP->encode_oid($oid),
						   NSNMP::NULL, '']],
				  %args);
  return undef unless $response_decoded;
  my $varbind = ($response_decoded->varbindlist)[0];
  return $decoders{$varbind->[1]}->($varbind->[2]);
}

=head2 NSNMP::Simple->set($agent, $oid, $type, $value, %args)

Sets the value of C<$oid> on the SNMP agent at C<$agent> to the value
C<$value>, as BER-encoded type C<$type>.  Returns true on success,
false on failure, and also sets C<$NSNMP::Simple::error> on failure.
Accepts the same C<%args> as C<-E<gt>get>.

=cut

sub set {
  my ($class, $host, $oid, $type, $value, %args) = @_;
  return !!_synchronous_request_response($host,
    type => NSNMP::SET_REQUEST,
    varbindlist => [[NSNMP->encode_oid($oid),
		     $type, $encoders{$type}->($value)]],
    %args);
}

=head2 NSNMP::Simple->get_table($agent, $oid, %args)

Gets the values of all OIDs under C<$oid> on the SNMP agent at
C<$agent>.  Returns a list of alternating OIDs and values, in OID
lexical order; you can stuff it into a hash if you don't care about
the order.  If there are no OIDs under C<$oid>, returns an empty list
and clears C<$NSNMP::Simple::error>.  Note that this can be caused
either by misspelling the OID or by actually having an empty table,
and there's no way to tell which.  (See the note in L<SNMP/BUGS> about
the SNMP protocol design.)

If any of the component SNMP requests returns an unexpected error,
C<get_table> returns an empty list and sets C<$NSNMP::Simple::error>.

Note for Net::SNMP users: C<get_table> does not set
C<$NSNMP::Simple::error> on an empty table, but Net::SNMP's
C<get_table> does.

Accepts the same C<%args> as C<-E<gt>get>.

The OIDs in the returned list are spelled in ASCII with or without a
leading dot, depending on whether or not C<$oid> has a leading dot.

=cut

sub get_table {
  my ($class, $host, $oid, %args) = @_;
  my @rv;
  my $response;
  my $mapper = NSNMP::Mapper->new($oid => 1);
  my $initial_dot = $oid =~ /\A\./;
  my $encoded_oid = NSNMP->encode_oid($oid);
  for (;;) {
    $response = _synchronous_request_response($host,
      type => NSNMP::GET_NEXT_REQUEST,
      varbindlist => [[$encoded_oid, NSNMP::NULL, '']],
      %args,
    );
    if (not defined $response) {
      if ($error_status eq NSNMP::noSuchName) {
	# end of MIB
	($error_status, $error) = (undef, undef);
	return @rv;
      }
      return ();
    }
    my @varbindlist = $response->varbindlist;
    $encoded_oid = $varbindlist[0][0];
    $oid = NSNMP->decode_oid($varbindlist[0][0]);
  return @rv unless ($mapper->map($oid))[0];
    push @rv, ($initial_dot ? ".$oid" : $oid),
      $decoders{$varbindlist[0][1]}->($varbindlist[0][2]);
  }
}

=head2 $error

C<$NSNMP::Simple::error> is undef after any successful subroutine
call on this module, and an English string describing the error after
any unsuccessful subroutine call.

C<$NSNMP::Simple::error_status> is undef when C<$error> is undef,
and when C<$error> is defined, C<$error_status> contains an integer
describing the type of error.  This may be a raw SNMP C<error-status>
code, such as NSNMP::noSuchName, or it may be one of the following
values:

=over

=item NSNMP::Simple::noResponse

This code means that the remote host sent no response, or at least, no
response we could decode, so we timed out.  (The timeout value is
configurable, as described earlier.)

=item NSNMP::Simple::badHostName

This code means that C<NSNMP::Simple> couldn't resolve the hostname
given.  It might be malformed or a nonexistent DNS name, or it might
be an existing DNS name, but DNS might be broken for some other
reason.

=back

=head1 FILES

None.

=head1 AUTHOR

Kragen Sitaker E<lt>kragen@pobox.comE<gt>

=head1 BUGS

This module uses L<the SNMP module|SNMP>, so it inherits most of the
bugs of that module.

It's still too slow.  On my 500MHz laptop, it can SNMP-walk 5675 OIDs
in about 7.2 CPU seconds, for less than 800 OIDs per second.  ucd-snmp
(now confusingly called net-snmp, not to be confused with Net::SNMP)
takes 1.8 CPU seconds to perform the same task.  That's four times as
fast.  On the other hand, Net::SNMP manages about 110 OIDs per second,
seven times slower still.

=cut

1;
