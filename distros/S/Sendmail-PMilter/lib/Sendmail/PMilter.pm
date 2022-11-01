=pod

=head1 LICENSE

Copyright (c) 2016-2022 G.W. Haywood.  All rights reserved.
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

package Sendmail::PMilter;

use 5.014;	# Don't use 5.016 yet.  That would enable feature 'unicode_strings', and we
		# probably aren't quite ready for that.  We're counting *characters* passed
		# between us and Sendmail, and Sendmail thinks that they're *bytes*.

use parent 'Exporter';
use strict;
use warnings;
use Carp;
use Errno;
use IO::Select;
use POSIX;
use Socket;
use Symbol;
use UNIVERSAL;

our $VERSION = '1.23';
$VERSION = eval $VERSION;

our $DEBUG = 0;

=pod

=head1 NAME

Sendmail::PMilter - Perl binding of Sendmail Milter protocol

=head1 SYNOPSIS

    use Sendmail::PMilter;

    my $milter = new Sendmail::PMilter;

    $milter->auto_setconn(NAME);
    $milter->register(NAME, { CALLBACKS }[, FLAGS]);
    $milter->main();

=head1 DESCRIPTION

Sendmail::PMilter is a mail filtering API implementing the Sendmail
Milter Protocol in Perl.  This allows the administrator of Sendmail
(and perhaps other MTAs which implement the Milter Protocol) to use
pure Perl code to filter and modify mail during an SMTP connection.

Over the years, the protocol which governs the communication between
qSendmail and its milters has passed through a number of revisions.

This documentation is for Sendmail::PMilter versions 1.20 and later,
which now supports Milter Protocol Version 6.  This is a substantial
upgrade from earlier versions, which at best supported up to Milter
Protocol Version 2 - this was first seen in Sendmail version 8.14.0
which was released on January 31st 2007.

Sendmail::PMilter now uses neither the original Sendmail::Milter (it
is obsolete, badly flawed and unmaintained) nor the Sendmail::Milter
which was packaged with earlier versions of Sendmail::PMilter as a
temporary workaround for the broken original.

For communications between the MTA and the milter, a 'dispatcher' acts
as a go-between.  This must be chosen when the milter is initialized,
before it serves requests.  Several dispatchers are provided within
the Sendmail::PMilter module, but in versions before 1.20 all the
dispatchers suffered from issues of varying gravity.  The 'prefork'
dispatcher (see DISPATCHERS below) has now been extensively exercised
by the current maintainer, but although the others have been patched
from issue reports going back more than a decade from the time of
writing (June 2019) THEY HAVE NOT BEEN TESTED.  Feedback via the CPAN
issue tracking system is encouraged.  If you have developed your own
dispatcher you can either pass a code reference to set_dispatcher() or
set an environment variable to point to it.  Sendmail::PMilter will
then use it instead of a built-in dispatcher.

=head1 METHODS

=cut

##### Protocol constants
# The SMFIS_* values here are not the same as those used in the Sendmail sources
# (see mfapi.h) so that hopefully "0" and "1" won't be used as response codes by
# mistake.  The other protocol constants below are unchanged from those used in
# the Sendmail sources.

use constant SMFIS_CONTINUE	=> 100;
use constant SMFIS_REJECT	=> 101;
use constant SMFIS_DISCARD	=> 102;
use constant SMFIS_ACCEPT	=> 103;
use constant SMFIS_TEMPFAIL	=> 104;
use constant SMFIS_MSG_LOOP	=> 105;
use constant SMFIS_ALL_OPTS	=> 110;

# Milter progessing 'places' (see mfapi.h, values are the same).
use constant SMFIM_CONNECT	=> 0;	# connect
use constant SMFIM_HELO		=> 1;	# HELO/EHLO
use constant SMFIM_ENVFROM	=> 2;	# MAIL FROM
use constant SMFIM_ENVRCPT	=> 3;	# RCPT TO
use constant SMFIM_DATA		=> 4;	# DATA
use constant SMFIM_EOM		=> 5;	# END OF MESSAGE (final dot)
use constant SMFIM_EOH		=> 6;	# END OF HEADER

