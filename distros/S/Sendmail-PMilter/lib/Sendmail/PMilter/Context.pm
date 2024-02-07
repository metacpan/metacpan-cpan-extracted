=pod

=head1 LICENSE

Copyright (c) 2016-2024 G.W. Haywood.  All rights reserved.
  With thanks to all those who have trodden these paths before,
  including
Copyright (c) 2002-2004 Todd Vierling.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notices,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notices, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

3. Neither the name of the author nor the names of contributors may be used
to endorse or promote products derived from this software without specific
prior written permission.  In the case of G.W. Haywood this permission is
hereby now granted.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=cut

package Sendmail::PMilter::Context;

use 5.014;	# Don't use 5.016 yet.  That would enable feature 'unicode_strings', and we
		# probably aren't quite ready for that.  We're counting *characters* passed
		# between us and Sendmail, and Sendmail thinks that they're *bytes*.
use parent 'Exporter';

use strict;
use warnings;

use Carp;
use Socket;
use UNIVERSAL;

use Sendmail::PMilter 1.27 qw(:all);

# use Data::Dumper;

our $VERSION = '1.27';
$VERSION = eval $VERSION;

=pod

=head1 SYNOPSIS

Sendmail::PMilter::Context - per-connection milter context

=head1 DESCRIPTION

A Sendmail::PMilter::Context is the context object passed to milter callback
functions as the first argument, typically named "$ctx" for convenience.  
This document details the publicly accessible operations on this object.

=head1 METHODS

=cut

##### Symbols exported to the caller

use constant SMFIA_UNKNOWN	=> 'U';
use constant SMFIA_UNIX		=> 'L';
use constant SMFIA_INET		=> '4';
use constant SMFIA_INET6	=> '6';

our @EXPORT_OK = qw(
	SMFIA_UNKNOWN
	SMFIA_UNIX
	SMFIA_INET
	SMFIA_INET6
);
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

##### Protocol constants
# Commands:
use constant SMFIC_ABORT	=> 'A';
use constant SMFIC_BODY		=> 'B';
use constant SMFIC_CONNECT	=> 'C';
use constant SMFIC_MACRO	=> 'D';
use constant SMFIC_BODYEOB	=> 'E';
use constant SMFIC_HELO		=> 'H';
use constant SMFIC_HEADER	=> 'L';
use constant SMFIC_MAIL		=> 'M';
use constant SMFIC_EOH		=> 'N';
use constant SMFIC_OPTNEG	=> 'O';
use constant SMFIC_RCPT		=> 'R';
use constant SMFIC_QUIT		=> 'Q';
use constant SMFIC_DATA		=> 'T'; # v4
use constant SMFIC_UNKNOWN	=> 'U'; # v3
# Responses:
use constant SMFIR_ADDRCPT	=> '+';
use constant SMFIR_DELRCPT	=> '-';
use constant SMFIR_ADDRCPT_PAR	=> '2';
use constant SMFIR_ACCEPT	=> 'a';
use constant SMFIR_REPLBODY	=> 'b';
use constant SMFIR_CONTINUE	=> 'c';
use constant SMFIR_DISCARD	=> 'd';
use constant SMFIR_ADDHEADER	=> 'h';
use constant SMFIR_INSHEADER	=> 'i'; # v3, or v2 and Sendmail 8.13+
use constant SMFIR_SETSYMLIST	=> 'l';
use constant SMFIR_CHGHEADER	=> 'm';
use constant SMFIR_PROGRESS	=> 'p';
use constant SMFIR_QUARANTINE	=> 'q';
use constant SMFIR_REJECT	=> 'r';
use constant SMFIR_CHGFROM	=> 'e'; # Sendmail 8.14+
use constant SMFIR_TEMPFAIL	=> 't';
use constant SMFIR_REPLYCODE	=> 'y';

##### Private data

no strict 'refs';
my %replynames = map { &{$_} => $_ } qw(
	SMFIR_ADDRCPT
	SMFIR_DELRCPT
	SMFIR_ADDRCPT_PAR
	SMFIR_ACCEPT
	SMFIR_REPLBODY
	SMFIR_CONTINUE
	SMFIR_DISCARD
	SMFIR_ADDHEADER
	SMFIR_INSHEADER
	SMFIR_SETSYMLIST
	SMFIR_CHGHEADER
	SMFIR_PROGRESS
	SMFIR_QUARANTINE
	SMFIR_REJECT
	SMFIR_CHGFROM
	SMFIR_TEMPFAIL
	SMFIR_REPLYCODE
);
use strict 'refs';

##### Constructor, main loop, and internal calls

sub new ($$$$$) {
	my $this = bless {}, shift;
	# The means of communicating with the MTA.
	$this->{socket} = shift;
	# A hash containing $key,$value pairs where $value is a reference to a
	# callback sub in the milter e.g. \&xm_connect_callback and $key is a
	# name for the callback (as passed to sub call_hooks below), e.g. 'connect'.
	my $callbacks = $this->{callbacks} = shift;
	# The capabilities we're going to request from the MTA.
	$this->{callback_flags} = shift;
	# The protocol version we're going to be using.  Probably 6, could be 2.
	$this->{'milter protocol version'} = shift;

	# Making the wild assumption that we're using a recent Sendmail version, offer to the milter all 'protocol' bits set.
	$this->{protocol} = SMFI_CURR_PROT;	# 0x001FFFFF
	# Also all possible data chunk size bits.  Two are available in milter protocol version 6.
	$this->{protocol} |= SMFIP_MDS_256K;	# 0x10000000 MILTER_MAX_DATA_SIZE=262143 bytes.
	$this->{protocol} |= SMFIP_MDS_1M;	# 0x20000000 MILTER_MAX_DATA_SIZE=1048575 bytes.

	$this;
}

