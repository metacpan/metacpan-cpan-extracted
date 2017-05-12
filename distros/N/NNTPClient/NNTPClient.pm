package News::NNTPClient;

require 5.002;

use Carp;
use Socket qw(1.5 inet_aton pack_sockaddr_in PF_INET SOCK_STREAM AF_INET);

use strict qw(vars subs);
use vars qw($VERSION $fhcnt);

$fhcnt = 0;			# File handle counter, to insure unique socket.
$VERSION = (qw$Revision: 0.37 $)[1];

# Create a new NNTP object.  Set up defaults for host and port, and
# attempt connection.  For host, if not supplied, check the
# environment variable NNTPSERVER.  If that isn't set, then hostname
# is "news".  For port, check the environment variable NNTPPORT, or
# use "nntp" service or 119.
sub new {
    my $name = shift;
    my $host = shift || $ENV{NNTPSERVER} || "news";
    my $port = shift || $ENV{NNTPPORT} || getservbyname("nntp","tcp") || 119;
    my $debug = shift;

    my $me = bless {
	DBUG => defined ($debug) ? $debug : 1,
	SOCK => $name . "::SOCK" . ++$fhcnt,
	HOST => $host,
	PORT => $port,
	ADDR => "",
	MESG => "",
	CODE => 0,
	POST => undef,
	EOL  => "\n",		# End Of Line
	GMT  => 0,		# Greenwich Mean Time
        FDY  => 0,		# Four Digit Year
    }, $name;

    $me->initialize();

    $me;
}

sub initialize {
    my $me = shift;
  
    $me->port($me->{PORT}) and
    $me->host($me->{HOST}) and
    $me->connect           and
    $me->response;
}

# Determine port number.  If we were passed a non-numeric port,
# attempt to look it up.
sub port {
    my $me = shift;
    my $port = shift or return $me->{PORT};

    unless ($port =~ /^\d+$/) {
	my $tmp = getservbyname ($port, "tcp") or
	    carp "News::NNTPClient: Bad port: $port" and return;
	$port = $tmp;
    }

    $me->{PORT} = $port;
}

# Resolve hostname.
sub host {
    my $me = shift;
    my $host = shift or return $me->{HOST};
    my $addr;

    # Get address.
    $addr = inet_aton($host) or
      carp "News::NNTPClient: Bad hostname: $host" and return;

    $me->{ADDR} = $addr;

    # Get fully qualified domain name if possible
    $me->{HOST} = gethostbyaddr ($addr, AF_INET) || $host;
}

# Connect to server.
sub connect {
    my $me = shift;

    my $SOCK = $me->{SOCK};

    if (defined fileno $SOCK) {
	1 < $me->{DBUG} and
	    warn "$SOCK already connected, closing\n";
	close $SOCK;
    }

    1 < $me->{DBUG} and
	warn "$SOCK connecting to $me->{HOST}:$me->{PORT}\n";

    socket ($SOCK, PF_INET, SOCK_STREAM, getprotobyname("tcp") || 6) or
	carp "News::NNTPClient: Can't open socket: $!" and return;

    unless (connect($SOCK, pack_sockaddr_in($me->{PORT},$me->{ADDR}))) {
	carp "News::NNTPClient: Can't connect socket: $!";
	close $SOCK;
	return;
    }

    select ((select($SOCK), $|=1)[0]); # Turn on autoflush.

    1;
}

########################################################################
# Helper methods.  These methods may be called to return saved
# information about the NNTP connection, information about the
# package, or to set EOL and debug,
########################################################################


# Return version number.
sub version {
    my $me = shift;

    # Get News::NNTPClient::version, if package happens to be
    # News::NNTPClient.
    my $rev = ${ref($me) . "::VERSION"};

    $rev;
}

# With no argument, return debugging level, otherwise set it.
sub debug {
    my $me = shift;
    my $debug = shift;

    $me->{DBUG} = $debug if defined $debug;

    $me->{DBUG};
}

# Set EOL
sub eol {
    my $me = shift;
    my $new = shift;
    my $old = $me->{EOL};

    # Set to new EOL only if passed a value.
    $me->{EOL} = $new if defined $new;

    $old;
}

# Set GMT
sub gmt {
    my $me = shift;
    my $new = shift;
    my $old = $me->{GMT};

    # Set to new GMT only if passed a value.
    $me->{GMT} = $new if defined $new;

    $old;
}