# Some of these things have been switched around from their order of
# presentation in the Sendmail sources but the values are the same.
######################################################################
# Taken from .../sendmail-8.15.2/include/libmilter/mfdef.h
######################################################################
#if _FFR_MDS_NEGOTIATE
# define MILTER_MDS_64K ((64 * 1024) - 1)
# define MILTER_MDS_256K ((256 * 1024) - 1)
# define MILTER_MDS_1M  ((1024 * 1024) - 1)
#endif /* _FFR_MDS_NEGOTIATE */
######################################################################
# These so-called 'protocols' apply to the SMFIP_* flags:
#define SMFI_V1_PROT    0x0000003FL     The protocol of V1 filter.  We won't bother with V1, it's obsolete.
#define SMFI_V2_PROT    0x0000007FL     The protocol of V2 filter
use constant SMFI_V2_PROT	=> 0x0000007F;	# The protocol flags available in Milter Protocol Version 2.
#use constant SMFI_V4_PROT	=> 0x000003FF;	# The protocol flags available in Milter Protocol Version 4.
use constant SMFI_V6_PROT	=> 0x001FFFFF;	# The protocol flags available in Milter Protocol Version 6.
use constant SMFI_CURR_PROT	=> 0x001FFFFF;	# The protocol flags available in the current Milter Protocol Version (which at July 2019 is Version 6).
######################################################################
# What the MTA can send/filter wants in protocol
use constant SMFIP_NOCONNECT	=> 0x00000001;	# MTA should not send connect info
use constant SMFIP_NOHELO	=> 0x00000002;	# MTA should not send HELO info
use constant SMFIP_NOMAIL	=> 0x00000004;	# MTA should not send MAIL info
use constant SMFIP_NORCPT	=> 0x00000008;	# MTA should not send RCPT info
use constant SMFIP_NOBODY	=> 0x00000010;	# MTA should not send body
use constant SMFIP_NOHDRS	=> 0x00000020;	# MTA should not send headers
use constant SMFIP_NOEOH	=> 0x00000040;	# MTA should not send EOH
use constant SMFIP_NR_HDR	=> 0x00000080;	# No reply for headers
use constant SMFIP_NOHREPL	=> 0x00000080;  # No reply for headers (backward compatibility, do not use, same as SMFIP_NR_HDR)
use constant SMFIP_NOUNKNOWN	=> 0x00000100;	# MTA should not send unknown commands
use constant SMFIP_NODATA	=> 0x00000200;	# MTA should not send DATA
use constant SMFIP_SKIP		=> 0x00000400;	# MTA understands SMFIS_SKIP called from EOM callback.
use constant SMFIP_RCPT_REJ	=> 0x00000800;	# MTA should also send rejected RCPTs
use constant SMFIP_NR_CONN	=> 0x00001000;	# No reply for connect
use constant SMFIP_NR_HELO	=> 0x00002000;	# No reply for HELO
use constant SMFIP_NR_MAIL	=> 0x00004000;	# No reply for MAIL
use constant SMFIP_NR_RCPT	=> 0x00008000;	# No reply for RCPT
use constant SMFIP_NR_DATA	=> 0x00010000;	# No reply for DATA
use constant SMFIP_NR_UNKN	=> 0x00020000;	# No reply for UNKN
use constant SMFIP_NR_EOH	=> 0x00040000;	# No reply for eoh
use constant SMFIP_NR_BODY	=> 0x00080000;	# No reply for body chunk
use constant SMFIP_HDR_LEADSPC	=> 0x00100000;	# header value leading space
use constant SMFIP_MDS_256K	=> 0x10000000;	# MILTER_MAX_DATA_SIZE=256K
use constant SMFIP_MDS_1M	=> 0x20000000;	# MILTER_MAX_DATA_SIZE=1M
######################################################################
# If no negotiate callback is registered, these are the defaults.  Basically
# everything is enabled except SMFIP_RCPT_REJ and MILTER_MAX_DATA_SIZE_*
# Sendmail and Postfix behave differently:
#   Postfix does not use the constants SMFIP_MDS_256K and SMFIP_MDS_1M.
use constant SMFIP_ALL_NO_CB	=> (SMFIP_NOCONNECT|SMFIP_NOHELO|SMFIP_NOMAIL|SMFIP_NORCPT|SMFIP_NOBODY|SMFIP_NOHDRS|SMFIP_NOEOH|SMFIP_NOUNKNOWN|SMFIP_NODATA|SMFIP_SKIP|SMFIP_HDR_LEADSPC);
use constant SMFIP_ALL_NO_REPLY	=> (SMFIP_NR_HDR|SMFIP_NR_CONN|SMFIP_NR_HELO|SMFIP_NR_MAIL|SMFIP_NR_RCPT|SMFIP_NR_DATA|SMFIP_NR_UNKN|SMFIP_NR_EOH|SMFIP_NR_BODY);
use constant SMFIP_DEFAULTS	=> ~(SMFIP_ALL_NO_CB|SMFIP_ALL_NO_REPLY);
######################################################################
# Taken from .../sendmail-8.15.2/include/libmilter/mfapi.h, and
# reformatted a little.
######################################################################
# These so-called 'actions' apply to the SMFIF_* flags:
#define SMFI_V1_ACTS    0x0000000FL	The actions of V1 filter
#define SMFI_V2_ACTS    0x0000003FL	The actions of V2 filter
#define SMFI_CURR_ACTS  0x000001FFL	actions of current version
######################################################################
#define SMFIF_NONE        0x00000000L	no flags
#define SMFIF_ADDHDRS     0x00000001L	filter may add headers
#define SMFIF_CHGBODY     0x00000002L	filter may replace body
#define SMFIF_MODBODY   SMFIF_CHGBODY	backwards compatible
#define SMFIF_ADDRCPT     0x00000004L	filter may add recipients
#define SMFIF_DELRCPT     0x00000008L	filter may delete recipients
#define SMFIF_CHGHDRS     0x00000010L	filter may change/delete headers
#define SMFIF_QUARANTINE  0x00000020L	filter may quarantine envelope		<<========= "envelope"???
#define SMFIF_CHGFROM	  0x00000040L	filter may change "from" (envelope sender)
#define SMFIF_ADDRCPT_PAR 0x00000080L	add recipients incl. args
#define SMFIF_SETSYMLIST  0x00000100L	filter can send set of symbols (macros) that it wants
######################################################################
#		Capability	FLAG value		Available in milter protocol version (*)
use constant SMFIF_NONE		=> 0x0000;		# Unused	(*) There's a bit of a muddle about V3,
use constant SMFIF_ADDHDRS	=> 0x0001;		# V1 Add headers	but nobody's using it any more.
use constant SMFIF_MODBODY	=> 0x0002;		# V1 Change body (for compatibility with old code, use SMFIF_CHGBODY in new code)
use constant SMFIF_CHGBODY	=> SMFIF_MODBODY;	# V2 Change body
use constant SMFIF_ADDRCPT	=> 0x0004;		# V1 Add recipient
use constant SMFIF_DELRCPT	=> 0x0008;		# V1 Delete recipient
use constant SMFIF_CHGHDRS	=> 0x0010;		# V2 Change headers
use constant SMFIF_QUARANTINE	=> 0x0020;		# V2 quarantine entire message - last of the V2 flags
use constant SMFIF_CHGFROM	=> 0x0040;		# V6 Change envelope sender
use constant SMFIF_ADDRCPT_PAR	=> 0x0080;		# V6 Add recipients incl. args
use constant SMFIF_SETSYMLIST	=> 0x0100;		# V6 Filter can send set of symbols (macros) that it wants

