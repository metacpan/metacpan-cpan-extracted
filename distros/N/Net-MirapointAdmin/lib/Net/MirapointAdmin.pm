#!/usr/bin/perl -w
##############################################################################
#
#	Net::MirapointAdmin Module
#	Copyright (C) 1999-2008, Mirapoint Inc.  All rights reserved.
#
#	History:
#	2008-01-14	nick@mirapoint.com (3.06)
#			Fix several Unicode related bugs
#	2007-09-18	gpalmer@mirapoint.com (3.05)
#			Update get_response to cope with the output from
#			some MOS commands which do not add an extra blank
#			line after the literal section
#	2007-03-20	adrianhall@mirapoint.com (3.04)
#			Corrected 00_use.t test - no changes to the
#			library except for the version string.
#	2007-03-19	adrianhall@mirapoint.com (3.03)
#			Corrected Makefile.PL so that automated testers
#			would work - no changes to the library except for
#			the version string.
#       2007-03-12	gpalmer@mirapoint.com (3.02)
#			Fixed issue resulting from an API change in
#			recent versions of IO::Socket::SSL that prevented
#			SSL connections from working
#	2005-03-10	ahall@mirapoint.com (3.01)
#			Fixed issues with the return values of the low
#			level protocol to match what the docs say and
#			what the module tests perform
#	2005-03-09	ahall@mirapoint.com (3.01)
#			Fixed the problem on later versions of Perl (> 5.8.3)
#			that $! == errno, not a string.
#	2005-03-07	gpalmer@mirapoint.com (3.0)
#			Fixed two more !defined bugs in send_command and
#			get_response
#	2005-03-04	ahall@mirapoint.com (3.0)
#			Name change to Net::MirapointAdmin
#			Change per-character I/O to per-line I/O
#			Make exception handling in new() work properly
#			Fix the !defined problem in login()
#	2004-12-06	gpalmer@mirapoint.com (2.10)
#			Handle reply from "autoreply get" better.
#	2004-08-13	ahall@mirapoint.com
#			Doc fix - the link to the protocol guide is broken
#       2004-08-02  	ahall@mirapoint.com (2.9)
#                 	Fixed $VERSION to reflect new version number
#       2004-07-22  	jxh@mirapoint.com
#                 	Fix EOF/error handling in _getline().
#                  	Permit debugfunc on new() for connection debugging.
#	2004-03-04	gpalmer@mirapoint.com (2.8)
#			Fix a few bugs relating to checking the handshake
#			from the remote server, and also hex encode
#			the version into mos_ver.
#	2002-06-14	ahall@mirapoint.com (2.7)
#			Added custom debug logging.  Removed tagprint (it
#			wasn't doing the right thing anyway!).  
#			Fixed documentation for new custom debug logging
#			Corrected problems in the low-level problems which
#			are only seen if you don't undef the connection prior
#			to quitting on the newer version of Perl.
#	2001-12-18	ahall@mirapoint.com 
#			Updated script so that it is suitable for uploading
#			to PAUSE/CPAN
#	2001-08-28	ahall@mirapoint.com (2.6)
#			Fixed the version number to match the Version: line 
#			above.
#	2001-05-11	jxh@mirapoint.com 
#			Fix some runtime warnings about undefined vars.
#	2001-04-02	ahall@mirapoint.com (2.5)
#			SSL Integration using std. IO::Socket::SSL instead
#			of the Net::SSLeay module
#	2001-03-12	ahall@mirapoint.com (2.4)
#			PR #7564.  zero length literal strings were not
#			handled appropriately.  They are now.
#	2001-01-08	ahall@mirapoint.com (2.3)
#			Updated quote/de-quote to handle parens.
#	2000-03-21	ahall@mirapoint.com (2.2)
#			Integrated pod documentation from Tech Pubs.  Also
#			added a version so that make dist will work properly
#	2000-03-17	ahall@mirapoint.com (3895)
#			loggedin() gets maintained across command(), so
#			calling command('LOGOUT') will set it to 0.
#	2000-03-15	ahall@mirapoint.com
#			OpenSSL is illegal in US, so disabled SSL.
#	2000-03-10	ahall@mirapoint.com
#			Updated SSL integration - Released as 2.1.
#	2000-03-09	ahall@mirapoint.com
#			First pass at SSL integration
#	2000-02-22	jxh@mirapoint.com
#			Deal with server literals that do not end in \r\n.
#	2000-02-09	jxh@mirapoint.com
#			Fixed quoting, dequoting.  Released as 2.0.
#	2000-01-19	jxh@mirapoint.com
#			Overhauled to include older, low-level interface.
#	1999-10-18	sandeep@mirapoint.com
#			Added functionality for extracting sessionID.
#	1999-10-06	jxh@mirapoint.com
#			Don't dereference unblessed object if error during
#			new().
#	1999-10-05	ahall@mirapoint.com
#			Corrected bug in get_response due to the fact that
#			some commands only return an OK and no message
#			afterwards (e.g. UPDATE LIST)
#	1999-09-27	ahall@mirapoint.com
#			Tidyed up documentation and added DESTROY destructor
#			function.
#	1999-09-26	jxh@mirapoint.com	
#			Revised to handle literal strings.  
#			Also revised the API.
#	1999-09-01	ahall@mirapoint.com
#			Initial Edit
#
##############################################################################
# 
#	This module provides Perl access routines for dealing 
# with the Mirapoint administration protocol, as implemented in Mirapoint
# Internet Messaging appliances.  Refer to http://www.mirapoint.com/.
# 
# Examples of use:
#
#    High-level interface: handles tag generation/stripping,
#    quoted and literal arguments and binding to Perl data types (in an
#    array context), optional response checking, and auto-logout before
#    disconnection.  Exception handler can be set.
#
#    Both "raw" and "cooked" commands and responses are supported:
#    send_command() with a single scalar argument simply generates and
#    prepends a tag; get_response() checks and strips the tag from the
#    response.  send_command(LIST) quotes arguments containing embedded
#    spaces and makes IMAP-style literals of those containing newlines,
#    and sends the list as a single, tagged command.
#
#    get_response() in stores the OK or NO response in the object, and, in a
#    scalar context, returns any other output (minus tags) as a single string,
#    with embedded newlines.  In an array context, it returns a two-dimensional
#    array, by line and field.  Responses are dequoted, and counted literals
#    are stored as scalars.
#
#    command(), command_ok(), and command_no() behave the same way, but they
#    combine send_command() and get_response(), and optionally check the OK/NO
#    response.
#
#    EXAMPLES OF USE:
#
#    Login:
#
#       $mp = Net::MirapointAdmin->new(host => $host,
#                                   port => $port,
#                                   debug => $debug);
#       $mp->login($user, $password);
#
#    Raw command and raw response:
#
#	$status = $mp->command_ok("BACKUP STATUS");
#  	    results in:
#       C: tag BACKUP STATUS\r\n
#       S: * tag Backup-10000 Error\r\n
#	S: * tag Backup-10000 Done\r\n
#       S: tag OK\r\n
#	$status = "Backup-10000 Error\nBackup-10000 Done\n"
#
#    Cooked command:
#
#	$user = "bob"; $password = "pwd"; $fullname = "Bob Smith";
#	$mp->command_ok(qw/USER ADD/, $user, $password, $fullname);
#	    results in:
#	C: tag USER ADD bob pwd "Bob Smith"\r\n
#	S: tag OK\r\n
#
#    Cooked command and response:
#
#	$pattern = ""; $start = "", $count = "";
#	@users = $mp->command_ok(qw/USER LIST/, $pattern, $start, $count);
#	@usernames = map { $_ = $$_[0] } @users;
#	    results in:
#	C: tag USER LIST "" "" ""\r\n
#	S: * tag "bob" "Bob Smith"\r\n
#	S: * tag "joe" "Joe Brown"\r\n
#	S: tag OK
#	@users = ( [ "bob", "Bob Smith" ], [ "joe", "Joe Brown" ] )
#	@usernames = ("bob", "joe");
#
#    With error checking (OK, or NO followed by pattern):
#
#       $mp->command_no(/Already exists/, qw/DL ADD/, $dl);
#
#    Manual error checking:
#
#	@response = $mp->command(qw/DLENTRY LIST/, $dl, "", "", "");
#	if ($mp->okno =~ /^NO/) {
#		...
#	}
#
#    Logout:
#
#       undef $mp;              -- Performs logout and disconnect
#
#
##############################################################################
package Net::MirapointAdmin;