sub main ($) {
	my $this = shift;
	my $socket = $this->{socket} || return undef;

	my $buf = '';
	my $gotquit = 0;

	my $split_buf = sub {
		$buf =~ s/\0$//; # remove trailing NUL
		return [ split(/\0/, $buf) ];
	};

	$socket->autoflush(1);

	$this->{lastsymbol} = '';

#my $time_now = localtime;

	eval {

#$time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): main(eval): entered eval, about to enter main loop.\n", $time_now, $$, __LINE__ );
		while (1) {
#$time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): main(eval): top of main loop\n", $time_now, $$, __LINE__ );
			# Loop, reading packets 'from the wire' into $buf and then extracting the commands and any data from them.
			# Note that commands are known by the symbolic constants 'SMFIC_something'.  There are 14 of these commands;
			# all are listed in the 'Commands' section under 'Protocol constants' above.  Correspondigly the responses
			# are known by symbolic constants 'SMFIR_something'.  The 17 possible responses are listed in the 'Responses'
			# section under 'Protocol data' above.  There is just one little wrinkle in all this; the (success) response
			# to the 'SMFIC_OPTNEG' command is also 'SMFIC_OPTNEG'.  There is no 'SMFIR_OPTNEG' response defined.
			$this->read_block(\$buf, 4) || last;
			my $len = unpack('N', $buf);

			die "bad packet length $len\n" if ($len <= 0);

			# save the overhead of stripping the first byte from $buf
			$this->read_block(\$buf, 1) || last;
			my $cmd = $buf;

#$time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): main(eval): got command=[%s]\n", $time_now, $$, __LINE__, $cmd );

			# get actual data
			$this->read_block(\$buf, $len - 1) || die "EOF in stream\n";

			if ($cmd eq SMFIC_ABORT) {
#				delete $this->{symbols}{&SMFIC_CONNECT};
#				delete $this->{symbols}{&SMFIC_HELO};
				delete $this->{symbols}{&SMFIC_MAIL};
#				delete $this->{symbols}{&SMFIC_RCPT};
#				delete $this->{symbols}{&SMFIC_DATA};
#				delete $this->{symbols}{&SMFIC_EOH};
#				delete $this->{symbols}{&SMFIC_BODYEOB};
				$this->call_hooks('abort');
			} elsif ($cmd eq SMFIC_BODY) {
				$this->call_hooks('body', $buf, length($buf));
			} elsif ($cmd eq SMFIC_CONNECT) {
				# Perl RE doesn't like matching multiple \0 instances.
				# To avoid problems, we slice the string to the first null,
				# then use unpack for the rest.
				unless ($buf =~ s/^([^\0]*)\0(.)//) {
					die "SMFIC_CONNECT: invalid connect info\n";
					# XXX should print a hexdump here?
				}

				my $host = $1;
				my $af = $2;
				my ($port, $addr) = unpack('nZ*', $buf);
				my $pack; # default undef

				if ($af eq SMFIA_INET) {
					$pack = pack_sockaddr_in($port, inet_aton($addr));
				} elsif ($af eq SMFIA_INET6) {
					$pack = eval {
						require Socket6;
						$addr =~ s/^IPv6://;
						Socket6::pack_sockaddr_in6($port,
							Socket6::inet_pton(&Socket6::AF_INET6, $addr));
					};
				} elsif ($af eq SMFIA_UNIX) {
					$pack = eval {
						sockaddr_un($addr);
					};
				}
				$this->call_hooks('connect', $host, $pack);
#				delete $this->{symbols}{&SMFIC_CONNECT};
			} elsif ($cmd eq SMFIC_MACRO) {
				die "SMFIC_MACRO: empty packet\n" unless ($buf =~ s/^(.)//);
				my $code = $this->{lastsymbol} = $1;
				my $marray = &$split_buf;

				# odd number of entries: give last empty value
				push(@$marray, '') if ((@$marray & 1) != 0);

				my %macros = @$marray;

				while (my ($name, $value) = each(%macros)) {
					$this->{symbols}{$code}{$name} = $value;
				}
			} elsif ($cmd eq SMFIC_BODYEOB) {
				$this->call_hooks('eom');
#				delete $this->{symbols}{&SMFIC_MAIL};
#				delete $this->{symbols}{&SMFIC_DATA};
#				delete $this->{symbols}{&SMFIC_EOH};
#				delete $this->{symbols}{&SMFIC_BODYEOB};
			} elsif ($cmd eq SMFIC_HELO) {
				my $helo = &$split_buf;
				die "SMFIC_HELO: bad packet\n" unless (@$helo == 1);
				$this->call_hooks('helo', @$helo);
#				delete $this->{symbols}{&SMFIC_HELO};
			} elsif ($cmd eq SMFIC_HEADER) {
				my $header = &$split_buf;

				# empty value: ensure an empty string
				push(@$header, '') if (@$header == 1);
				$this->call_hooks('header', @$header);
			} elsif ($cmd eq SMFIC_MAIL) {
				if ($this->{lastsymbol} ne SMFIC_MAIL) { delete $this->{symbols}{&SMFIC_MAIL}; }
				my $envfrom = &$split_buf;
				$this->call_hooks('envfrom', @$envfrom)
					if scalar @$envfrom >= 1;

#				delete $this->{symbols}{&SMFIC_MAIL};
			} elsif ($cmd eq SMFIC_EOH) {
				$this->call_hooks('eoh');
#				delete $this->{symbols}{&SMFIC_EOH};
			
			} elsif ($cmd eq SMFIC_OPTNEG) {

				# Here we've established that the 'NEGOTIATE' command (SMFIC_OPTNEG) has been received in the incoming packet from the MTA.
				# If it happens at all, the negotiation step should happen once (and only once) at the beginning of a connection.

				# Bleat about the packet size if it's not what's expected, perhaps somebody has, er, 'improved' the MTA.
				# The expected size (including the command byte that we've already stripped off) is 13, so we
				# expect 12 bytes to remain in the packet buffer $buf.  Add 1 to the size and test for != 13.
				my $packet_size = length( $buf ) + 1;
				if( $packet_size != 13 ) {die "SMFIC_OPTNEG: unsupported packet size $packet_size\n"; }
				# Extract the integers from the buffer into the @negotiate array.
				my @negotiate = unpack( 'NNN', $buf );						# Three 32-bit numbers of four bytes each.
				my $arraysize = scalar( @negotiate );
				if( $arraysize != 3 ) { die "SMFIC_OPTNEG: bad packet: expected 3 integer values, found $arraysize.\n"; }
				# Named scalars for clarity, could as easily have used the array elements themselves.
				my $milter_protocol_version	= $negotiate[0];
				my $actions_available		= $negotiate[1];
				my $protocol_steps_available	= $negotiate[2];

				$this->{'milter_protocol_version_ref'}		# 6.  We hope.  Later we may insist.
					= \$milter_protocol_version;		#
				$this->{'actions_available_ref'}		# 1FF.  We hope.  Later we may insist.
					= \$actions_available;			# $actions_available contains an integer consisting of bits which flag various protocol capabilities ('actions' in Sendmail parlance) available from the MTA.
										#   These are things which the milter can ask the MTA to do to the message, such as add a message header (milters very commonly add headers) or replace the message body.
										#   Symbolic constants for these bits are all SMFIF_something.  Over the years,the list of available actions has been extended as Sendmail has developed, and a 'version'
										#   of the milter protocol - a single digit - is implied by the state of development of the milter protocol (i.e. the capabilities which are available) in any particular
										#   version of Sendmail.  Milter protocol Version 6 was introduced by Sendmail 8.14.0 in January 2007, and as of 2019 only versions of Sendmail which support this milter
										#   protocol version are in widespread use.  For security reasons alone you probably should not be using older versions of Sendmail which do not support milter protocol
										#   version 6, but other MTAs may not support all the V6 capabilities so it is probably best to check their availability in your milter before attempting to use them.
										#   The available protocol actions, symbolic constants, and the corresponding bit values for the flags are:
										#	Action			Symbolic constant	Value		Available in milter protocol version.  There's a bit of a muddle about V3, but nobody's using it any more.
										#	-			SMFIF_NONE		0x0000
										#	Add header		SMFIF_ADDHDRS		0x0001		V1  A message header can be added at the end of the message headers, or inserted at a specified position.
										#	Replace body		SMFIF_CHGBODY		0x0002		V2  The message body can be replaced.
										#	Add recipient		SMFIF_ADDRCPT		0x0004		V1  A recipient can be added.  ESMTP arguments cannot be included (see SMFIF_ADDRCPT_PAR below).
										#	Delete recipient	SMFIF_DELRCPT		0x0008		V1  A recipient can be deleted.
										#	Change header		SMFIF_CHGHDRS		0x0010		V2  A header can be modified.
										#	Replace body		SMFIF_MODBODY == SMFIF_CHGBODY  Historical - Milter Protocol V1 - exists for backward compatibility, do not use in new code.
										#	Quarantine message	SMFIF_QUARANTINE	0x0020		V2  The MTA will not deliver the message, but instead place it in a holding area.
										#	Change envelope from	SMFIF_CHGFROM		0x0040		V6  The sender (and ESMTP arguments) given by the client in the "MAIL FROM" command can be replaced.
										#	Add recipient + args	SMFIF_ADDRCPT_PAR	0x0080		V6  A recipient (such as may have been received in a client "RCPT TO" command with ESMTP arguments) can be added.
										#	Request macro values	SMFIF_SETSYMLIST	0x0100		V6  The MTA can provide a list of macros valid for a given protocol 'step'.  See below for the protocol steps.
										#
				$this->{'protocol_steps_available_ref'}		# 1FFFFF.  We hope - later, we may even insist.
					= \$protocol_steps_available;		# $protocol_steps_available contains an integer consisting of bits which refer to four different types of configurable behaviour.
										#   Symbolic constants for these bits are all SMFIP_something.  The first three of the four configuration types affect the protocol
										#   and are listed below in the same order as they are listed in the libmilter source (see st_optionneg() in libmilter/engine.c).
										#   A fourth type which is not related to protocol steps, and is not mentioned in that list, is included here for completness.
										#       Note that the positions of these bits in the integer are not significant - they merely reflect Sendmail development history.
										#  1. The MTA offers to the milter the option for the milter to ask the MTA not to send a particular protocol step command to run one of the callbacks.
										#     The request may be made even if a callback for that step is defined in the milter, and has been 'hooked' by the MTA at startup.
										#	Symbolic constants for these bits are all SMFIP_NOsomething.  There are NINE of these "Do not send protocol step command" features.
										#	The protocol step commands, symbolic constants, and the corresponding bits in this integer are:
										#	Step			Symbolic constant	Value		Available in milter protocol version.  There's a bit of a muddle about V3, but nobody's using it any more.
										#	CONNECT			SMFIP_NOCONNECT		0x00000001	V1  It's difficult to imagine a milter not wanting to know that a connection has been made, but there you are.
										#	HELO			SMFIP_NOHELO		0x00000002
										#	MAIL FROM		SMFIP_NOMAIL		0x00000004
										#	RCPT TO			SMFIP_NORCPT		0x00000008
										#	DATA			SMFIP_NODATA		0x00000200
										#	HEADER			SMFIP_NOHDRS		0x00000020
										#	EOH			SMFIP_NOEOH		0x00000040
										#	BODY			SMFIP_NOBODY		0x00000010
										#	UNKNOWN COMMAND		SMFIP_NOUNKNOWN		0x00000100
										#  2. The MTA understands if the milter requests certain additional features in the protocol.
										#	There are THREE of these features.
										#	Symbolic constants for these bits have, like the corresponding protocol features, nothing in common beyond the SMFIP_ prefix.
										#	The protocol step commands, the symbolic constants, and the corresponding bits are:
										#	SKIP			SMFIP_SKIP		0x00000400	The MTA understands the 'SKIP' command, see Sendmail's libmilter documentation.
										#	SEND REJECTED RECIPIENT	SMFIP_RCPT_REJ		0x00000800	The MTA should send the SMFIC_MAIL command even if the MTA has already decided to reject it as e.g. unknown.
										#									This will take effect only if Sendmail has been compiled with _FFR_MILTER_CHECK_REJECTIONS_TOO.
										#	HEADER LEADING SPACE	SMFIP_HDR_LEADSPC	0x00100000	The MTA will not add leading spaces to header values, the milter must do that.  See the Sendmail documentation.
										#  3. The MTA will by prior negotiation permit the milter to make no reply to the MTA after a given individual milter callback has been run in response to an MTA command.
										#	Symbolic constants for these bits are all SMFIP_NR_something.  There are NINE of these 'SEND NO REPLY' features.
										#	If the MTA and milter agree that the milter will not to send a reply to the MTA at a particular protocol step, it MUST NOT reply to that step.
										#	The protocol step 'NO REPLY' commands, the symbolic constants, and the corresponding bits are:
										#	No reply for CONNECT	SMFIP_NR_CONN		0x00001000
										#	No reply for HELO	SMFIP_NR_HELO		0x00002000
										#	No reply for MAIL	SMFIP_NR_MAIL		0x00004000
										#	No reply for RCPT	SMFIP_NR_RCPT		0x00008000
										#	No reply for DATA	SMFIP_NR_DATA		0x00010000
										#	No reply for HEADER	SMFIP_NR_HDR		0x00000080
										#	No reply for HEADER	SMFIP_NOHREPL == SMFIP_NR_HDR  Historical - exists for backward compatibility, do not use in new code.
										#	No reply for EOH	SMFIP_NR_EOH		0x00040000
										#	No reply for BODY	SMFIP_NR_BODY		0x00080000
										#	No reply for UNKNOWN	SMFIP_NR_UNKN		0x00020000	An unknown command received from the client which is attempting to send mail.
										#  4. The MTA offers to the milter the ability to use a data buffer larger than the default 65535 bytes.
										#	Here be dragons.  The facility is not available in default Sendmail builds, it must be compiled with at least _FFR_MDS_NEGOTIATE to make use of this facility.
										#	Max data size 256K	SMFIP_MDS_256K		0x10000000	262143 bytes.
										#	Max data size 1M	SMFIP_MDS_1M		0x20000000	1048575 bytes.  No sizes other than the three given are permitted.

				if( ${$this->{'milter_protocol_version_ref'}} != 2 && ${$this->{'milter_protocol_version_ref'}} != 6) { die "SMFIC_OPTNEG: unsupported milter protocol version " . ${$this->{'milter_protocol_version_ref'}} . "\n"; }

				# Next we call the milter's 'negotiate' callback, if there is one, via the 'call_hooks' sub.  The 'call_hooks' sub is defined about 78 lines below in this file.
				# The 'call_hooks' sub returns to the MTA a packet which contains (subject to translation of some symbolic constants) whatever the milter callback returned.
				# The 'call_hooks' sub will unpack that packet into the three class variables $this->{'something_ref'} (where 'something' is one of 'milter_protocol_version', 'actions_available' and 'protocol_steps_available').
				my @negotiate_refs = ();
				if( ! defined $this->{callbacks}{'negotiate'} )
				{   # Default protocol steps if no negotiate callback registered.
				    ${$this->{'protocol_steps_available_ref'}} &= SMFIP_DEFAULTS;
				}
				push( @negotiate_refs, $this->{'milter_protocol_version_ref'}, $this->{'actions_available_ref'}, $this->{'protocol_steps_available_ref'} );
				$this->call_hooks('negotiate', @negotiate_refs);

			} elsif ($cmd eq SMFIC_RCPT) {
				my $envrcpt = &$split_buf;
				$this->call_hooks('envrcpt', @$envrcpt)
					if scalar @$envrcpt >= 1;
				delete $this->{symbols}{&SMFIC_RCPT};

			} elsif ($cmd eq SMFIC_DATA) {
				$this->call_hooks('data');
#				delete $this->{symbols}{&SMFIC_DATA};
			} elsif ($cmd eq SMFIC_QUIT) {
				$this->call_hooks('quit');		# A long-felt want, but I'm not sure it will really do what I want.  Is it called if the client does *not* send the 'QUIT' command?
				last;
				# that's all, folks!
			} elsif ($cmd eq SMFIC_UNKNOWN) {
				# This is not an unknown packet, but a packet to tell the milter that an unknown smtp command has been received.
			        # The argument passed to the milter is the unknown command plus any arguments there may have been, both of which can be null so we don't count arguments.
				my $unknown = &$split_buf;
			        $this->call_hooks('unknown', @$unknown );
			} else {
				die "unknown milter packet type $cmd\n";
			}
		}

#$time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): main:       exited main loop.\n", $time_now, $$, __LINE__ );

	};

	my $err = $@;

#$time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): main:       exited eval, err=[%s], about to call 'close' callback.\n", $time_now, $$, __LINE__, $err );

	$this->call_hooks('close');

	# XXX better error handling?  die here to let an eval further up get it?
	if ($err) {
		$this->write_packet(SMFIR_TEMPFAIL) if defined($socket);
#$time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): main:       error found at loop exit: [%s]\n", $time_now, $$, __LINE__, $err );
		warn $err;
		die $err;
	} else {
		$this->write_packet(SMFIR_CONTINUE) if defined($socket);
	}

#$time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): main:       exit.\n", $time_now, $$, __LINE__ );
	undef;
}

sub read_block {
	my $this = shift;
	my $bufref = shift;
	my $len = shift;

	my $socket = $this->{socket};
	my $sofar = 0;

	$$bufref = '';

	while ($len > $sofar) {
		my $read = $socket->sysread($$bufref, $len - $sofar, $sofar);
		return undef if (!defined($read) || $read <= 0); # if EOF
		$sofar += $read;
	}
	1;
}

sub write_packet {
	my $this = shift;
	my $code = shift;
	my $out = shift;
	$out = '' unless defined($out);
	my $len = pack('N', length($out) + 1);
	my $socket = $this->{socket};
	$socket->syswrite($len);
	$socket->syswrite($code);
	$socket->syswrite($out);
return length($code) + length($out);	# XXXX
}

sub call_hooks ($$;@) {
	my $this = shift;
	my $what = $this->{cb} = shift;

#my $time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): call_hooks: callback=[%s]\n", $time_now, $$, __LINE__, $what );

	my $rc = SMFIS_CONTINUE;	# SMFIS_CONTINUE is the default behaviour if no callback is defined.
	my $sub = $this->{callbacks}{$what};
#$time_now = localtime;
	if( defined($sub) )
	{
	    $rc = SMFIS_TEMPFAIL;	# 2023.03.11: Without this assignment we would accept messages if the milter bombs out with some dumb Perl error.  Under these circumstances I'd rather TEMPFAIL.  Configuration?
#printf( "%s PID=%d Context.pm(%3d): call_hooks: about to call callback=[%s], rc=[%s]\n", $time_now, $$, __LINE__, $what, $rc );
	    $rc = &$sub($this, @_);
#$time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): call_hooks: after calling callback=[%s], rc=[%s]\n", $time_now, $$, __LINE__, $what, $rc );
	}
	else
	{
#printf( "%s PID=%d Context.pm(%3d): call_hooks: (non-existent callback=[%s])\n", $time_now, $$, __LINE__, $what );
	}

	# translate to response codes
	if ($rc eq SMFIS_CONTINUE) {
		$rc = SMFIR_CONTINUE;
	} elsif ($rc eq SMFIS_ACCEPT) {
		$rc = SMFIR_ACCEPT;
	} elsif ($rc eq SMFIS_DISCARD) {
		$rc = SMFIR_DISCARD;
	} elsif ($rc eq SMFIS_REJECT) {
		if (defined($this->{reply})) {
			$rc = SMFIR_REPLYCODE;
		} else {
			$rc = SMFIR_REJECT;
		}
	} elsif ($rc eq SMFIS_TEMPFAIL) {
		if (defined($this->{reply})) {
			$rc = SMFIR_REPLYCODE;
		} else {
			$rc = SMFIR_TEMPFAIL;
		}
	} else {
		die "invalid callback return $rc";			# XXXX Need to handle SMFIF_ALL_OPTS
	}

my $len = 0;
#$time_now = localtime;

	if( $what eq 'negotiate' )
	{
	    $this->{protocol} = ${$this->{'protocol_steps_available_ref'}};
#printf( "%s PID=%d Context.pm(%3d): call_hooks: calling write_packet at [%s] callback, rc=[%s]\n", $time_now, $$, __LINE__, $what, $rc );
#print Dumper($this->{symbols})."\n";
	    $len = $this->write_packet
	    (
		SMFIC_OPTNEG,
		pack(
		     'NNN',
		     ${$this->{'milter_protocol_version_ref'}},
		     ${$this->{'actions_available_ref'}},
		     $this->{'protocol'}
		)
	    );
	}
	elsif( $what eq 'abort' ) { ; }					# According to the Sendmail docs the abort callback reply is ignored.
	elsif( $rc ne SMFIR_REPLYCODE || $what eq 'close' )
	{
#printf( "%s PID=%d Context.pm(%3d): call_hooks: calling write_packet at [%s] callback, rc=[%s]\n", $time_now, $$, __LINE__, $what, $rc );
##printf( "%s Context.pm(%3d): call_hooks: calling write_packet at [%s] callback, rc=[%s] (symval{'_'}=[%s])\n", $time_now, __LINE__, $what, $rc, $this->{symbols}{SMFIC_CONNECT}{'_'}//'null' );
#print Dumper($this->{symbols})."\n";
	    $len = $this->write_packet($rc);
	}
	else
	{
#printf( "%s PID=%d Context.pm(%3d): call_hooks: calling write_packet at [%s] callback, rc=[%s]\n", $time_now, $$, __LINE__, $what, $rc );
#print Dumper($this->{symbols})."\n";
	    $len = $this->write_packet($rc, $this->{reply}."\0");
	}
#$time_now = localtime;
#printf( "%s PID=%d Context.pm(%3d): call_hooks: packet length written=[%2d]\n", $time_now, $$, __LINE__, $len );
	undef $this->{reply};
}

##### General methods

=pod

=over 4

=item $ctx->getpriv

Returns the private data object for this milter instance, set by
$ctx->setpriv() (see below).  Returns undef if setpriv has never been called
by this milter instance.

=cut

sub getpriv ($) {
	my $this = shift;

	$this->{priv};
}

=pod

=item $ctx->getsymval(NAME)

(The word 'macro' in Sendmail parlance refers to named variables which are
essentially text strings.  They can be defined by the MTA, and populated as
messages are processed, or by milters, or by the MTA's configuration files.)

The getsymval method retrieves the macro symbol named NAME from the macros
 available from the MTA for the current callback.  NAME is either a one-
character macro name, or a multi-character name enclosed in {curly braces}.
If macro NAME is undefined when getsymval is called, it returns undef.

Some common macros are given below.  The milter protocol was first
implemented in the Sendmail MTA, so these macro names are those used by
Sendmail itself; other MTAs e.g. Postfix may provide similar macros.

=over 2

=item $ctx->getsymval('_')

The remote host name and address, in standard SMTP "name [address]" form.

=item $ctx->getsymval('i')

The MTA's queue ID for the current message.

=item $ctx->getsymval('j')

The MTA's idea of local host name.

=item $ctx->getsymval('{if_addr}')

The local address of the network interface upon which the connection was
received.

=item $ctx->getsymval('{if_name}')

The local hostname of the network interface upon which the connection was
received.

=item $ctx->getsymval('{mail_addr}')

The MAIL FROM: sender's address, canonicalized and angle bracket stripped.
(This is typically not the same value as the second argument to the
"envfrom" callback.)  Will be defined to the empty string '' if the client
issued a MAIL FROM:<> null return path command.

=item $ctx->getsymval('{rcpt_addr}')

The RCPT TO: recipient's address, canonicalized and angle bracket stripped.
(This is typically not the same value as the second argument to the
"envrcpt" callback.)

=back

Not all macros may be available at all times.  Some macros are only
available after a specific phase is reached, and some macros may only
be available from certain MTA implementations.  Check returned values
for 'undef'.  This version of the Sendmail::PMilter package collects
macro values only for the following callbacks:

CONNECT
HELO
ENVFROM
ENVRCPT
DATA
EOH
EOM

=cut

sub getsymval ($$) {
	my $this = shift;
	my $key = shift;
	foreach my $code (SMFIC_CONNECT, SMFIC_HELO, SMFIC_MAIL, SMFIC_RCPT, SMFIC_DATA, SMFIC_EOH, SMFIC_BODYEOB)
	{
		my $val = $this->{symbols}{$code}{$key};
		if( defined $val ) { return $val; }
	}
	undef;
}

=pod

=item $ctx->setpriv(DATA)

This is the place to store milter-private data that is sensitive to the
current SMTP client connection.  Only one value can be stored, so typically
an arrayref or hashref is initialized in the "connect" callback and set with
$ctx->setpriv.

This value can be retrieved on subsequent callback runs with $ctx->getpriv.

=cut

sub setpriv ($$) {
	my $this = shift;
	$this->{priv} = shift;
	1;
}

=pod

=item $ctx->setreply(RCODE, XCODE, MESSAGE)

Set an extended SMTP status reply (before returning SMFIS_REJECT or
SMFIS_TEMPFAIL).  RCODE should be a short (4xx or 5xx) numeric reply
code, XCODE should be a long ('4.x.y' or '5.x.y') ESMTP reply code.
The first digit of RCODE must be the same as the first digit of XCODE.
There is no such restriction on the other digits.  In RCODE and XCODE,
'x' should be one decimal digit; in XCODE 'y' should be either one or
two decimal digits.  MESSAGE is the full text of the message to send.
Refer to the appropriate RFCs for actual codes and suggested messages.
Examples:

        $ctx->setreply(451, '4.7.0', 'Cannot authenticate you right now');
        return SMFIS_TEMPFAIL;

        $ctx->setreply(550, '5.7.26', 'Multiple authentication failures');
        return SMFIS_REJECT;

Note that after setting a reply with this method, the SMTP result code
comes from RCODE, not from the symbolic constants SMFIS_REJECT and
SMFIS_TEMPFAIL.  However for consistency, callbacks that set a 4xx
response code should use SMFIS_TEMPFAIL, and those that set a 5xx code
should return SMFIS_REJECT.

Returns 1 on success, undef on failure.  In the case of failure, which
is typically only caused by bad parameters, a generic message will be
sent based on the SMFIS_* return code.

=cut

sub setreply ($$$$) {
	my $this = shift;
	my $rcode = shift || '';
	my $xcode = shift || '';
	my $message = shift || '';

	if ($rcode !~ /^[45]\d\d$/ || $xcode !~ /^[45]\.\d\.\d{1,2}$/ || substr($rcode, 0, 1) ne substr($xcode, 0, 1)) {
		warn 'setreply: bad reply arguments';
		return undef;
	}

	$this->{reply} = "$rcode $xcode $message";
	1;
}

=pod

=item $ctx->setmlreply(RCODE, XCODE, MESSAGES)

Set an extended SMTP status reply (before returning SMFIS_REJECT or
SMFIS_TEMPFAIL).  See setreply() above for more information about the
reply codes RCODE and XCODE.  MESSAGES is an array which contains a
multi-line reply.  This array must contain no less than two string
elements.  Sendmail dictates that it must contain no more than 32
elements, and that each string element must contain no more than 980
characters (although any of the strings may be NULL), and no string
may contain a newline ("\n") or a carriage return ("\r") character.

Example:

        $ctx->setmlreply(451, '4.7.0', \('Cannot authenticate sender.',
                          'Please refer to our published policies at',
                          'http://www.example.com/policies')
                        );
        return SMFIS_TEMPFAIL;

Note that after setting a reply with this method, the SMTP result code
comes from RCODE, not from the symbolic constants SMFIS_REJECT and
SMFIS_TEMPFAIL.  However for consistency, callbacks that set a 4xx
response code should use SMFIS_TEMPFAIL, and those that set a 5xx code
should return SMFIS_REJECT.

Returns 1 on success, undef on failure.  In the case of failure, which
is typically caused by bad parameters, a generic message will be sent
based on the SMFIS_* return code.

=cut

# See Sendmail::PMilter and .../libmilter/smfi.c in the Sendmail
# source for MAXREPLIES and MAXREPLYLEN.

sub setmlreply ($$$$) {
	my $this = shift;
	my $rcode = shift || '';
	my $xcode = shift || '';
	my $messageref = shift || '';
	if
	(
		ref( $messageref ) ne 'ARRAY'			||
		$rcode !~ /^[45]\d\d$/				||
		$xcode !~ /^[45]\.\d\.\d{1,2}$/			||
		substr($rcode, 0, 1) ne substr($xcode, 0, 1)	||
		@{$messageref} < 2				||
		@{$messageref} > MAXREPLIES
	)
	{
		warn 'setmlreply: bad reply arguments';
		return undef;
	}
	my $message = $rcode . '-' . $xcode . ' ';			# Admittedly this is a bit willful.
	foreach( @{$messageref} )
	{
	    if( /[\r\n]/ )						# Sendmail does not allow these characters in the reply strings.
	    {
		warn 'setmlreply: bad reply arguments';
		return undef;
	    }
	    $message .= "\r\n" . $rcode . '-' . $xcode . ' ' . $_;
	}
	$message .= "\r\n" . $rcode . ' ' . $xcode . ' ';
	$this->{reply} = $message;
	1;
}

=item $ctx->shutdown()

A special case of C<< $ctx->setreply() >> which sets the short numeric reply 
code to 421 and the ESMTP code to 4.7.0.  Under Sendmail 8.13 and higher
(and you should not be using any version of Sendmail older than that),
this will close the MTA's communication channel quickly, which should 
immediately result in a "close" callback and end of milter execution. 

Returns 1.

=cut

sub shutdown ($) {
	my $this = shift;
	$this->setreply(421, '4.7.0', 'Closing communications channel');
	1;
}

##### Protocol action methods

=pod

=item $ctx->addheader(HEADER, VALUE)

Add header HEADER with value VALUE to this mail.  Does not change any
existing headers with the same name.  Only callable from the "eom" callback.

Returns 1 on success, undef on failure.

=cut

sub addheader ($$$) {
	my $this = shift;
	my $header = shift || die "addheader: no header name\n";
	my $value = shift;
	die "addheader: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "addheader: SMFIF_ADDHDRS not in capability list\n" unless ($this->{callback_flags} & SMFIF_ADDHDRS);
	die "addheader: no header value\n" unless defined $value;

	$this->write_packet(SMFIR_ADDHEADER, "$header\0$value\0");
	1;
}

=pod

=item $ctx->insheader(HEADER, VALUE, POSITION)

Insert header HEADER at position POSITION with value VALUE to this mail.
Does not change any existing headers with the same name.  Only callable
from the "eom" callback.  HEADER and VALUE are requred, but POSITION is
optional.  A POSITION value of zero is acceptable and is the default if
not supplied - this inserts the HEADER before all existing headers.

Returns 1 on success, undef on failure.

=cut

sub insheader ($$$;$) {
	my $this = shift;
	my $header = shift || die "insheader: no header name\n";
	my $value = shift || die "insheader: no header value\n";
	my $position = shift;
	if( not defined $position ) { $position = 0; }

	die "insheader: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "addheader: SMFIF_ADDHDRS not in capability list\n" unless ($this->{callback_flags} & SMFIF_ADDHDRS);

	$this->write_packet(SMFIR_INSHEADER, pack('N',$position)."$header\0$value\0");
	1;
}

=pod

=item $ctx->chgheader(HEADER, INDEX, VALUE)

Change the INDEX'th header of name HEADER to the value VALUE.  Only callable
from the "eom" callback.  If INDEX exceeds the number of existing headers of
name HEADER, adds another header of that name.

Returns 1 on success, undef on failure.

=cut

sub chgheader ($$$$) {
	my $this = shift;
	my $header = shift || die "chgheader: no header name\n";
	my $num = shift || 0;
	my $value = shift;

	$value = '' unless defined($value);

	die "chgheader: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "chgheader: SMFIF_CHGHDRS not in capability list\n" unless ($this->{callback_flags} & SMFIF_CHGHDRS);

	$this->write_packet(SMFIR_CHGHEADER, pack('N', $num)."$header\0$value\0");
	1;
}

=pod

=item $ctx->addrcpt(ADDRESS)

Add address ADDRESS to the list of recipients for this mail.  Only callable
from the "eom" callback.

Returns 1 on success, undef on failure.

=cut

sub addrcpt ($$) {
	my $this = shift;
	my $rcpt = shift || die "addrcpt: no recipient specified\n";

	die "addrcpt: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "addrcpt: SMFIF_ADDRCPT not in capability list\n" unless ($this->{callback_flags} & SMFIF_ADDRCPT);

	$this->write_packet(SMFIR_ADDRCPT, "$rcpt\0");
	1;
}

=pod

=item $ctx->addrcpt_par(ADDRESS,PARAMS)

Add an address ADDRESS and its ESMTP arguments PARAMS to the list of
recipients for this mail.  Only callable from the "eom" callback.

Returns 1 on success, undef on failure.

=cut

sub addrcpt_par ($$$) {
	my $this = shift;
	my $rcpt = shift || die "addrcpt: no recipient specified\n";
	my $params = shift;

	die "addrcpt_par: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "addrcpt_par: SMFIF_ADDRCPT_PAR not in capability list\n" unless ($this->{callback_flags} & SMFIF_ADDRCPT_PAR);

	$this->write_packet(SMFIR_ADDRCPT_PAR, "$rcpt\0");
	1;
}

=pod

=item $ctx->delrcpt(ADDRESS)

Remove address ADDRESS from the list of recipients for this mail.  The
ADDRESS argument must match a prior argument to the "envrcpt" callback
exactly (case sensitive, and including angle brackets if present).  Only
callable from the "eom" callback.

Returns 1 on success, undef on failure.  A success return means that
the command was queued for processing.  It does not necessarily mean
that the recipient was successfully removed, that information is not
available from Sendmail.

=cut

sub delrcpt ($$) {
	my $this = shift;
	my $rcpt = shift || die "delrcpt: no recipient specified\n";

	die "delrcpt: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "delrcpt: SMFIF_DELRCPT not in capability list\n" unless ($this->{callback_flags} & SMFIF_DELRCPT);

	$this->write_packet(SMFIR_DELRCPT, "$rcpt\0");
	1;
}

=pod

=item $ctx->progress()

Sends an asynchronous "progress" message to the MTA, to allow longer
than normal operations such as extensive message body scanning or a
deliberate delay.  This command should only be issued during the EOM
callback, it will fail (and return undef) if called at other times.

Returns 1 if the call is made during EOM and is permitted, else undef.

=cut

sub progress ($) {
	my $this = shift;
	die "progress: called outside of EOM\n" if ($this->{cb} ne 'eom');
	$this->write_packet(SMFIR_PROGRESS);
	1;
}

=pod

=item $ctx->quarantine(REASON)

Quarantine the current message in the MTA-defined quarantine area, using 
the given REASON as a text string describing the quarantine status.  Only 
callable from the "eom" callback.

Returns 1 on success, undef on failure.

This method is an extension that is not available in the standard 
Sendmail::Milter package.

=cut

sub quarantine ($$) {
	my $this = shift;
	my $reason = shift;

	die "quarantine: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "quarantine: SMFIF_QUARANTINE not in capability list\n" unless ($this->{callback_flags} & SMFIF_QUARANTINE);

	$this->write_packet(SMFIR_QUARANTINE, "$reason\0");
	1;
}

=pod

=item $ctx->replacebody(BUFFER)

Replace the message body with the data in BUFFER (a scalar).  This method
may be called multiple times, each call appending to the replacement buffer.  
End-of-line should be represented by CR-LF ("\r\n").  Only callable from the
"eom" callback.

Returns 1 on success, undef on failure.

=cut

sub replacebody ($$) {
	my $this = shift;
	my $chunk = shift;

	die "replacebody: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "replacebody: SMFIF_CHGBODY not in capability list\n" unless ($this->{callback_flags} & SMFIF_CHGBODY);

	my $len = length($chunk);
	my $socket = $this->{socket};

	$len = pack('N', ($len + 1));
	$socket->syswrite($len);
	$socket->syswrite(SMFIR_REPLBODY);
	$socket->syswrite($chunk);
	1;
}

=pod

=item $ctx->chgfrom(ADDRESS)
=item $ctx->setsender(ADDRESS) (Deprecated)

Replace the envelope sender address for the given mail message.

Returns 1 on success, undef on failure.  Successful return means that
the command was queued for processing.  It does not necessarily mean
that the operation was successfully completed, that information is not
available from Sendmail.

=cut

sub chgfrom ($$) {
	my $this = shift;
	my $sender = shift || die "chgfrom: no sender specified\n";

	die "chgfrom: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "chgfrom: SMFIF_CHGFROM not in capability list\n" unless ($this->{callback_flags} & SMFIF_CHGFROM);

	$this->write_packet(SMFIR_CHGFROM, "$sender\0");
	1;
}

# Deprecated, may be removed from a future version with little or no warning.
sub setsender ($$) {
	my $this = shift;
	my $sender = shift || die "setsender: no sender specified\n";

	die "setsender: called outside of EOM\n" if ($this->{cb} ne 'eom');
	die "setsender: SMFIF_CHGFROM not in capability list\n" unless ($this->{callback_flags} & SMFIF_CHGFROM);

	$this->write_packet(SMFIR_CHGFROM, "$sender\0");
	1;
}

1;

__END__

=pod

=back

=head1 SEE ALSO

L<Sendmail::PMilter>