use constant SMFI_V1_ACTS	=> SMFIF_ADDHDRS|SMFIF_CHGBODY|SMFIF_ADDRCPT|SMFIF_DELRCPT;
use constant SMFI_V2_ACTS	=> SMFI_V1_ACTS|SMFIF_CHGHDRS|SMFIF_QUARANTINE;
use constant SMFI_V6_ACTS	=> SMFI_V2_ACTS|SMFIF_CHGFROM|SMFIF_ADDRCPT_PAR|SMFIF_SETSYMLIST;
use constant SMFI_CURR_ACTS	=> SMFI_V6_ACTS;	# All capabilities.  See mfapi.h and mfdef.h

# See libmilter/smfi.c
use constant MAXREPLYLEN	=> 980;
use constant MAXREPLIES		=> 32;

##### Symbols exported to the caller

my $smflags =
'   SMFIP_DEFAULTS SMFIP_NOCONNECT SMFIP_NOHELO SMFIP_NOMAIL SMFIP_NORCPT SMFIP_NOBODY SMFIP_NOHDRS SMFIP_NOEOH SMFIP_NOUNKNOWN SMFIP_NODATA SMFIP_RCPT_REJ SMFIP_SKIP
    SMFIP_NR_CONN SMFIP_NR_HELO SMFIP_NR_MAIL SMFIP_NR_RCPT SMFIP_NR_DATA SMFIP_NR_HDR SMFIP_NR_EOH SMFIP_NR_BODY SMFIP_NR_UNKN SMFIP_HDR_LEADSPC SMFIP_MDS_256K SMFIP_MDS_1M
    SMFIM_CONNECT SMFIM_HELO SMFIM_ENVFROM SMFIM_ENVRCPT SMFIM_DATA SMFIM_EOM SMFIM_EOH
    SMFIS_CONTINUE SMFIS_REJECT SMFIS_DISCARD SMFIS_ACCEPT SMFIS_TEMPFAIL SMFIS_MSG_LOOP SMFIS_ALL_OPTS
    SMFIF_NONE SMFIF_ADDHDRS SMFIF_CHGBODY SMFIF_ADDRCPT SMFIF_DELRCPT SMFIF_CHGHDRS SMFIF_QUARANTINE SMFIF_CHGFROM SMFIF_ADDRCPT_PAR SMFIF_SETSYMLIST
    SMFI_V2_ACTS SMFI_V6_ACTS SMFI_CURR_ACTS SMFI_V2_PROT SMFI_V6_PROT SMFI_CURR_PROT
    MAXREPLYLEN MAXREPLIES
';
my @smflags = eval "qw/ $smflags /;";
my @dispatchers =  qw/ ithread_dispatcher postfork_dispatcher prefork_dispatcher sequential_dispatcher /;
my @callback_names = qw/ negotiate connect helo envfrom envrcpt data header eoh body eom close abort unknown /;
my %DEFAULT_CALLBACKS = map { $_ => $_.'_callback' } @callback_names;
# Don't export anything by default.
our @EXPORT = ();
# Everything else is OK.  I have tried.
our @EXPORT_OK = qw/
    SMFIP_DEFAULTS SMFIP_NOCONNECT SMFIP_NOHELO SMFIP_NOMAIL SMFIP_NORCPT SMFIP_NOBODY SMFIP_NOHDRS SMFIP_NOEOH SMFIP_NOUNKNOWN SMFIP_NODATA SMFIP_RCPT_REJ SMFIP_SKIP
    SMFIP_NR_CONN SMFIP_NR_HELO SMFIP_NR_MAIL SMFIP_NR_RCPT SMFIP_NR_DATA SMFIP_NR_HDR SMFIP_NR_EOH SMFIP_NR_BODY SMFIP_NR_UNKN SMFIP_HDR_LEADSPC SMFIP_MDS_256K SMFIP_MDS_1M
    SMFIM_CONNECT SMFIM_HELO SMFIM_ENVFROM SMFIM_ENVRCPT SMFIM_DATA SMFIM_EOM SMFIM_EOH
    SMFIS_CONTINUE SMFIS_REJECT SMFIS_DISCARD SMFIS_ACCEPT SMFIS_TEMPFAIL SMFIS_MSG_LOOP SMFIS_ALL_OPTS
    SMFIF_NONE SMFIF_ADDHDRS SMFIF_CHGBODY SMFIF_ADDRCPT SMFIF_DELRCPT SMFIF_CHGHDRS SMFIF_QUARANTINE SMFIF_CHGFROM SMFIF_ADDRCPT_PAR SMFIF_SETSYMLIST
    SMFI_V2_ACTS SMFI_V6_ACTS SMFI_CURR_ACTS SMFI_V2_PROT SMFI_V6_PROT SMFI_CURR_PROT
    MAXREPLYLEN MAXREPLIES
    ithread_dispatcher postfork_dispatcher prefork_dispatcher sequential_dispatcher
    negotiate_callback connect_callback helo_callback envfrom_callback envrcpt_callback data_callback header_callback eoh_callback body_callback eom_callback close_callback abort_callback unknown_callback