# Set Four digit year flag.
sub fourdigityear {
    my $me = shift;
    my $new = shift;
    my $old = $me->{FDY};

    # Set to new FDY only if passed a value.
    $me->{FDY} = $new if defined $new;

    $old;
}

# Return boolean according to code < 400.
sub ok {
    my $me = shift;

    # Codes less than 400 are good.
    0 < $me->{CODE} and $me->{CODE} < 400;
}

# Return boolean according to code < 400 and print message if not ok.
sub okprint {
    my $me = shift;

    warn "NNTPERROR: $me->{CODE} $me->{MESG}\n"
	if 400 <= $me->{CODE} and $me->{DBUG};

    # Codes less than 400 are good.
    0 < $me->{CODE} and $me->{CODE} < 400;
}

# Return the most recent message
sub message {
    my $me = shift;

    "$me->{MESG}$me->{EOL}";
}

# Return the most recent code
sub code {
    my $me = shift;

    $me->{CODE};
}

# Return boolean according to post ok flag.
sub postok {
    my $me = shift;

    $me->{POST};
}

########################################################################
# NNTP methods.
########################################################################

# Fetch an article.
sub article {
    my $me = shift;
    my $msgid = shift || "";

    $me->{CMND} = "fetch";
    $me->command("ARTICLE $msgid");
}

# Fetch body of an article.
sub body {
    my $me = shift;
    my $msgid = shift || "";

    $me->{CMND} = "fetch";
    $me->command("BODY $msgid");
}

# Fetch header of an article.
sub head {
    my $me = shift;
    my $msgid = shift || "";

    $me->{CMND} = "fetch";
    $me->command("HEAD $msgid");
}

# Fetch status of an article.  Return Message-ID if found.
sub stat {
    my $me = shift;
    my $msgid = shift || "";

    $me->{CMND} = "msgid";
    $me->command("STAT $msgid");
}

# Move current article pointer backwards.  Return Message-ID if found.
sub last {
    my $me = shift;

    $me->{CMND} = "msgid";
    $me->command("LAST");
}

# Move current article pointer forwards.  Return Message-ID if found.
sub next {
    my $me = shift;

    $me->{CMND} = "msgid";
    $me->command("NEXT");
}

# Set the group.
sub group {
    my $me = shift;
    my $group = shift || "";

    $me->{CMND} = "groupinfo";
    $me->command("GROUP $group");
}

# List all groups.
sub list {
    my $me   = shift;
    my $type = shift || "";
    my $pat  = shift || "";

    $me->{CMND} = "fetch";
    $me->command("LIST $type $pat");
}

# List new groups since date/time.
sub newgroups {
    my $me = shift;
    my $since = $me->yymmdd_hhmmss(shift);

    my $dist = distributions(@_);

    $me->{CMND} = "fetch";
    $me->command("NEWGROUPS $since $dist");
}

# List new news since date/time.  If first argument is a timestamp
# instead of a group, use default group.  Otherwise use second
# argument for time stamp.  Default group is set by the group method,
# or is all groups (*) if not set.
sub newnews {
    my $me = shift;
    my $group = shift;
    my $since;

    if ($group) {
	if ($group =~ /^[\d ]+/) {
	    $since = $group;
	    $group = "";
	} else {
	    $since = shift;
	}
    }

    $group ||= $me->{GROUP} || "*";
    $since = $me->yymmdd_hhmmss($since);

    my $dist = distributions(@_);

    $me->{CMND} = "fetch";
    $me->command("NEWNEWS $group $since $dist");
}

# Get help text.
sub help {
    my $me = shift;

    $me->{CMND} = "fetch";
    $me->command("HELP");
}

# Post an article.
sub post {
    my $me = shift;

    $me->command("POST") or return;

    $me->squirt(@_);
}

# Transfer an article.
sub ihave {
    my $me = shift;
    my $msgid = shift || "";

    $me->command("IHAVE $msgid") or return;

    $me->squirt(@_);
}

# Authinfo command
sub authinfo {
    my $me = shift;
    my $user = shift || "guest";
    my $pass = shift || "foobar";

    $me->command("AUTHINFO USER $user") && $me->command("AUTHINFO PASS $pass");
}

# Turn on slave mode, whatever that means.
sub slave {
    my $me = shift;

    $me->command("SLAVE");
}

# All done.
sub quit {
    my $me = shift;

    return unless defined fileno $me->{SOCK};

    my $ret = $me->command("QUIT");

    close $me->{SOCK};

    $ret;
}

sub DESTROY {
    my $me = shift;

    $me->quit;
}