use strict;
use vars qw($ERRSTR $VERSION $AUTOLOAD);

$VERSION = "3.06";
$ERRSTR  = "";

use bytes ();

use Carp;
use Socket;
use IO::Socket;	
#
# We have this version to determine the right API support.
#
#
# Since we do not necessarily have SSL, we need to be careful when loading
# the module to ensure we are handling it appropriately.
#
my $SSL;
BEGIN {
	eval 'use IO::Socket::SSL';
	if (!defined $@ || $@ ne "")
	{
		$SSL = 0;
	} else {
		$SSL = 1;
	}
}
#
##############################################################################
#
#	Function to return the SSL support.
#
sub supports_ssl
{
	return $SSL;
}
#
##############################################################################
#
# The entities in %MP_Fields are also the entities that can be called for
# setting and retrieving of information.  
#
my %MP_Fields = (
	"hostname"	=> undef,	# Who are we connected to?
	"portnumber"	=> undef,	# and where?
	"reported_hostname" => undef,	# Who does it think it is?
	"error"		=> undef,	# What was the last error?
	"debug"		=> 0,		# Is debugging turned on?
	"version"	=> undef,	# What version are we connecting to?
	"mos_ver"	=> undef,	# Hex encoding of "version"
	"connected"	=> 0,		# Are we connected?
	"loggedin"	=> 0,		# and logged in?
	"socket"	=> undef,	# the socket descriptor?
	"sessionid"	=> undef,	# the sessionid?
	"lasttag"	=> 0,		# and the last tag we handled?
	"exception"	=> undef,	# the exception handler
	"okno"		=> undef,	# last OK/NO response
	"ssl"		=> 0,		# Are we on an SSL link?
	"ignore_hand"	=> 0,		# Ignore the Handshake?
	"debugfunc"	=> undef,	# Non-default debug function
);
#
###############################################################################
#
#	Function:	AUTOLOAD
#	
#	This is actually the "catch-all" function.  We use this to set or
# get the settings within %MP_Fields.  In our case, this means you can do
# things like:
#
#	$conn->debug(1);
#	$debug = $conn->debug();
# 
sub AUTOLOAD
{
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object.";
	my $name = $AUTOLOAD;
	
	$name =~ s/.*://;	# Strip fully-qualified version.
	croak "Cannot access $name in object of class $type.\n"
		unless (exists $self->{$name});
	if (@_) 
	{
		if ($name eq "error" && $self->{"debug"})
		{
			print "ERROR: $_[0]\n";
		}
		$self->{$name} = shift;
	} 
	return $self->{$name};
}