/;

# Three export tags for flags, dispatchers and callbacks.
our %EXPORT_TAGS = ( all => [ @smflags ], dispatchers => [ @dispatchers ], callbacks => [ (values %DEFAULT_CALLBACKS) ] );

our $enable_chgfrom = 0;

##### Methods

sub new ($) {
	bless {}, shift;
}

=pod

=over 4

=item get_max_interpreters()

Returns the maximum number of interpreters passed to C<main()>.  This is
only useful when called from within the dispatcher, as it is not set before
C<main()> is called.

=cut

sub get_max_interpreters ($) {
	my $this = shift;

	$this->{max_interpreters} || 0;
}

=pod

=item get_max_requests()

Returns the maximum number of requests per interpreter passed to C<main()>.  
This is only useful when called from within the dispatcher, as it is not set
before C<main()> is called.

=cut

sub get_max_requests ($) {
	my $this = shift;

	$this->{max_requests} || 0;
}

=pod

=item main([MAXCHILDREN[, MAXREQ]])

This is the last method called in the main block of a milter program.  If
successful, this call never returns; the protocol engine is launched and
begins accepting connections.

MAXCHILDREN (default 0, meaning unlimited) specifies the maximum number of
connections that may be serviced simultaneously.  If a connection arrives
with the number of active connections above this limit, the milter will
immediately return a temporary failure condition and close the connection.
Passing a value for MAXCHILDREN is optional.

MAXREQ (default 0, meaning unlimited) is the maximum number of requests that
a child may service before being recycled.  It is not guaranteed that the
interpreter will service this many requests, only that it will not go over
the limit.  MAXCHILDREN must be given if MAXREQ is to be set.

Any callback which C<die>s will have its output sent to C<warn>, followed by
a clean shutdown of the milter connection.  To catch any warnings generated
by the callbacks, and any error messages caused by a C<die>, set
C<$SIG{__WARN__}> to a user-defined subroutine.  (See L<perlvar>.)

=cut

sub main ($;$$$) {
	require Sendmail::PMilter::Context;

	my $this = shift;
	croak 'main: socket not bound' unless defined($this->{socket});
	croak 'main: callbacks not registered' unless defined($this->{callbacks});
	croak 'main: milter protocol version not defined' unless defined($this->{'milter protocol version'});

	my $max_interpreters = shift;
	my $max_requests = shift;

	$this->{max_interpreters} = $max_interpreters if (defined($max_interpreters) && $max_interpreters =~ /^\d+$/); # This test doesn't permit an empty string.
	$this->{max_requests} = $max_requests if (defined($max_requests) && $max_requests =~ /^\d+$/);

	my $dispatcher = $this->{dispatcher};

	unless (defined($dispatcher)) {
		my $dispatcher_name = ($ENV{PMILTER_DISPATCHER} || 'postfork').'_dispatcher';
		$dispatcher = &{\&{qualify_to_ref($dispatcher_name, 'Sendmail::PMilter')}};
	}

	my $handler = sub {
		my $ctx = new Sendmail::PMilter::Context(shift, $this->{callbacks}, $this->{callback_flags}, $this->{'milter protocol version'});

		$ctx->main();
	};

	&$dispatcher($this, $this->{socket}, $handler);
	undef;
}

=pod

=item register(NAME, CALLBACKS[, FLAGS])

Sets up the main milter loop configuration.

NAME is the name of the milter.  This should be the same name as passed to
auto_getconn() or auto_setconn(), but this PMilter implementation does not
enforce this.

CALLBACKS is a hash reference containing one or more callback subroutines.
For example

  my %callbacks = 
  (
    'negotiate' => \&my_negotiate_callback,
    'connect'   => \&my_connect_callback,
    'helo'      => \&my_helo_callback,
    'envfrom'   => \&my_envfrom_callback,
    'close'     => \&my_close_callback,
    'abort'     => \&my_abort_callback,
  );
  $milter->register( $milter_name, \%callbacks );

If a callback is not named in this hashref, the caller's package will be
searched for subroutines named "CALLBACK_callback", where CALLBACK is the
name of the callback function.

FLAGS is accepted for backward compatibility with older versions of
this module.  Consider it deprecated.  Set it to SMFI_V6_PROT for all
available 'actions' in any recent (last few years) Sendmail version.

If no C<negotiate> callback is registered, then by default the protocol
steps available are as described in .../libmilter/engine.c in the
Sendmail sources.  This means all the registered CALLBACKS plus the
SKIP function call which is allowed in the End Of Message callback.
Note that SMFIP_RCPT_REJ is specifically not included.

C<register()> must be called successfully exactly once.  If called a second
time, the previously registered callbacks will be erased.

Returns 1 on success, undef on failure.

=cut

sub register ($$$;$) {
	my $this = shift;
	$this->{name} = shift;

	carp 'register: no name supplied' unless defined($this->{name});
	carp 'register: passed ref as name argument' if ref($this->{name});

	my $callbacks = shift;
	my $pkg = caller;

	croak 'register: callbacks is undef' unless defined($callbacks);
	croak 'register: callbacks not hash ref' unless UNIVERSAL::isa($callbacks, 'HASH');

	# make internal copy, and convert to code references
	$callbacks = { %$callbacks };

	foreach my $cbname (keys %DEFAULT_CALLBACKS) {
	    my $cb = $callbacks->{$cbname};
	    if (defined($cb) && !UNIVERSAL::isa($cb, 'CODE')) {
		$cb = qualify_to_ref($cb, $pkg);
		if (exists(&$cb)) {
		    $callbacks->{$cbname} = \&$cb;
		} else {
		    delete $callbacks->{$cbname};
		}
	    }
	}

	$this->{callbacks} = $callbacks;
	$this->{callback_flags} = shift || 0;
	# MILTER PROTOCOL VERSION
	$this->{'milter protocol version'} = ($this->{callback_flags} & ~0x3F) ? 6 : 2;
	1;
}