########################################################################
# Extended NNTP methods.  Not all of these are implemented on all
# servers.
########################################################################

# Mode reader command.
sub mode_reader {
    my $me = shift;

    $me->command("MODE READER");
}

# Returns date
sub date {
    my $me = shift;

    $me->{CMND} = "msg";
    $me->command("DATE");
}

# Return list of article numbers in group.
sub listgroup {
    my $me = shift;
    my $group = shift || "";

    $me->{CMND} = "fetch";
    $me->command("LISTGROUP $group");
}

# Get message of the day.
sub xmotd {
    my $me = shift;
    my $since = $me->yymmdd_hhmmss(shift);

    $me->{CMND} = "fetch";
    $me->command("XMOTD $since");
}

# Return titles for newsgroups matching pattern.
sub xgtitle {
    my $me = shift;
    my $group_pattern = shift || "";

    $me->{CMND} = "fetch";
    $me->command("XGTITLE $group_pattern");
}

# Return path name for article?
sub xpath {
    my $me = shift;
    my $msgid = shift || "";

    $me->{CMND} = "msg";
    $me->command("XPATH $msgid");
}

# Fetch a header for a range of articles.  If ARG1 is numeric, use it
# as first entry of article range and use Message-ID as the header.
# Otherwise ARG1 is header, and ARG2 is first entry of article range.
sub xhdr {
    my $me = shift;
    my $header = shift || "message-id";
    my $list = shift || 1;
    my $last = shift;

    $list = "$list-$last" if $last;

    $me->{CMND} = "fetch";
    $me->command("XHDR $header $list");
}

sub xpat {
    my $me = shift;
    my $header = shift || "subject";
    my $list = shift || 1;
    my $last = shift;
    my $patterns = "";
    
    if ($last) {
	if ($last =~ /^\d+$/) {
	    $list = "$list-$last";
	} else {
	    $patterns = $last;
	}
    }

    $patterns .= @_ ? " @_" : "";

    $patterns = "*" unless $patterns;

    $me->{CMND} = "fetch";
    $me->command("XPAT $header $list $patterns");
}

# Fetch overview for range of articles.
sub xover {
    my $me = shift;
    my $list = shift || 1;
    my $last = shift;

    $list = "$list-$last" if $last;

    $me->{CMND} = "fetch";
    $me->command("XOVER $list");
}

# Fetch thread file.
sub xthread {
    my $me = shift;
    my $file = @_ ? "dbinit" : "thread";

    $me->{CMND} = "fetchbinary";
    $me->command("XTHREAD $file");
}

# Fetch index
sub xindex {
    my $me = shift;
    my $group = shift || $me->{GROUP} || "";

    $me->{CMND} = "fetch";
    $me->command("XINDEX $group");
}

# Search???  Expects search criteria, format unknown.
sub xsearch {
    my $me = shift;

    $me->command("XSEARCH") or return;

    $me->squirt(@_);
}

########################################################################
# Subroutines to implement basic methods.
########################################################################

# Send a command.
sub cmd {
    my ($me, $cmd) = @_;
    local $\ = "\015\012";

    my $SOCK = $me->{SOCK};

    1 < $me->{DBUG} and warn "$SOCK command: $cmd\n";

    defined fileno $SOCK or
	carp "News::NNTPClient: $SOCK has been closed\n" and return;

    print $SOCK $cmd;
}

# Send a command and retrieve status.  The only reason for not doing
# all the work in cmd is so this method can be replaced in a subclass,
# and the subclass can call cmd to do the real work.
sub command {
    my $me = shift;

    $me->cmd(@_) or return;

    $me->response();
}

# Like message, but with okprint
sub msg {
    my $me = shift;

    $me->okprint() or return;

    $me->{MESG};
}

# Extract Group info from MESG.
sub groupinfo {
    my $me = shift;

    $me->{GROUP} = "";

    # est-articles first-article last-article group-name
    if ($me->okprint and $me->{MESG} =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\w+)/) {
	$me->{GROUP} = $4;
	return wantarray ? ($2, $3) : "$2-$3";
    }

    return;
}

# Extract Message-ID from MESG.
sub msgid {
    my $me = shift;

    $me->okprint() and $me->{MESG} =~ /(<[^>]+>)/ ? $1 : "";
}