###############################################################################
#
#	Function: 	_default_exception(LIST)
#
#	Usage:		$obj->default_exception("Doing thing 1");
#	Arguments:	none.
#	Returns:	undef.
#	Error:		dies.
#	
#	This is the default exception handler, used if no user-specified
#	handler is supplied on new() or in a later call to
#	$obj->exception().  Prints each argument and the value of
#	$self->error, then dies.

sub _default_exception
{
	my $self = shift;
	my $report = join("", @_);
	my $err = $self->{"error"};
	if (defined $err)
	{
		die "Error $err\n$report";
	} else {
		die $report;
	}
}

sub raise_exception
{
	my $self = shift;

	&{$self->{exception}}($self, @_);
}

###############################################################################
#	Function:	debuglog(message)
#	Usage:		<internal only>
#	Arguments:	Message to be logged
#	Returns:	nothing
#	Error:		returns
#
#	This is the default log routine for the system
#
sub debuglog
{
	my $self = shift;
	my $msg = join('', @_);

	if (defined $self->{debugfunc}) {
		$self->{debugfunc}->($msg);
	} else {
		print STDERR $msg, "\n";
	}
}

###############################################################################
#
#	Function: 	new(List)
#
#	Usage:		$obj = Net::MirapointAdmin->new(host=>$host)
#	Arguments:	host (string) 		DNS hostname, required
#			port (numeric) 		TCP port number
#			exception (subroutine) 	exception handler
#			debug (boolean)		Default to 0
#			ssl (boolean)		Default to 0
#			ignore_handshake (boolean)	Default to 1
#			debugfunc (coderef)	Default to undef
#	Returns:	object reference
#	Error:		raises exception
#	
#	Creates a blessed instance of this object, and uses it to connect.
#	If exception is not specified, a default exception handler is used.
#	On error, raises exception, then returns whatever the exception
#	handler itself returns.  The exception handler should usually not
#	return at all.
#	
#
sub new
{
	my $that = shift;
	my $class = ref($that) || $that;
	my $self = { %MP_Fields };
	bless $self, $class;

	my %args;
	my $connect_now = 0;

	if ($#_ < 1 || $_[0] ne "host" ) 	# Hostname only or host, port
	{	
		$args{"host"} = shift;
		if (@_) 
		{				# host,port
			$args{"port"} = shift;
			$connect_now = 1;
		}
	} else {				# named arguments
		%args = @_;
		$connect_now = 1;
	}

	$self->{"hostname"} = $args{"host"};
	$self->{"exception"} =  $args{"exception"} || \&_default_exception;
	$self->{"debug"} = $args{"debug"} || 0;
	$self->{"ignore_hand"} = $args{"ignore_handshake"} || 0;
        $self->{"debugfunc"} = $args{"debugfunc"} || undef;


	if (defined $args{"ssl"} && $args{"ssl"} > 0)
	{
		if ($SSL != 1)
		{
			$self->error("SSL requested but not available");
			$self->raise_exception();
		} else {
			$self->{"ssl"} = 1;
			$self->{"portnumber"} = $args{"port"} || 10243;
		}
	} else {
		$self->{"ssl"} = 0;
		$self->{"portnumber"} = $args{"port"} || 10143;
	}
	if (!defined $args{"host"})
	{
		$self->error("No hostname specified in new()");
		return $self->raise_exception();
	}
	return $self->connect($connect_now) if $connect_now; 
	return $self;
}
#
###############################################################################
#
#	Function:	login(Username, Password)
#
#	Usage:		$obj->login($user, $password);
#	Returns:	defined
#	Error:		raises exception
#
#	Uses the open connection to issue a LOGIN command, and sets an
# internal variable in the object to allow further command()s.
# Returns undef on an error and a defined value on success.

sub login
{
	my $self = shift;
	my $user = shift;
	my $pass = shift;
	my($res);

	if ($self->connected != 1)
	{
		$self->error("Not Connected");
		return $self->raise_exception();
	}

	$res = $self->command_ok("LOGIN", $user, $pass);
	if ($self->{"okno"} =~ /^OK/) {
		$self->loggedin(1);
		$self->sessionid($res);
		return 1;
	}
	return undef;
} 


###############################################################################
#
#	Function:	send_command(List);
#
#	Usage:		$lasttag = $obj->send_command(qw/LICENSE STATUS/);
#	Returns:	string
#	Error:		raises exception
#
#	This function sets up a tag (based on $self->{lasttag}) and sends a
# command to the admin API consisting of arguments in LIST.  We return the
# tag to be used in a later get_response() call.
# Each element of the list is quoted if it contains spaces, or is sent as
# an IMAP-style counted literal if it contains newlines.
# If LIST contains only a single scalar, it is neither quoted nor sent as a
# literal.

sub send_command
{
	my $self = shift;
	my @cmd = @_;
	my $tag = $self->{lasttag}++;
	my ($cmd);
	
	if ($self->connected == 0)
	{
		$self->error("Not Connected.");
		return $self->raise_exception();
	}
	if (@cmd < 2) {	# scalar command
		$cmd = $tag . " " . $cmd[0];
	} else {
		$cmd = $tag . " " . $self->_pack_args(@cmd);
	}

	if (! $self->xmit($cmd)) {
		return undef;
	}

	return $tag;
}



###############################################################################
#
#	Function:	get_response(Tag)
#
#	Usage:		$obj->get_response($lasttag);
#	Returns:	defined
#	Error:		raises exception
#
#	This function reads a multi-line admin response and returns it, in an
#	array context, as an array of arrays, by line and field.  Responses are
#	dequoted, and counted literals are stored as scalars.
#	Called in a scalar context, the multi-line response is only stripped of
#	tags and returned in a single string, with embedded newlines.
#	On error, we return undef and $obj->error is set appropriately.
#	The OK/NO response line is stored in the object, to permit multi-
#	threaded operation.

sub get_response
{
	my $self = shift;
	my $tag = shift;
	my($response, @response, @line, $line, $lineref);
	my($done, $lit, $count, $buf);
	my $cooked = wantarray;

	if ($self->connected == 0)
	{
		$self->error("Not Connected.");
		return $self->raise_exception();
	}
	@response = ();	# cooked response
	$response = ""; # raw response
	$self->okno(undef);
	my $blankOK = 0;
	while (1)
	{
		$line = $self->_getline;
		if (!defined $line)
		{
			$self->error("Connection was dropped.");
			return $self->raise_exception();
		}
		if ( $line eq '' )
		{
			$self->error("EOF on connection.");
			return $self->raise_exception();
		}
		if ($blankOK == 1)
		{
			$blankOK = 0;
			next if ($line =~ /^[\r\n]+$/);
		}
		$lineref = [];
		#
		# Now that we have a line, check to see if it is a
		# continuation line or a command termination (or
		# something else) and act appropriately.
		#
		if ($line =~ /^\* $tag /)
		{
			$line =~ s/^\* $tag //g;
			$line =~ s/\r\n$/\n/;
			if ($cooked) {
				chop($line);	# discard newline
			} else {
				$response .= $line;	# keep newline
			}
			# continue processing arguments
		} elsif ($line =~ /^$tag OK/ || $line =~ /^$tag NO/) {
			$line =~ s/^$tag //g;
			$line =~ s/\r\n$//;
			$self->okno($line);
			if ($cooked) {
				return @response;
			} else {
				return $response;
			}
		} else {
			$line =~ s/\r\n$/\n/;
			# This is possible during clean-up
			if ($line eq "") {
				return @response;
			}
			$self->error("Unknown tag: $line");
			return $self->raise_exception();
		}
		$self->_dequote_args($lineref, \$line) if $cooked;
		if (defined $line && $line =~ /\{[0-9]+\}\n*$/) {	
			# Handle Literal String
			$lit = "";
			$count = $line;
			$count =~ s/^.*\{(\d+)\}$/$1/;
			while ($count > 0) {
				$line = $self->_getline;
				unless (defined $line) 
				{
					$self->error("Connection was dropped.");
					return $self->raise_exception();
				}
				if ($line eq '') 
				{
					$self->error("EOF on connection.");
					return $self->raise_exception();
				}
				# _getline will eat the \r\n after the literal
				# if the literal does not itself end with \n.
				# In this case, $count would become negative.
				if ($count < bytes::length($line)) {	
					substr($line, $count) = ""; 
				}
				$count -= bytes::length($line);
				$lit .= $line;
				last if bytes::length($line) <= 0;
			}
			if ($cooked) {
				push(@$lineref, $lit);
			} else {
				$response .= $lit; $response .= "\n";
			}
			# Eat closing CRLF if necessary
			$blankOK = 1
				if ($lit eq "" || $lit =~ /\n$/);
		}
		push(@response, $lineref) if $cooked;
	}
	# We should never get here, but if we do, its an error.
	$self->error("Net::MirapointAdmin Generic Error 1");
	return $self->raise_exception();
}


###############################################################################
#
#	Function:	command(List);
#
#	Usage:		$obj->command(qw/USER LIST/);
#	Returns:	array or scalar
#	Error:		raises exception
#
#	This function issues an admin command and returns its response.
#	If LIST has only one value, it is a raw command; see send_command().
#	In an array context, returns the response as an array of arrays,
#	by line and field.  In a scalar context, returns raw response;
#	see get_response().
#
#	On error, raises an exception.  (NB: a "NO" response is not
#	considered an error here.)
#	The OK/NO response line is stored in the object, to permit multi-
#	threaded operation.
#

sub command
{
	my ($self) = shift;
	my ($tag, $response, @response);

	$tag = $self->send_command(@_);
	return $self->raise_exception() unless $tag;
	if (wantarray) {
		@response = $self->get_response($tag);
	} else {
		$response = $self->get_response($tag);
	}
	$self->{"loggedin"} = 0 if ($_[0] =~ /logout/i);
	return (wantarray ? @response : $response);
}


###############################################################################
#
#	Function:	command_ok(List);
#
#	Usage:		$obj->command_ok(qw/MAILBOX LIST/, "%");
#	Returns:	array or scalar
#	Error:		raises exception
#
#	This function calls command(), but then checks the OK/NO response
#	and raises an exception if the response is not "OK".
#	It's useful for issuing routine commands that are expected to
#	produce an "OK" response.
#
#	If LIST has only one value, it is a raw command; see send_command().
#	In an array context, returns the response as an array of arrays,
#	by line and field.  In a scalar context, returns raw response;
#	see get_response().

sub command_ok
{
	my ($self) = shift;
	my ($response, @response);
	if (wantarray) {
		@response = $self->command(@_);
	} else {
		$response = $self->command(@_);
	}
	if ($self->okno !~ /^OK/)
	{
		return $self->raise_exception("ERROR: ", $self->okno, " in COMMAND ", join(" ", @_), "\n");
	}
	if (wantarray) {
		return @response;
	} else {
		return $response;
	}
}

###############################################################################
#
#	Function:	command_no(Regexp, List);
#
#	Usage:		$obj->command_no(/Already exists/, qw/DL ADD/, $dl);
#	Returns:	array or scalar
#	Error:		raises exception, then returns undef
#
#	This function calls command(), but then checks the OK/NO response.
#	A "NO" response that matches the supplied regular expression is
#	considered the same as an "OK" response.
#	This is useful for issuing commands that can return an expected
#	"NO" response in some cases.
#
#	Many scripts will likely use command_ok() and command_no() for most
#	of their work.
#	If LIST has only one value, it is a raw command; see send_command().
#
#	In an array context, returns the response as an array of arrays,
#	by line and field.  In a scalar context, returns raw response;
#	see get_response().

sub command_no
{
	my ($self) = shift;
	my ($regexp) = shift;
	my ($response, @response);
	if (wantarray) {
		@response = $self->command(@_);
	} else {
		$response = $self->command(@_);
	}
	return $self->raise_exception("ERROR: ", $self->okno, " in COMMAND ", join(" ", @_), "\n") unless ($self->okno =~ /^OK/ || ($self->okno =~ /^NO/) && ($self->okno =~ $regexp));
	if (wantarray) {
		return @response;
	} else {
		return $response;
	}
}

###############################################################################
#
#	Function:	DESTROY
#
#	This function is called when the Perl script destructs the object.  We
# use this to log out of the system and disconnect from the admin API.   
#
sub DESTROY
{
	my $self = shift;
	
	return if ($self->{"connected"} == 0);
	return if ($self->{"loggedin"} == 0);

	$self->command("logout");
	if (defined $self->{"socket"}) {
		$self->{"socket"}->close();
	}
	return;
}

###############################################################################
#
#	Function:	_getline
#
# 	A low-level function that implements getline() at the socket level.
#
#	Unfortunately, as of IO::Socket::SSL v0.77, getline() was not 
#	implemented.  Thus, we have to do this the old fashioned way.  The
#	only real way to do this is by reading byte by byte (since in SSL
#	we cannot go back)
#
#	As of IO::Socket::SSL v0.96, this has been repaired, so this should
#	now work.
#
sub _getline
{
    my $self = shift;

    # If we aren't connected, return undef
    return undef if ($self->connected() != 1);

    # If our socket has disappeared, return undef
    my $fd = $self->{'socket'};
    return undef if (!defined $fd);

    # This should now work.
    my $ret = <$fd>;
    if ($ret) {
        $self->debuglog("S: $ret") if ($self->{"debug"});
    } else {
    	$self->debuglog("S: return is undef") if ($self->{"debug"});
    }

    return $ret;
}

###############################################################################
#
#	Function:	_pack_args
#
#	Turns a list of scalars into a string of IMAP-style arguments,
#	quoting blank arguments and those with embedded spaces, and
#	encoding in literals those containing newlines.
#	Backslashes ('\') and double-quotes ('"') are escaped with
#	a leading backslash.  Arguments containing these escapes are
#	quoted just as for embedded spaces.
#
sub _pack_args
{
	my ($self) = shift;
	my ($cmd, @cmd, $lit, $quoteme);
	$cmd = "";
	@cmd = ();
	for (@_) {
		$quoteme = 0;
		if (/\n/) {			# literal
			$lit = $_;		# work on a copy of it
#			$lit =~ s/[^\r]\n/\r\n/g;	# force network EOLs
			$cmd = "{" . bytes::length($lit) . "+}\r\n" . $lit;
		} else {
			$cmd = $_;
			if (/\\/) {		# escape literal backslashes
				$cmd =~ s/\\/\\\\/g;
				$quoteme = 1;
			}
			if (/\"/) {		# escape literal quotes
				$cmd =~ s/\"/\\\"/g;
				$quoteme = 1;
			}
			if (/^$/ || /[\(\)\s]/ || $quoteme) {
				# quote if embedded space or \ or "
				# 2001-01-08 - also quote if embedded parens
				$cmd = '"' . $cmd . '"';
			}
			# else bareword
		}
		push(@cmd, $cmd);		# accumulate
	}
	return join(" ", @cmd);
}

###############################################################################
#
#	Function:	_dequote_args
#
#	Turns a string of possibly-quoted arguments into a list.
#	Stops processing if it encounters a literal introducer (e.g. "{42}").
#	Double quotes ('"') and backslashes ('\') escaped with leading
#	backslashes have the escape stripped.
#

sub _dequote_args
{
	my ($self) = shift;
	my ($listref, $sref) = @_;
	my ($line, @line);

# Remove literal introducer, if any

	if ($$sref =~ /\{[0-9]+\}.*/) {	# there's a literal
		$line = $`;
		$$sref = $&;	# leave the introducer and the literal there
	} else {
		$line = $$sref;
		$$sref = "";	# eat entire line
	}

# Play regexp games to be able to split out quoted strings, being careful not
# to be fooled by escaped quotes or escaped backslashes.  Take advantage of
# the fact that there are neither CR nor LF characters outside a literal.
# If this actually works, credit goes to <flynn@kodachi.com>.

	$line =~ s/\r//g;	# remove all CRs, just in case
	$line =~ s/\\/\r/g;	# hide all backslashes
	$line =~ s/\r\r/\\/g;	# reveal escaped backslashes
	$line =~ s/\r\"/\n/g;	# hide escaped quotes
	$line =~ s/\r/\\/g;	# reveal remaining backslashes
	$line =~ s/\n/\r/g;	# hide escaped quotes in a different way
	$line =~ s/\s*(\".*?\")\s*/\n$1\n/g;	# mark bounds of quoted words
	$line =~ s/\n\n/\n/g;	# fix abutting quoted words
	$line =~ s/^\n//;	# deal with quoted word first on the line
	$line =~ s/\n$//;	# deal with quoted word last on the line

# We can now split on \n and get a list of "words", where some of them
# are enclosed in quotes, and the rest can be further split on whitespace
# to make more words.

	@line = split(/\n/, $line);
	for (@line) {
		if ($_ =~ /^\"(.*)\"$/s) {	# quoted string
			my $word = $+;
			$word =~ s/\r/\"/g;	# reveal escaped quotes
			push(@$listref, $word);
		} else {	# bareword(s)
			my @word = split(/\s+/, $_);
			for (@word) {
				s/\r/\"/g;	# reveal escaped quotes
				push(@$listref, $_);
			}
		}
	}
}


###############################################################################
###############################################################################
#
# Compatibility (low-level) interface
#
# This low-level interface is provided for compatibility with an older
# instance of this module, for use with existing scripts.  Most new scripts
# should use the high-level interface.
#
###############################################################################
###############################################################################


###############################################################################
#
#	Function:	new(Hostname);
#
#	Usage:		$obj = Net::MirapointAdmin->new($hostname);
#	Returns:	object reference
#	Error:		calls die()
#
#	Creates an object for use by the other methods in the module.
#	Object type is the same as for the new() method in the high-level
#	interface, but mixing them is not supported.

# same as the new() function in the new interface, near the top of this file.

###############################################################################
#
#	Function:	connect;
#
#	Usage:		$obj->connect;
#	Returns:	$obj
#	Error:		raises exception, then returns undef
#
#	Creates a TCP connection to the hostname given in new()
#
sub connect
{
	my $self = shift;
	# $the == 1 if in new()
	my $the = shift || 0;

	$ERRSTR = "";				# Clean out the error
	return $self if $self->connected();	# Just in case...

	if ($self->{"ssl"} == 1) {
		$self->{"socket"} = IO::Socket::SSL->new(
			PeerAddr 	=> $self->hostname,
			PeerPort 	=> $self->portnumber,
			Proto    	=> 'tcp',
			SSL_use_cert	=> 0,
			SSL_verify_mode	=> 0x00);
		if (!defined $self->{"socket"})
		{
			$ERRSTR = "Cannot create SSL connection: $^E";
			if ($the) {
				return undef;
			} else {
				$self->error($ERRSTR);
				return $self->raise_exception();
			}
		}
	} else {
		$self->{"socket"} = IO::Socket::INET->new(
			PeerAddr => $self->hostname, 
			PeerPort => $self->portnumber,
			Proto    => 'tcp', 
			Timeout  => 20);
		if (!defined $self->{"socket"})
		{
			$ERRSTR = "Cannot create TCP connection: $^E";
			if ($the) {
				return undef;
			} else {
				$self->error($ERRSTR);
				return $self->raise_exception();
			}
		}
	}

	$self->socket->autoflush(1);
	$self->connected(1);
	$self->loggedin(0);
	$self->lasttag(1);

	#
	#  We need to fill in the information about the version of the
	#  Admind we are connecting to and the FQDN of the host.
	#
	my $l = $self->_getline;
	if (!defined $l)
	{
		$ERRSTR = "Cannot read handshake.";
		if ($the) {
			return undef;
		} else {
			$self->error($ERRSTR);
			return $self->raise_exception();
		}
	}
	if ($self->{"ignore_hand"} == 0) {
		if ($l !~ /\* OK ([^ ]+) admind ([0-9\.]+).*/)
		{
			$ERRSTR = "Bad handshake: $l";
			if ($the) {
				return undef;
			} else {
				$self->error($ERRSTR);
				return $self->raise_exception();
			}
		} else {

			$self->{'reported_hostname'} = $1;
			$self->{'version'} = $2;
			if ($self->version() =~ /(\d+)\.(\d+)\.(\d+)/) {
				my $mos_ver = $3;
				$mos_ver += $2 << 8;
				$mos_ver += $1 << 16;
				$self->mos_ver($mos_ver);
			} elsif ($self->version() =~ /(\d+)\.(\d+)/) {
				my $mos_ver += $2 << 8;
				$mos_ver += $1 << 16;
				$self->mos_ver($mos_ver);
			}
		}
	}

	return $self;
}


###############################################################################
#
#	Function:	xmit(String);
#
#	Usage:		$obj->xmit("tag LOGIN user pass");
#	Returns:	undef
#	Error:		calls die()
#
#	Writes the supplied string to the TCP connection, followed by CRLF.

sub xmit
{
	my $self = shift;
	my $cmd = shift;
	my $res;

	# Quickie error check --- socket must be defined, or this has
	# no meaning.
	return undef if ($self->connected() != 1);
	return undef unless ($self->{"socket"});

	$self->debuglog("C: $cmd") if ($self->{"debug"});
	$res = $self->{"socket"}->print("$cmd\r\n");
	if ($res < 1)
	{
		$self->error("Cannot write to channel: $^E");
		return $self->raise_exception();
	} 
	return bytes::length("$cmd\r\n");
}


###############################################################################
#
#	Function:	getbuf;
#
#	Usage:		$buf = $obj->getbuf;
#	Returns:	string
#	Error:		calls die()
#
#	Gets a line of text from the TCP connection.

sub getbuf
{
	my $self = shift;

	return $self->_getline;
}


##############################################################################
#
# Examples of use:
#
#    Lower-level interface: (with implicit exception handler)
#
#       $mp = Net::MirapointAdmin->new($host);
#       $mp->connect;
#       $mp->xmit("a00001 LOGIN user password");
#       $okno = $mp->getbuf;
#       if ($okno !~ /^a00001 OK/) { ... }
#       $mp->xmit("a00002 VERSION");
#       $version = $mp->getbuf;
#       if ($version !~ /^a00002 OK/) { ... }
#       $version =~ s/^.*OK //;
#       $mp->xmit("a00003 LOGOUT");
#       $okno = $mp->getbuf;
#       undef $mp;              -- Performs disconnect
#

###############################################################################
#
#	The End.  (And Lets Keep Perl Happy)
#
1;

__END__

=pod

=head1 NAME

Net::MirapointAdmin - Perl interface to the Mirapoint administration protocol

=head1 SYNOPSIS

=head2 High-Level Interface

 $obj = Net::MirapointAdmin->new(host=>$host, debug=>$debug, ssl=>$usessl)

 $obj->login($user, $password);

 $lasttag = $obj->send_command(qw/LICENSE STATUS/);

 $obj->get_response($lasttag);

 $obj->command(qw/USER LIST/, "", "", "");

 $obj->command_ok(qw/MAILBOX LIST/, "%", "", "");

 $obj->command_no(/Already exists/, qw/DL ADD/, $dl);

=head2 Low-Level Interface

 $obj = Net::MirapointAdmin->new($host)

 $obj->connect();

 $obj->xmit("tag LOGIN user pass")

 $buf = $obj->getbuf();

=head1 DESCRIPTION

Net::MirapointAdmin is a perl module that simplifies the task of writing
perl scripts to manage Mirapoint systems.  The API allows you to send
Mirapoint protocol commands that automate administration tasks across
the network.

Two interfaces are available: low-level and high-level.  The low-level
functions send and receive simple arguments.  The high-level functions
handle tag generation and stripping, quoted and literal arguments with
binding to Perl data types (in an array context), optional response
checking, and auto-logout before disconnect.  In general, using the
high-level interface is more convenient.

=head2 High-Level Interface

The new(host=>$host,args) function takes a list of arguments, and
uses these arguments to create a TCP/IP connection to the Mirapoint
server's administration protocol interface.  In the case of a failure,
$Net::MirapointAdmin::ERRSTR is set to the error message and undef 
is retruned. The arguments can include the following:

=over 8

=item port => $port

This option specifies a specific port.  It is not normally needed
since the default port is selected based on the protocol used.

=item exception => $exception_function_ptr

The default exception handler is a function that prints an error message
and dies.  This may not always be appropriate (for example, when used as
part of a CGI script).  This option allows you to replace the default
exception handler.

=item ssl => $ssl 

The value of $ssl is either 0 (the default) to use a cleartext connection,
or 1 to use an SSL connection.  The new() function returns undef if an SSL
connection is requested but not available.

=item debug => $debug 

The module prints out TCP trace information if $debug is 1
(by default, $debug is 0).

=back

Other Functions:

=over 4

=item login($user, $pass)

Login to the Mirapoint host with the specified username or password.  Return
undef if unable to comply (the okno() function gives the reason).

=item $tag = send_command(@cmd)

Sends a command to the Mirapoint unit - the return value is the value to be 
used as the argument to the get_response() function.

=item @response = get_response($tag)

Checks and strips the tag from the reponse.   The OK or NO response from
the Mirapoint host can be retrieved with the okno() function.  In a scalar
context, the return value is the first argument of the return value.
In an array context, the return value is an array of array-references.
The outer array is organized by line, and the inner-array by field.

=item @response = command(@cmd)

The command() function combines the send_command() and get_response()
functions, relieving the programmer of having to know about tags.

=item @response = command_ok(@cmd)

The command_ok() function is similar to the command() function, but
insists on an OK response from the server.  If the response was not an
OK response, it raises an exception.

=item @response = command_no($pattern, @cmd)

The command_no() function is similar to the command_ok() function, but
allows a NO response, providing that the NO response matches $pattern.  

=item hostname()

Returns the host to which we are currently connected.

=item reported_hostname()

Returns the hostname as reported by the Mirapoint system.

=item version()

Returns the version of the Mirapoint protocol running on the
connected Mirapoint host.

=item error()

Returns the last error generated by the module.

=item okno()

Returns the status of the last command executed.

=item connected()

Returns TRUE if the module is connected to a host, and FALSE otherwise.

=item loggedin()

Returns TRUE if the module has successfully logged in and is authenticated.

=item supports_ssl()

Returns 1 if the module supports SSL.  This is generally used in the following
manner:

	$ssl = Net::MirapointAdmin::supports_ssl();
	$mp = Net::MirapointAdmin->new(host => $host, ssl => $ssl);

=item mos_ver()

Returns the version of the Mirapoint protocol running on the
connected Mirapoint host encoded into a hexadecimal number.

=back

=head2 Low-Level Interface

In order to support more complex situations, a lower level interface
is provided.  This includes the following functions:

=over 4

=item C<new($host, $port)>

Connect to the specified host on the specified port.  Note that an
SSL connection is not possible using the low level interface.

=item C<connect()>

Unlike the high-level interface, the low-level interface does not
automatically connect to the remote host.  C<connect()> actually
initiates the connection, and raises an exception on failure.

=item C<xmit($cmd)>

Send the $cmd string directly to the server.  The $cmd string should
already have a tag in front of it.  Returns the number of bytes sent
on success, or undef on failure.

=item C<$cmd = getbuf()>

Obtain one line from the Mirapoint host.  Note that no dequoting of
the resulting line is done, and the return value may not contain the
full output of the command executed with the xmit() function.  Returns
undef on error (such as an invalid connection)

=back

=head1 EXAMPLES

=over 4

=item Login:

	$mp = Net::MirapointAdmin->new(host => $host,
				   ssl => $ssl,
				   debug => $debug);
	$mp->login($user, $password);

=item High-level command:

	$user = "bob"; $password = "pwd"; $fullname = "Bob Smith";
	$mp->command_ok(qw/USER ADD/, $user, $password, $fullname);
	    results in:
	C: tag USER ADD bob pwd "Bob Smith"
	S: tag OK

=item High-level command and response:

	$pattern = ""; $start = "", $count = "";
	@users = $mp->command_ok(qw/USER LIST/, $pattern, $start, $count);
	@usernames = map { $_ = $$_[0] } @users;
	    results in:
	C: tag USER LIST "" "" ""
	S: * tag "bob" "Bob Smith"
	S: * tag "joe" "Joe Brown"
	S: tag OK
	@users = ( [ "bob", "Bob Smith" ], [ "joe", "Joe Brown" ] )
	@usernames = ("bob", "joe");

=item With error checking (OK, or NO followed by pattern):

       $mp->command_no("Already exists", qw/DL ADD/, $dl);

=item Manual error checking:

	@response = $mp->command(qw/DLENTRY LIST/, $dl, "", "", "");
	if ($mp->okno =~ /^NO/) {
		...
	}

=item Low-level routine:

	$mp->send_command(qw/EVENT WATCH Login/);
	while ($mp->connected()) {
		print $mp->getbuf();	# Get the next line
	}

=item Logout:

       undef $mp;              [Performs logout and disconnect]

=back

=head1 SEE ALSO

	The Mirapoint Protocol Reference Manual
	http://support.mirapoint.com/

=cut