=pod

=item setconn(DESC)

Sets up the server socket with connection descriptor DESC.  This is
identical to the descriptor syntax used by the "X" milter configuration
lines in sendmail.cf (if using Sendmail).  This should be one of the
following:

=over 2

=item local:PATH

A local ("UNIX") socket on the filesystem, named PATH.  This has some smarts
that will auto-delete the pathname if it seems that the milter is not
currently running (but this currently contains a race condition that may not
be fixable; at worst, there could be two milters running with one never
receiving connections).

=item inet:PORT[@HOST]

An IPv4 socket, bound to address HOST (default INADDR_ANY), on port PORT.  
It is not recommended to open milter engines to the world, so the @HOST part
should be specified.

=item inet6:PORT[@HOST]

An IPv6 socket, bound to address HOST (default INADDR_ANY), on port PORT.  
This requires IPv6 support and the Perl IO::Socket::IP package to be installed.
It is not recommended to open milter engines to the world, so the @HOST part
should be specified.

=back

Returns a true value on success, undef on failure.

=cut

sub setconn ($$) {
	my $this = shift;
	my $conn = shift;
	my $backlog = $this->{backlog} || 5;
	my $socket;

	croak "setconn: $conn: unspecified protocol"
		unless ($conn =~ /^([^:]+):([^:@]+)(?:@([^:@]+|\[[0-9a-f:\.]+\]))?$/);

	if ($1 eq 'local' || $1 eq 'unix') {
		require IO::Socket::UNIX;

		my $path = $2;
		my $addr = sockaddr_un($path);

		croak "setconn: $conn: path not absolute"
			unless ($path =~ m,^/,,);

		if (-e $path && ! -S $path) { # exists, not a socket
			$! = Errno::EEXIST;
		} else {
			$socket = IO::Socket::UNIX->new(Type => SOCK_STREAM);
		}

		# Some systems require you to unlink an orphaned inode.
		# There's a race condition here, but it's unfortunately
		# not easily fixable.  Using an END{} block doesn't
		# always work, and that's too wonky with fork() anyway.

		if (defined($socket) && !$socket->bind($addr)) {
			if ($socket->connect($addr)) {
				close $socket;
				undef $socket;
				$! = Errno::EADDRINUSE;
			} else {
				unlink $path; # race condition
				$socket->bind($addr) || undef $socket;
			}
		}

		if (defined($socket)) {
			$socket->listen($backlog) || croak "setconn: listen $conn: $!";
		}
	} elsif ($1 eq 'inet') {
		require IO::Socket::INET;

		$socket = IO::Socket::INET->new(
			Proto => 'tcp',
			ReuseAddr => 1,
			Listen => $backlog,
			LocalPort => $2,
			LocalAddr => $3
		);
	} elsif ($1 eq 'inet6') {
		require IO::Socket::IP;

		$socket = IO::Socket::IP->new(
			Proto => 'tcp',
			ReuseAddr => 1,
			Listen => $backlog,
			LocalService => $2,
			LocalHost => $3
		);
	} else {
		croak "setconn: $conn: unknown protocol";
	}

	if (defined($socket)) {
		$this->set_socket($socket);
	} else {
		carp "setconn: $conn: $!";
		undef;
	}
}

=pod

=item set_dispatcher(CODEREF)

Sets the dispatcher used to accept socket connections and hand them off to
the protocol engine.  This allows pluggable resource allocation so that the
milter script may use fork, threads, or any other such means of handling
milter connections.  See C<DISPATCHERS> below for more information.

The subroutine (code) reference will be called by C<main()> when the
listening socket object is prepared and ready to accept connections.  It
will be passed the arguments:

    MILTER, LSOCKET, HANDLER

MILTER is the milter object currently running.  LSOCKET is a listening
socket (an instance of C<IO::Socket>), upon which C<accept()> should be
called.  HANDLER is a subroutine reference which should be called, passing
the socket object returned by C<< LSOCKET->accept() >>.

Note that the dispatcher may also be set from one of the off-the-shelf
dispatchers noted in this document by setting the PMILTER_DISPATCHER
environment variable.  See C<DISPATCHERS>, below.

=cut

sub set_dispatcher($&) {
	my $this = shift;

	$this->{dispatcher} = shift;
	1;
}

=pod

=item set_listen(BACKLOG)

Set the socket listen backlog to BACKLOG.  The default is 5 connections if
not set explicitly by this method.  Only useful before calling C<main()>.

=cut

sub set_listen ($$) {
	my $this = shift;
	my $backlog = shift;

	croak 'set_listen: socket already bound' if defined($this->{socket});

	$this->{backlog} = $backlog;
	1;
}

=pod

=item set_socket(SOCKET)

Rather than calling C<setconn()>, this method may be called explicitly to
set the C<IO::Socket> instance used to accept inbound connections.

=cut

sub set_socket ($$) {
	my $this = shift;
	my $socket = shift;

	croak 'set_socket: socket already bound' if defined($this->{socket});
	croak 'set_socket: not an IO::Socket instance' unless UNIVERSAL::isa($socket, 'IO::Socket');

	$this->{socket} = $socket;
	1;
}

=pod

=back

=head1 SENDMAIL-SPECIFIC METHODS