# Fetch text from server until single dot.
sub fetch {
    my $me = shift;
    local $/ = "\012";         # Only use LF to account for possible missing CR
    local $_;

    return unless $me->okprint();

    my @lines;

    my $SOCK = $me->{SOCK};

    # Loop reading lines until we receive a line with a single period.
    while (<$SOCK>) {
	s/\015?\012$/$me->{EOL}/; # Change termination

	last if $_ eq ".$me->{EOL}";

	s/^\.\././;		# Fix up escaped dots.
	push @lines, $_;	# Save each line.
    }

    1 < $me->{DBUG} and	warn "$SOCK received ${\scalar @lines} lines\n";

    wantarray ? @lines : \@lines;
}

# Fetch binary data from server, terminated by: \r\n.\r\n   Used by xthread
sub fetchbinary {
    my $me = shift;
    local $/ = "\015\012.\015\012";
    local $_;

    return unless $me->okprint();

    my $SOCK = $me->{SOCK};

    my $data = <$SOCK>;

    chomp $data;

    1 < $me->{DBUG} and	warn "$SOCK received ${\length $data} bytes\n";

    $data;
}

# Figure out what we should return to sender
sub returnval {
    my $me = shift;

    my $command = $me->{CMND} || "okprint";

    $me->{CMND} = "";		# reset after use.

    $me->$command();
}

# Read response to some action (connect, command or squirt)
sub response {
    my $me = shift;
    local $/ = "\012";         # Only use LF to account for possible missing CR
    local $_;
    
    my $SOCK = $me->{SOCK};

    $_ = <$SOCK>;

    $me->{CODE} = 0;
    $me->{MESG} = "";

    defined ($_) or
	carp "News::NNTPClient unexpected EOF on $SOCK\n" and return;

    s/\015?\012$//;		# Remove termination

    if (/^((\d\d)(\d))\s*(.*)/) { # Split out numeric code and message.
	$me->{POST} = !$3 if $2 == 20;
	$me->{CODE} = $1;
	$me->{MESG} = $4;
    } else {
	warn "News::NNTPClient garbled response: $_\n";
	return;
    }

    1 < $me->{DBUG} and	warn "$SOCK result($me->{CODE}): $me->{MESG}\n";

    $me->returnval();
}

sub squirt {
    my $me = shift;
    local $\ = "\015\012";

    my $SOCK = $me->{SOCK};

    1 < $me->{DBUG} and warn "$SOCK sending ${\scalar @_} lines\n";

    foreach (@_) {
	local ($_) = $_;
	# Print each line, possibly prepending a dot for lines
	# starting with a dot and trimming any trailing \n.
	s/^\./../;
	s/\n$//;
	print $SOCK $_;
    }

    print $SOCK ".";	# Terminate message.

    1 < $me->{DBUG} and warn "$SOCK done sending\n";

    $me->response();
}

# Return time in YYYYMMDD HHMMSS format, for use with newnews and
# newgroups commands.  If passed a string already in that format, just
# return it.  Otherwise use localtime() to convert seconds to
# date/time.  Default is current time.
sub yymmdd_hhmmss {
    my $me = shift;
    my $time = shift || time();

    # Already in the correct format?
    return $time if $time =~ /^\d{8}\s+\d{6}(\s*GMT)?$/;

    # Check for old format.
    if ($time =~ /^\d{6}\s+\d{6}(\s*GMT)?$/) {
      carp "Short year in date, using anyway\n" if $me->{FDY};
      return $time;
    }

    # returns Seconds, Minutes, Hours, days, months - 1, years.
    my @t = ($me->{GMT} ? gmtime($time) : localtime($time))[0..5];

    $t[4]++;			# Fix up month
    if ($me->{FDY}) {	
      $t[5] += 1900;		# Fix up year for 4 digit year.
    } else {			
      $t[5] %= 100;		# Fix up year for 2 digit year.
    }
    my $fmt = "%.02d" x 3;
    sprintf "$fmt $fmt%s", reverse(@t), $me->{GMT} ? " GMT" : "";
}

# Convert list of newsgroup prefixes to distribution list.  For
# example: comp news -> "<comp,news>".  Returns null string if passed
# an empty list.
sub distributions {
    @_ and "<" . join(",", @_) . ">" or "";
}

1;

__END__

=head1 NAME

News::NNTPClient - Perl 5 module to talk to NNTP (RFC977) server

=head1 SYNOPSIS

    use News::NNTPClient;

    $c = new News::NNTPClient;
    $c = new News::NNTPClient($server);
    $c = new News::NNTPClient($server, $port);
    $c = new News::NNTPClient($server, $port, $debug);

=head1 DESCRIPTION