The following methods are only useful if Sendmail is the MTA connecting to
this milter.  Other MTAs likely don't use Sendmail's configuration file, so
these methods would not be useful with them.

=over 4

=item auto_getconn(NAME[, CONFIG])

Returns the connection descriptor for milter NAME in Sendmail configuration
file CONFIG (default C</etc/mail/sendmail.cf> or whatever was set by
C<set_sendmail_cf()>).  This can then be passed to setconn(), below.

Returns a true value on success, undef on failure.

=cut

sub auto_getconn ($$;$) {
	my $this = shift;
	my $milter = shift || die "milter name not supplied\n";
	my $cf = shift || $this->get_sendmail_cf();
	local *CF;

	open(CF, '<'.$cf) || die "open $cf: $!";

	while (<CF>) {
		s/\s+$//; # also trims newlines

		s/^X([^,\s]+),\s*// || next;
		($milter eq $1) || next;

		while (s/^(.)=([^,\s]+)(,\s*|\Z)//) {
			if ($1 eq 'S') {
				close(CF);
				return $2;
			}
		}
	}

	close(CF);
	undef;
}

=pod

=item auto_setconn(NAME[, CONFIG])

Creates the server connection socket for milter NAME in Sendmail
configuration file CONFIG.

Essentially, does:

    $milter->setconn($milter->auto_getconn(NAME, CONFIG))

Returns a true value on success, undef on failure.

=cut

sub auto_setconn ($$;$) {
	my $this = shift;
	my $name = shift;
	my $conn = $this->auto_getconn($name, shift);

	if (defined($conn)) {
		$this->setconn($conn);
	} else {
		carp "auto_setconn: no connection for $name found";
		undef;
	}
}

=pod

=item get_sendmail_cf()

Returns the pathname of the Sendmail configuration file.  If this has
been set by C<set_sendmail_cf()>, then that is the value returned.
Otherwise the default pathname C</etc/mail/sendmail.cf> is returned.

=cut

sub get_sendmail_cf ($) {
	my $this = shift;

	$this->{sendmail_cf} || '/etc/mail/sendmail.cf';
}

=pod

=item get_sendmail_class(CLASS[, CONFIG])

Returns a list containing all members of the Sendmail class CLASS, in
Sendmail configuration file CONFIG (default C</etc/mail/sendmail.cf> or
whatever is set by C<set_sendmail_cf()>).  Typically this is used to look up
the entries in class "w", the local hostnames class.

=cut

sub get_sendmail_class ($$;$) {
	my $this = shift;
	my $class = shift;
	my $cf = shift || $this->get_sendmail_cf();
	my %entries;
	local *CF;

	open(CF, '<'.$cf) || croak "get_sendmail_class: open $cf: $!";

	while (<CF>) {
		s/\s+$//; # also trims newlines

		if (s/^C\s*$class\s*//) {
			foreach (split(/\s+/)) {
				$entries{$_} = 1;
			}
		} elsif (s/^F\s*$class\s*(-o)?\s*//) {
			my $required = !defined($1);
			local *I;

			croak "get_sendmail_class: class $class lookup resulted in pipe: $_" if (/^\|/);

			if (open(I, '<'.$_)) {
				while (<I>) {
					s/#.*$//;
					s/\s+$//;
					next if /^$/;
					$entries{$_} = 1;
				}
				close(I);
			} elsif ($required) {
				croak "get_sendmail_class: class $class lookup: $_: $!";
			}
		}
	}

	close(CF);
	keys %entries;
}

=pod

=item get_sendmail_option(OPTION[, CONFIG])

Returns a list containing the first occurrence of Sendmail option
OPTION in Sendmail configuration file CONFIG (default C</etc/mail/sendmail.cf>,
or whatever has been set by C<set_sendmail_cf()>).  Returns the
value of the option or undef if it is not found.  This can be used
to learn configuration parameters such as Milter.maxdatasize.

=cut

sub get_sendmail_option ($$;$) {
	my $this = shift;
	my $option = shift;
	my $cf = shift || $this->get_sendmail_cf();
	my %entries;
	local *CF;
	open(CF, '<'.$cf) || croak "get_sendmail_option: open $cf: $!";
	while (<CF>) {
		s/\s+$//; # also trims newlines
		if (/^O\s*$option=(\d+)/) { return $1; }
	}
	close(CF);
	undef;
}

=pod

=item set_sendmail_cf(FILENAME)

Set the default filename used by C<auto_getconn>, C<auto_setconn>, and
C<sendmail_class> to find Sendmail-specific configuration data.  If not
explicitly set by this method, it defaults to C</etc/mail/sendmail.cf>.
Returns 1.

=cut

sub set_sendmail_cf ($) {
	my $this = shift;

	$this->{sendmail_cf} = shift;
	1;
}

### off-the-shelf dispatchers

=pod

=back

=head1 DISPATCHERS

Milter requests may be dispatched to the protocol handler in a pluggable
manner (see the description for the C<set_dispatcher()> method above).
C<Sendmail::PMilter> offers some off-the-shelf dispatchers that use
different methods of resource allocation.

Each of these is referenced as a non-object function, and return a value
that may be passed directly to C<set_dispatcher()>.

=over 4

=item Sendmail::PMilter::ithread_dispatcher()

=item (environment) PMILTER_DISPATCHER=ithread

June 2019: This dispatcher has not been tested adequately.

The C<ithread> dispatcher spins up a new thread upon each connection to
the milter socket.  This provides a thread-based model that may be more
resource efficient than the similar C<postfork> dispatcher.  This requires
that the Perl interpreter be compiled with C<-Duseithreads>, and uses the
C<threads> module (available on Perl 5.8 or later only).

=cut