This module implements a client interface to NNTP, enabling a Perl 5
application to talk to NNTP servers.  It uses the OOP (Object Oriented
Programming) interface introduced with Perl 5.

NNTPClient exports nothing.

A new NNTPClient object must be created with the I<new> method.  Once
this has been done, all NNTP commands are accessed through this object.

Here are a couple of short examples.  The first prints all articles in
the "test" newsgroup:

  #!/usr/local/bin/perl -w
 
  use News::NNTPClient;
 
  $c = new News::NNTPClient;
 
  ($first, $last) = ($c->group("test"));
 
  for (; $first <= $last; $first++) {
      print $c->article($first);
  }
 
  __END__

This example prints the body of all articles in the "test" newsgroup
newer than one hour:

  #!/usr/local/bin/perl -w
 
  require News::NNTPClient;
 
  $c = new News::NNTPClient;
 
  foreach ($c->newnews("test", time - 3600)) {
      print $c->body($_);
  }
 
  __END__

=head2 NNTPClient Commands

These commands are used to manipulate the NNTPClient object, and
aren't directly related to commands available on any NNTP server.

=over 10

=item I<new>

Use this to create a new NNTP connection. It takes three arguments, a
hostname, a port and a debug flag.  It calls I<initialize>.  Use an
empty argument to specify defaults.

If port is omitted or blank (""), looks for environment variable
NNTPPORT, service "nntp", or uses 119.

If host is omitted or empty (""), looks for environment variable
NNTPSERVER or uses "news".

Examples:

  $c = new News::NNTPClient;
or
  $c = new News::NNTPClient("newsserver.some.where");
or
  $c = new News::NNTPClient("experimental", 9999);
or
  # Specify debug but use defaults.
  $c = new News::NNTPClient("", "", 2);

Returns a blessed reference, representing a new NNTP connection.

=item I<initialize>

Calls I<port>, I<host>, I<connect>, and I<response>, in that order.
If any of these fail, initialization is aborted.

=item I<connect>

Connects to current host/port.
Not normally needed, as the I<new> method does this for you.
Closes any existing connection.
Sets the posting status.  See the I<postok> method.

=item I<host>

Sets the host that will be used on the next connect.
Not normally needed, as the I<new> method does this for you.

Without an argument, returns current host.

Argument can be hostname or dotted quad, for example, "15.2.174.218".

Returns fully qualified host name.

=item I<port>

Sets the port that will be used on the next connect.
Not normally needed, as the I<new> method does this for you.

Without an argument, returns current port.

Argument can be port number or name.  If it is a name, it must be a
valid service.

Returns port number.

=item I<debug>

Sets the debug level.

Without an argument, returns current debug level.

There are currently three debug levels.  Level 0, level 1, and level
2.

At level 0 the messages described for level 1 are not produced.  Debug
level 0 is a way of turning off messages produced by the default debug
level 1.  Serious error messages, such as EOF (End Of File) on the
file handle, are still produced.

At level 1, any NNTP command that results in a result code of 400 or
greater prints a warning message.  This is the default.

At level 2, in addition to level 1 messages, status messages are
printed to indicate actions taking place.

Returns old debug value.

=item I<ok>

Returns boolean status of most recent command.  NNTP return codes less
than 400 are considered OK.  Not often needed as most commands return
false upon failure anyway.

=item I<okprint>

Returns boolean status of most recent command.  NNTP return codes less
than 400 are considered OK.  Prints an error message for return codes
of 400 or greater unless debug level is set to zero (0).

This method is used internally by most commands, and could be
considered to be "for internal use only".  You should use the return
status of commands directly to determine pass-fail, or if needed the
I<ok> method can be used to check status later.

=item I<message>

Returns the NNTP response message of the most recent command.

Example, as returned by NNTP server version 1.5.11t:

  $c->slave;
  print $c->message;

  Kinky, kinky.  I don't support such perversions.

=item I<code>

Returns the NNTP response code of the most recent command.

Example:

  $c->article(1);
  print $c->code, "\n";

  412

=item I<postok>

Returns the post-ability status that was reported upon connection or
after the mode_reader command.

=item I<eol>

Sets the End-Of-Line termination for text returned from the server.

Returns the old EOL value.

Default is \n.

To set EOL to nothing, pass it the empty string.

To query current EOL without setting it, call with no arguments.

Example:

  $old_eol = $c->eol();     # Get original.
  $c->eol("");              # Set EOL to nothing.
  @article = $c->article(); # Fetch an article.
  $c->eol($old_eol);        # Restore value.

=item I<gmt>

Sets GMT mode.  Returns old value.  To query GMT mode without setting
it, call with no arguments.

A true value means that GMT mode is used in the I<newgroups> and
I<newnews> functions.  A false value means that local time is used.

=item I<fourdigityear>

Sets four digit year mode.  Returns old value.  To query four digit
year mode without setting it, call with no arguments.

A true value means that four digit years are used in the I<newgroups>
and I<newnews> functions.  A false value means that an RFC977
compliant two digit year is used.

This function is available for news servers that implemented four
digit years rather than deal with non-y2k compliment two digit years.
RFC977 does not allow four digit years, and instead chooses the
century closest.  I quote:

    The closest century is assumed as part of the year (i.e., 86
    specifies 1986, 30 specifies 2030, 99 is 1999, 00 is 2000).

=item I<version>

Returns version number.

This document represents @(#) $Revision: 0.37 $.

=back

=head2 NNTP Commands

These commands directly correlate to NNTP server commands.  They
return a false value upon failure, true upon success.  The truth value
is usually some bit of useful information.  For example, the I<stat>
command returns Message-ID if it is successful.

Some commands return multiple lines.  These lines are returned as an
array in array context, and as a reference to an array in scalar
context.  For example, if you do this:

  @lines = $c->article(14);

then @lines will contain the article, one line per array element.
However, if you do this:

  $lines = $c->article(14);

then $lines will contain a I<reference> to an array.  This feature is
for those that don't like passing arrays from routine to routine.

=over 10

=item I<mode_reader>

Some servers require this command to process NNTP client commands.
Sets postok status.  See I<postok>.

Returns OK status.

=item I<article>

Retrieves an article from the server.  This is the main command for
fetching articles.  Expects a single argument, an article number or
Message-ID.  If you use an article number, you must be in a news
group.  See I<group>.

Returns the header, a separating blank line, and the body of the
article as an array of lines terminated by the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

Examples:

  print $c->article('<art1234@soom.oom>');

  $c->group("test");

  print $c->article(99);

=item I<body>

Expects a single argument, an article number or Message-ID.

Returns the body of an article as an array of lines terminated by the
current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

See I<article>.

=item I<head>

Expects a single argument, an article number or Message-ID.

Returns the head of the article as an array of lines terminated by the
current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

See I<article>.

=item I<stat>

Expects a single argument, an article number or Message-ID.

The STAT command is like the ARTICLE command except that it does not
return any text.  It can be used to set the "current article pointer"
if passed an article number, or to validate a Message-ID if passed a
Message-ID.

Returns Message-ID if successful, otherwise returns false.

=item I<last>

The "current article pointer" maintained by the server is moved to the
previous article in the current news group.

Returns Message-ID if successful, otherwise returns false.

=item I<next>

The "current article pointer" maintained by the server is moved to the
next article in the current news group.

Returns Message-ID if successful, otherwise returns false.

=item I<group>

Expects a single argument, the name of a valid news group. 

This command sets the current news group as maintained by the server.
It also sets the server maintained "current article pointer" to the
first article in the group.  This enables the use of certain other
server commands, such as I<article>, I<head>, I<body>, I<stat>,
I<last>, and I<next>.  Also sets the current group in the NNTPClient
object, which is used by the I<newnews> and I<xindex> commands.

Returns (first, last) in list context, or "first-last" in scalar
context, where first and last are the first and last article numbers
as reported by the group command.  Returns false if there is an error.

It is an error to attempt to select a non-existent news group.

If the estimated article count is needed, it can be extracted from the
message.  See I<message>.

=item I<list>

Accepts two optional arguments.  The first can be used indicate the
type of list desired.  List type depends on server.  The second is a
pattern that is use by some list types.

Examples:

  print $c->list();
  print $c->list('active');
  print $c->list('active', 'local.*');
  print $c->list('newsgroups');

With an argument of "active" or with no arguments, this command
returns a list of valid newsgroups and associated information.  The
format is:

  group last first p

where group is the news group name, last is the article number of the
last article, first is the article number of the first article, and p
is flag indicating if posting is allowed.  A 'y' flag is an indication
that posting is allowed.

Other possible arguments are: newsgroups, distributions, subscriptions
for B-News, and active.times, distributions, distrib.pats, newsgroups,
overview.fmt for INN.

Returns an array of lines terminated by the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

=item I<newgroups>

Expects at least one argument representing the date/time in seconds,
or in S<"YYYYMMDD HHMMSS [GMT]"> format.  The GMT part is optional.  If
you wish to use GMT with the seconds format, first call I<gmt>.
Remaining arguments are used as distributions.

Example, print all new groups in the "comp" and/or "news" hierarchy as
of one hour ago:

  print $c->newgroups(time() - 3600, "comp", "news");

Returns list of new news group names as an array of lines terminated
by the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

=item I<newnews>

Expects one, two, or more arguments.

If the first argument is a group name, it looks for new news in that
group, and the date/time is the second argument.  If the first
argument represents the date/time in seconds or in "YYYYMMDD HHMMSS
[GMT]" format, then the group is is last group set via the I<group>
command. If no I<group> command has been issued then the group is "*",
representing all groups.  If you wish to use GMT in seconds format for
the time, first call I<gmt>.  Remaining arguments are use to restrict
search to certain distribution(s).

Returns a list of Message-IDs of articles that have been posted or
received since the specified time.

Examples:

  # Hour old news in news group "test".
  $c->newnews("test", time() - 3600);
or
  # Hour old in all groups.
  $c->newnews(time() - 3600);
or
  $c->newnews("*", time() - 3600);
or
  # Hour old news in news group "test".
  $c->group("test");
  $c->newnews(time() - 3600);

The group argument can include an asterisk "*" to specify a range news
groups.  It can also include multiple news groups, separated by a
comma ",".

Example:

  $c->newnews("comp.*.sources,alt.sources", time() - 3600);

An exclamation point "!" may be used to negate the selection of
certain groups.

Example:

  $c->newnews("*sources*,!*.d,!*.wanted", time() - 3600);

Any additional distribution arguments will be concatenated together
and send as a distribution list.  The distribution list will limit
articles to those that have a Distribution: header containing one of
the distributions passed.

Example:

  $c->newnews("*", time() - 3600, "local", "na");

Returns Message-IDs of new articles as an array of lines terminated by
the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

=item I<help>

Returns any server help information.  The format of the information is
highly dependent on the server, but usually contains a list of NNTP
commands recognized by the server.

Returns an array of lines terminated by the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

=item I<post>

Post an article.  Expects data to be posted as an array of lines.  Most
servers expect, at a minimum, Newsgroups and Subject headers.  Be sure
to separate the header from the body with a neck, er blank line.

Example:

  @header = ("Newsgroups: test", "Subject: test", "From: tester");
  @body   = ("This is the body of the article");

  $c->post(@header, "", @body);


There aren't really three arguments.  Perl folds all arguments into a
single list.  You could also do this:

  @article = ("Newsgroups: test", "Subject: test", "From: tester", "", "Body");
  $c->post(@article);

or even this:

  $c->post("Newsgroups: test", "Subject: test", "From: tester", "", "Body");

Any "\n" characters at the end of a line will be trimmed.

Returns status.

=item I<ihave>

Transfer an article.  Expects an article Message-ID and the article to
be sent as an array of lines.

Example:

  # Fetch article from server on $c
  @article = $c->article($artid);
  
  # Send to server on $d
  if ($d->ihave($artid, @article)) {
      print "Article transfered\n";
  } else {
      print "Article rejected: ", $d->message, "\n";
  }

=item I<slave>

Doesn't do anything on most servers.  Included for completeness.

=item I<DESTROY>

This method is called whenever the the object created by
News::NNTPClient::new is destroyed.  It calls I<quit> to close the
connection.

=item I<quit>

Send the NNTP quit command and close the connection.  The connection
can be then be re-opened with the connect method.  Quit will
automatically be called when the object is destroyed, so there is no
need to explicitly call I<quit> before exiting your program.

=back

=head2 Extended NNTP Commands

These commands also directly correlate NNTP server commands, but are
not mentioned in RFC977, and are not part of the standard.  However,
many servers implement them, so they are included as part of this
package for your convenience.  If a command is not recognized by a
server, the server usually returns code 500, command unrecognized.

=over 10

=item I<authinfo>

Expects two arguments, user and password.

=item I<date>

Returns server date in "YYYYMMDDhhmmss" format.

=item I<listgroup>

Expects one argument, a group name.  Default is current group.

Returns article numbers as an array of lines terminated by the current
EOL.

In scalar context a reference to the array is returned instead of the
array itself.

=item I<xmotd>

Expects one argument of unix time in seconds or as a string in the
form "YYYYMMDD HHMMSS".

Returns the news servers "Message Of The Day" as an array of lines
terminated by the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

For example, the following will always print the message of the day,
if there is any:

  print $c->xmotd(1);
  NNTP Server News2

  News administrator is Joseph Blough <joeblo@news.foo.com>

=item I<xgtitle>

Expects one argument of a group pattern.  Default is current group.

Returns group titles an array of lines terminated by the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

Example:

  print $c->xgtitle("bit.listserv.v*");

  bit.listserv.valert-l   Virus Alert List. (Moderated)
  bit.listserv.vfort-l    VS-Fortran Discussion List.
  bit.listserv.vm-util    VM Utilities Discussion List.
  bit.listserv.vmesa-l    VM/ESA Mailing List.
  bit.listserv.vmslsv-l   VAX/VMS LISTSERV Discussion List.
  bit.listserv.vmxa-l     VM/XA Discussion List.
  bit.listserv.vnews-l    VNEWS Discussion List.
  bit.listserv.vpiej-l    Electronic Publishing Discussion

=item I<xpath>

Expects one argument of an article Message-ID.  Returns the path name
of the file on the server.

Example:

  print print $c->xpath(q(<43bq5l$7b5@news.dtc.hp.com>))'
  hp/test/4469

=item I<xhdr>

Fetch header for a range of articles.  First argument is name of
header to fetch.  If omitted or blank, default to Message-ID.  Second
argument is start of article range.  If omitted, defaults to 1.  Third
argument is end of range.  If omitted, defaults to "".  The second
argument can also be a Message-ID.

Returns headers as an array of lines terminated by the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

Examples:

  # Fetch Message-ID of article 1.
  $c->xhdr();

  # Fetch Subject of article 1.
  $c->xhdr("Subject");

  # Fetch Subject of article 3345.
  $c->xhdr("Subject", 3345);

  # Fetch Subjects of articles 3345-9873
  $c->xhdr("Subject", 3345, 9873);

  # Fetch Message-ID of articles 3345-9873
  $c->xhdr("", 3345,9873);

  # Fetch Subject for article with Message-ID
  $c->xhdr("Subject", '<797t0g$25f10@foo.com>');

=item I<xpat>

Fetch header for a range of articles matching one or more patterns.
First argument is name of header to fetch.  If omitted or blank,
default to Subject.  Second argument is start of article range.  If
omitted, defaults to 1.  Next argument is end of range.  Remaining
arguments are patterns to match.  Some servers use "*" for wildcard.

Returns headers as an array of lines terminated by the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

Examples:

  # Fetch Subject header of article 1.
  $c->xpat();

  # Fetch "From" header of article 1.
  $c->xpat("From");

  # Fetch "From" of article 3345.
  $c->xpat("From", 3345);

  # Fetch "From" of articles 3345-9873 matching *foo*
  $c->xpat("From", 3345, 9873, "*foo*");

  # Fetch "Subject" of articles 3345-9873 matching
  # *foo*, *bar*, *and*, *stuff*
  $c->xpat("", 3345,9873, qw(*foo* *bar* *and* *stuff*));

=item I<xover>

Expects an article number or a starting and ending article number
representing a range of articles.

Returns overview information for each article as an array of lines
terminated by the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

Xover generally returns items separated by tabs.  Here is an example
that prints out the xover fields from all messages in the "test" news
group.

  #!/usr/local/bin/perl

  require News::NNTPClient;

  $c = new News::NNTPClient;

  @fields = qw(numb subj from date mesg refr char line xref);

  foreach $xover ($c->xover($c->group("test"))) {
      %fields = ();
      @fields{@fields} = split /\t/, $xover;
      print map { "$_: $fields{$_}\n" } @fields;
      print "\n";
  }

  __END__
				# 
=item I<xthread>

Expects zero or one argument.  Value of argument doesn't matter.  If
present, I<dbinit> command is sent.  If absent, I<thread> command is
sent.

Returns binary data as a scalar value.

Format of data returned is unknown at this time.

=item I<xindex>

Expects one argument, a group name.  If omitted, defaults to the group
set by last I<group> command.  If there hasn't been a group command,
it returns an error;

Returns index information for group as an array of lines terminated by
the current EOL.

In scalar context a reference to the array is returned instead of the
array itself.

=item I<xsearch>

Expects a query as an array of lines which are sent to the server,
much like post.  Returns the result of the search as an array of lines
or a reference to same.

Format of query is unknown at this time.

=back

=head1 AUTHOR

Rodger Anderson  <rodger@boi.hp.com>

=head1 COPYRIGHT

Copyright 1995 Rodger Anderson. All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