sub ithread_dispatcher {
	require threads;
	require threads::shared;
	require Thread::Semaphore;

	my $nchildren = 0;

	threads::shared::share($nchildren);

	sub {
		my $this = shift;
		my $lsocket = shift;
		my $handler = shift;
		my $maxchildren = $this->get_max_interpreters();
		my $child_sem;

		if ($maxchildren) {
		    $child_sem = Thread::Semaphore->new($maxchildren);
		}
		
		my $siginfo = exists($SIG{INFO}) ? 'INFO' : 'USR1';
		local $SIG{$siginfo} = sub {
			warn "Number of active children: $nchildren\n";
		};

		my $child_sub = sub {
			my $socket = shift;

			eval {
				&$handler($socket);
				$socket->close();
			};
			my $died = $@;

			lock($nchildren);
			$nchildren--;
			if ($child_sem) {
			    $child_sem->up();
			}
			warn $died if $died;
		};

		while (1) {
			my $socket = $lsocket->accept();
			next if $!{EINTR};

			warn "$$: incoming connection\n" if ($DEBUG > 0);

			if ($child_sem and ! $child_sem->down_nb()) {
			    warn "pausing for high load: children $nchildren >= max $maxchildren";
			    my $start = time();
			    $child_sem->down();
			    my $end = time();
			    warn sprintf("paused for %.1f seconds due to high load", $end - $start); 
			}

			# scoping block for lock()
			{
				lock($nchildren);
				my $t = threads->create($child_sub, $socket) || die "thread creation failed: $!\n";
				$t->detach;
				threads->yield();
				$nchildren++;
			}
		}
	};
}

=pod

=item Sendmail::PMilter::prefork_dispatcher([PARAMS])

=item (environment) PMILTER_DISPATCHER=prefork

June 2019: This dispatcher has been tested extensively by the maintainer.

The C<prefork> dispatcher forks the main Perl process before accepting
connections, and uses the main process to monitor the children.  This
should be appropriate for steady traffic flow sites.  Note that if
MAXINTERP is not set in the call to C<main()> or in PARAMS, an internal
default of 10 processes will be used; similarly, if MAXREQ is not set, 100
requests will be served per child.

Currently the child process pool is fixed in size:  discarded children will
be replaced immediately.

PARAMS, if specified, is a hash of key-value pairs defining parameters for
the dispatcher.  The available parameters that may be set are:

=over 2

=item child_init

subroutine reference that will be called after each child process is forked.
It will be passed the C<MILTER> object.

=item child_exit

subroutine reference that will be called just before each child process
terminates.  It will be passed the C<MILTER> object.

=item max_children

Maximum number of child processes active at any time.  Equivalent to the
MAXINTERP option to main() -- if not set in the main() call, this value
will be used.

=item max_requests_per_child

Maximum number of requests a child process may service before being
recycled.  Equivalent to the MAXREQ option to main() -- if not set in the
main() call, this value will be used.

=back

=cut

sub prefork_dispatcher (@) {
	my %params = @_;
	my %children;

	my $child_dispatcher = sub {
		my $this = shift;
		my $lsocket = shift;
		my $handler = shift;
		my $max_requests = $this->get_max_requests() || $params{max_requests_per_child} || 100;
		my $i = 0;

		local $SIG{PIPE} = 'IGNORE'; # so close_callback will be reached

		my $siginfo = exists($SIG{INFO}) ? 'INFO' : 'USR1';
		local $SIG{$siginfo} = sub {
			warn "$$: requests handled: $i\n";
		};

		# call child_init handler if present
		if (defined $params{child_init}) {
			my $method = $params{child_init};
			$this->$method();
		}

		while ($i < $max_requests) {
			my $socket = $lsocket->accept();
			next if $!{EINTR};

			warn "$$: incoming connection\n" if ($DEBUG > 0);

			$i++;
			&$handler($socket);
			$socket->close();
		}

		# call child_exit handler if present
		if (defined $params{child_exit}) {
			my $method = $params{child_exit};
			$this->$method();
		}
	};

	# Propagate some signals down to the entire process group.
	my $killall = sub {
		my $sig = shift;

		kill 'TERM', keys %children;
		exit 0;
	};
	local $SIG{INT} = $killall;
	local $SIG{QUIT} = $killall;
	local $SIG{TERM} = $killall;

	setpgrp();

	sub {
		my $this = $_[0];
		my $maxchildren = $this->get_max_interpreters() || $params{max_children} || 10;

		while (1) {
			while (scalar keys %children < $maxchildren) {
				my $pid = fork();
				die "fork: $!" unless defined($pid);

				if ($pid) {
					# Perl reset these to IGNORE.  Restore them.
					$SIG{INT} = $killall;
					$SIG{QUIT} = $killall;
					$SIG{TERM} = $killall;
					$children{$pid} = 1;
				} else {
					# Perl reset these to IGNORE.  Set to defaults.
					$SIG{INT} = 'DEFAULT';
					$SIG{QUIT} = 'DEFAULT';
					$SIG{TERM} = 'DEFAULT';
					&$child_dispatcher(@_);
					exit 0;
				}
			}

			# Wait for a pid to exit, then loop back up to fork.
			my $pid = wait();
			delete $children{$pid} if ($pid > 0);
		}
	};
}

=pod

=item Sendmail::PMilter::postfork_dispatcher()

=item (environment) PMILTER_DISPATCHER=postfork

June 2019: This dispatcher has not been tested adequately.

This is the default dispatcher for PMilter if no explicit dispatcher is set.

The C<postfork> dispatcher forks the main Perl process upon each connection
to the milter socket.  This is adequate for machines that get bursty but
otherwise mostly idle mail traffic, as the idle-time resource consumption is
very low.

If the maximum number of interpreters is running when a new connection
comes in, this dispatcher blocks until a slot becomes available for a
new interpreter.

=cut

sub postfork_dispatcher () {
	my $nchildren = 0;
	my $sigchld;

	$sigchld = sub {
		my $pid;
		$nchildren-- while (($pid = waitpid(-1, WNOHANG)) > 0);
		$SIG{CHLD} = $sigchld;
	};

	sub {
		my $this = shift;
		my $lsocket = shift;
		my $handler = shift;
		my $maxchildren = $this->get_max_interpreters();

		# Decrement child count on child exit.
		local $SIG{CHLD} = $sigchld;

		my $siginfo = exists($SIG{INFO}) ? 'INFO' : 'USR1';
		local $SIG{$siginfo} = sub {
			warn "Number of active children: $nchildren\n";
		};

		while (1) {
			my $socket = $lsocket->accept();
			next if !$socket;

			warn "$$: incoming connection\n" if ($DEBUG > 0);

			# If the load's too high, fail and go back to top of loop.
			my $paused = undef;
			while ($maxchildren) {
			    my $cnchildren = $nchildren; # make constant

			    if ($cnchildren >= $maxchildren) {
				warn "pausing for high load: children $cnchildren >= max $maxchildren";
				if ( ! $paused ) { $paused = time(); }
				pause();
			    }
			    else {
				last;
			    }
			}
			if ($paused) {
			    warn sprintf( "paused for %.1f seconds due to high load", time() - $paused );
			}

			my $pid = fork();

			if ($pid < 0) {
				die "fork: $!\n";
			} elsif ($pid) {
				$nchildren++;
				$socket->close() if defined($socket);
			} else {
				$lsocket->close();
				undef $lsocket;
				undef $@;
				$SIG{PIPE} = 'IGNORE'; # so close_callback will be reached
				$SIG{CHLD} = 'DEFAULT';
				$SIG{$siginfo} = 'DEFAULT';

				&$handler($socket);
				$socket->close() if defined($socket);
				exit 0;
			}
		}
	};
}

=pod

=item Sendmail::PMilter::sequential_dispatcher()

=item (environment) PMILTER_DISPATCHER=sequential

June 2019: This dispatcher has not been tested adequately.

The C<sequential> dispatcher forces one request to be served at a time,
making other requests wait on the socket for the next pass through the loop.
This is not suitable for most production installations, but may be quite
useful for milter debugging or other software development purposes.

Note that, because the default socket backlog is 5 connections, if you
use this dispatcher it may be wise to increase this backlog by calling
C<set_listen()> before entering C<main()>.

=cut

sub sequential_dispatcher () {
	sub {
		my $this = shift;
		my $lsocket = shift;
		my $handler = shift;
		local $SIG{PIPE} = 'IGNORE'; # so close_callback will be reached

		while (1) {
			my $socket = $lsocket->accept();
			next if $!{EINTR};

			warn "$$: incoming connection\n" if ($DEBUG > 0);

			&$handler($socket);
			$socket->close();
		}
	};
}

1;
__END__

=pod

=back

=head1 EXPORTS

Each of these symbols may be imported explicitly, imported with tag C<:all>,
or referenced as part of the C<Sendmail::PMilter::> package.

=over 2

=item Callback Return Values

  SMFIS_CONTINUE - continue processing the message
  SMFIS_REJECT - reject the message with a 5xx error
  SMFIS_DISCARD - accept, but discard the message
  SMFIS_ACCEPT - accept the message without further processing
  SMFIS_TEMPFAIL - reject the message with a 4xx error
  SMFIS_MSG_LOOP - send a never-ending response to the HELO command

In the C<envrcpt> callback, SMFIS_REJECT and SMFIS_TEMPFAIL will reject
only the current recipient.  Message processing will continue for any
other recipients as if SMFIS_CONTINUE had been returned.

In all callbacks, SMFIS_CONTINUE tells the MTA to continue calling the
milter (and any other milters which may be installed), for the remaining
message steps.  Except as noted for the C<envrcpt> callback, all the
other return values terminate processing of the message by all the
installed milters.  Message disposal is according to the return value.

=back

=head1 SECURITY CONSIDERATIONS

=over 4

=item Running as root

Running Perl as root is dangerous.  Running C<Sendmail::PMilter> as root may
well be system-assisted suicide at this point.  So don't do that.

More specifically, though, it is possible to run a milter frontend as root,
in order to gain access to network resources (such as a filesystem socket in
/var/run), and then drop privileges before accepting connections.  To do
this, insert drop-privileges code between calls to setconn/auto_setconn and
main; for instance:

    $milter->auto_setconn('pmilter');
    $> = 65534; # drop root privileges
    $milter->main();

The semantics of properly dropping system administrator privileges in Perl
are, unfortunately, somewhat OS-specific, so this process is not described
in detail here.

=back

=head1 AUTHORS

Todd Vierling, Ged Haywood.

=head1 Maintenance

cpan:GWHAYWOOD now maintains Sendmail::PMilter.  Use the CPAN issue
tracking system to request more information, or to comment.  Private
mail is fine but you'll need to use the right email address, it should
be obvious.  This module is NOT maintained on Sourceforge/Github/etc..

=head1 See also

L<Sendmail::PMilter::Context>

The Sendmail documentation, especially libmilter/docs/* in the sources
of Sendmail version 8.15.2 and later.

=head1 THANKS

rob.casey@bluebottle.com - for the prefork mechanism idea

=cut

1;

__END__
