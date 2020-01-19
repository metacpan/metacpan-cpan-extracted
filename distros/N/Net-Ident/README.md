[![](https://github.com/toddr/Net-Ident/workflows/linux/badge.svg)](https://github.com/toddr/Net-Ident/actions) [![](https://github.com/toddr/Net-Ident/workflows/macos/badge.svg)](https://github.com/toddr/Net-Ident/actions) [![](https://github.com/toddr/Net-Ident/workflows/windows/badge.svg)](https://github.com/toddr/Net-Ident/actions)

# NAME

Net::Ident - lookup the username on the remote end of a TCP/IP connection

# SYNOPSIS

    use Net::Ident;
    
    $username = Net::Ident::lookup(SOCKET, $timeout);

    $username = Net::Ident::lookupFromInAddr($localsockaddr,
                                              $remotesockaddr, $timeout);
    
    $obj = Net::Ident->new(SOCKET, $timeout);
    $obj = Net::Ident->newFromInAddr($localsockaddr, $remotesockaddr,
                                           $timeout);
    $status = $obj->query;
    $status = $obj->ready;
    $username = $obj->username;
    ($username, $opsys, $error) = $obj->username;
    $fh = $obj->getfh;
    $txt = $obj->geterror;
    
    use Net::Ident 'ident_lookup';
    
    $username = ident_lookup(SOCKET, $timeout);

    use Net::Ident 'lookupFromInAddr';

    $username = lookupFromInAddr($localsockaddr, $remotesockaddr, $timeout);

    use Net::Ident ':fh';

    $username = SOCKET->ident_lookup($timeout);

    use Net::Ident ':apache';

    # my Apache $r;
    $c = $r->connection;
    $username = $c->ident_lookup($timeout);

# OVERVIEW

**Net::Ident** is a module that looks up the username on the remote
side of a TCP/IP connection through the ident (auth/tap) protocol
described in RFC1413 (which supersedes RFC931). Note that this
requires the remote site to run a daemon (often called **identd**) to
provide the requested information, so it is not always available for
all TCP/IP connections.

# DESCRIPTION

You can either use the simple interface, which does one ident
lookup at a time, or use the asynchronous interface to perform
(possibly) many simultaneous lookups, or simply continue serving other
things while the lookup is proceeding.

## Simple Interface

The simple interface comes in four varieties. An object oriented method
call of a FileHandle object, an object oriented method of an Apache::Connection
object, and as one of two different simple subroutine calls. Other than the
calling method, these routines behave exactly the same.

- `Net::Ident::lookup (SOCKET` \[`, $timeout`\]`)`

    **Net::Ident::lookup** is an exportable function. However, due to the
    generic name of the **lookup** function, it is recommended that you
    instead import the alias function **Net::Ident::ident\_lookup**. Both
    functions are exported through `@EXPORT_OK`, so you'll have to
    explicitly ask for it if you want the function **ident\_lookup** to be
    callable from your program.

    You can pass the socket using either a string, which doesn't have to be
    qualified with a package name, or using the more modern FileHandle calling
    styles: as a glob or as a reference to a glob. The Socket has to be a
    connected TCP/IP socket, ie. something which is either **connect()**ed
    or **accept()**ed. The optional timeout parameter specifies a timeout
    in seconds. If you do not specify a timeout, or use a value of undef,
    there will be no timeout (apart from any default system timeouts like
    TCP connection timeouts).

- `Net::Ident::lookupFromInAddr ($localaddr, $remoteaddr` \[`, $timeout`\]`)`

    **Net::Ident::lookupFromInAddr** is an exportable function (via `@EXPORT_OK`).
    The arguments are the local and remote address of a connection, in packed
    \`\`sockaddr'' format (the kind of thing that `getsockname` returns). The
    optional timeout value specifies a timeout in seconds, see also the
    description of the timeout value in the `Net::Ident::lookup` section above.

    The given localaddr **must** have the IP address of a local interface of
    the machine you're calling this on, otherwise an error will occur.

    You can use this function whenever you have a local and remote socket address,
    but no direct access to the socket itself. For example, because you are
    parsing the output of "netstat" and extracting socket address, or because you
    are writing a mod\_perl script under apache (in that case, also see the
    Apache::Connection method below).

- `ident_lookup SOCKET` \[`$timeout`\]

    When you import the \`\`magic'' tag ':fh' using `use Net::Ident ':fh';`,
    the **Net::Ident** module extends the **FileHandle** class with one
    extra method call, **ident\_lookup**. It assumes that the object (a
    FileHandle) it is operating on, is a connected TCP/IP socket,
    ie. something which is either **connect()**ed or **accept()**ed. The optional
    parameter specifies the timeout in seconds, just like the timeout parameter
    of the function calls above.

     

    Some people do not like the way that \`\`proper'' object design is broken
    by letting one module add methods to another class. This is why, starting
    from version 1.20, you have to explicitly ask for this behaviour to occur.
    Personally, I this it's a compromise: if you want an object-oriented
    interface, then either you make a derived class, like a
    FileHandleThatCanPerformIdentLookups, and make sure all appropriate
    internal functions get wrappers that do the necessary re-blessing. Or,
    you simply extend the FileHandle class. And since Perl doesn't object to this
    (pun intended :), I find this an acceptable solution. But you might think
    otherwise.

- `ident_lookup Apache::Connection` \[`$timeout`\]

    When you import the \`\`magic'' tag ':apache' using `use Net::Ident ':apache';`,
    the **Net::Ident** module extends the **Apache::Connection** class with one
    extra method call, **ident\_lookup**. This method takes one optional parameter:
    a timeout value in seconds.

    This is a similar convenience function as the FileHandle::ident\_lookup method,
    to be used with mod\_perl scripts under Apache.

What these functions return depends on the context:

- scalar context

    In scalar context, these functions return the remote username on
    success, or undef on error. "Error" is rather broad, it might mean:
    some network error occurred, function arguments are invalid, the remote site
    is not responding (in time) or is not running an ident daemon, or the
    remote site ident daemon says there's no user connected with that
    particular connection.

    More precisely, the functions return whatever the remote daemon
    specified as the ID that belongs to that particular connection. This
    is often the username, but it doesn't necessarily have to be. Some
    sites, out of privacy and/or security measures, return an opaque ID
    that is unique for each user, but is not identical to the username.
    See _RFC1413_ for more information.

- array context

    In array context, these functions return: `($username, $opsys,
    $error)`.  The _$username_ is the remote username or ID, as returned
    in the scalar context, or undef on error.

    The _$opsys_ is the remote operating system as reported by the remote
    ident daemon, or undef on a network error, or **"ERROR"** when the
    remote ident daemon reported an error. This could also contain the
    character set of the returned username. See RFC1413.

    The _$error_ is the error message, either the error reported by the
    remote ident daemon (in which case _$opsys_ is **"ERROR"**), or the
    internal message from the **Net::Ident** module, which includes the
    system errno `$!` whenever possible. A likely candidate is
    **"Connection refused"** when the remote site isn't running an ident
    daemon, or **"Connection timed out"** when the remote site isn't
    answering our connection request.

    When _$username_ has a value, _$error_ is always undef, and vice versa.

## EXAMPLE

The following code is a complete example, implementing a server that
waits for a connection on a port, tells you who you are and what time
it is, and closes the connection again. The majority of the code will
look very familiar if you just read [perlipc](https://metacpan.org/pod/perlipc).

Excersize this server by telnetting to it, preferably from a machine
that has a suitable ident daemon installed.

    #!/usr/bin/perl -w

    use Net::Ident;
    # uncomment the below line if you want lots of debugging info
    # $Net::Ident::DEBUG = 2;
    use Socket;
    use strict;
    
    sub logmsg { print "$0 $$: @_ at ", scalar localtime, "\n" }
    
    my $port = shift || 2345;
    my $proto = getprotobyname('tcp');
    socket(Server, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
    setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) or
      die "setsockopt: $!";
    bind(Server, sockaddr_in($port, INADDR_ANY)) or die "bind: $!";
    listen(Server,SOMAXCONN) or die "listen: $!";
    
    logmsg "server started on port $port";
    
    my $paddr;
    
    for ( ; $paddr = accept(Client,Server); close Client) {
        my($port,$iaddr) = sockaddr_in($paddr);
        my $name = gethostbyaddr($iaddr,AF_INET) || inet_ntoa($iaddr);
        logmsg "connection from $name [" . inet_ntoa($iaddr) .
          "] at port $port";
       
        my $username = Client->ident_lookup(30) || "~unknown";
        logmsg "User at $name:$port is $username";
        
        print Client "Hello there, $username\@$name, it's now ",
           scalar localtime, "\n";
    }

## Asynchronous Interface

The asynchronous interface is meant for those who know the ins and outs
of the `select()` call (the 4-argument version of `select()`, but I
didn't need saying that, did I?). This interface is completely object
oriented. The following methods are available:

- `new Net::Ident SOCKET, $timeout`

    This constructs a new Net::Ident object, and initiates the connection
    to the remote ident daemon. The parameters are the same as described
    above for the **Net::Ident::lookup** subroutine. This method returns
    immediately, the supplied _$timeout_ is only stored in the object and
    used in future methods.

    If you want to implement your own timeout, that's fine. Simply throw
    away the object when you don't want it anymore.

    The constructor will always succeed. When it detects an error,
    however, it returns an object that "has already failed" internally. In
    this case, all methods will return `undef` except for the `geterror`
    method, wich will return the error message.

    The timeout is _not_ implemented using `alarm()`. In fact you can
    use `alarm()` completely independant of this library, they do not
    interfere.

- `newFromInAddr $localaddr, $remoteaddr, $timeout`

    Alternative constructor, that takes two packed sockaddr structures. Otherwise
    behaves identical to the `new` constructor above.

- `query $obj`

    This object method queries the remote rfc931 deamon, and blocks until
    the connection to the ident daemon is writable, if necessary (but you
    are supposed to make sure it is, of course). Returns true on success
    (or rather it returns the _$obj_ itself), or undef on error.

- `ready $obj` \[`$blocking`\]

    This object method returns whether the data received from the remote
    daemon is complete (true or false). Returns undef on error. Reads any
    data from the connection.  If _$blocking_ is true, it blocks and
    waits until all data is received (it never returns false when blocking
    is true, only true or undef). If _$blocking_ is not true, it doesn't
    block at all (unless... see below).

    If you didn't call `query $obj` yet, this method calls it for you,
    which means it _can_ block, regardless of the value of _$blocking_,
    depending on whether the connection to the ident is writable.

    Obviously, you are supposed to call this routine whenever you see that
    the connection to the ident daemon is readable, and act appropriately
    when this returns true.

    Note that once **ready** returns true, there are no longer checks on
    timeout (because the networking part of the lookup is over anyway).
    This means that even `ready $obj` can return true way after the
    timeout has expired, provided it returned true at least once before
    the timeout expired. This is to be construed as a feature.

- `username $obj`

    This object method parses the return from the remote ident daemon, and
    blocks until the query is complete, if necessary (it effectively calls
    `ready $obj 1` for you if you didn't do it yourself). Returns the
    parsed username on success, or undef on error. In an array context,
    the return values are the same as described for the
    **Net::Ident::lookup** subroutine.

- `getfh $obj`

    This object method returns the internal FileHandle used for the
    connection to the remote ident daemon. Invaluable if you want it to
    dance in your select() ring. Returns undef when an error has occurred.

- `geterror $obj`

    This object method returns the error message in case there was an
    error. undef when there was no error.

An asynchronous example implementing the above server in a multi-threaded
way via select, is left as an excersize for the interested reader.

# DISCLAIMER

I make NO WARRANTY or representation, either express or implied,
with respect to this software, its quality, accuracy, merchantability, or
fitness for a particular purpose.  This software is provided "AS IS",
and you, its user, assume the entire risk as to its quality and accuracy.

# AUTHOR

Jan-Pieter Cornet, <johnpc@xs4all.nl>

# COPYRIGHT

Copyright (c) 1995, 1997, 1999 Jan-Pieter Cornet. All rights reserved. You
can distribute and use this program under the same terms as Perl itself.

# REVISION HISTORY

- V1.20

    August 2, 1999. Finally implemented the long-asked-for lookupFromInAddr
    method. Other changes:

    - No longer imports ident\_lookup into package FileHandle by default, unless you
    explicitly ask for it (or unless you installed it that way during compile time
    for compatibility reasons).
    - Allow adding an ident\_lookup method to the Apache::Connection class, as a
    convenience for mod\_perl script writers.
    - Rewritten tests, included test for the Apache::Connection method by actually
    launching apache and performing ident lookups from within mod\_perl.
    - Moved selection of FileHandle/IO::Handle class out of the Makefile.PL. 
    PAUSE/CPAN didn't really like modules that weren't present in the
    distribution, and it didn't allow you to upgrade your perl version
    underneath.

- V1.11

    Jan 15th, 1997. Several bugfixes, and some slight interface changes:

    - constructor now called `new` instead of `initconnect`, constructor
    now always succeeds, if something has gone wrong in the constructor,
    all methods return undef (like `getfh`), except for `geterror`, which
    returns the error message.
    - The recommended exported function is now `ident_lookup` instead of
    `lookup`
    - Fixed a bug: now chooses O\_NDELAY or O\_NONBLOCK from %Config, instead
    of hardcoding O\_NDELAY (argh)
    - Adding a method to FileHandle would break in perl5.004, it should get
    added in IO::Handle. Added intelligence in Makefile.PL to detect that
    and choose the appropriate package.
    - Miscellaneous pod fixes.
    - Test script now actually tests multiple different things.

- V1.10

    Jan 11th, 1997. Complete rewrite for perl5. Requires perl5.002 or up.

- V1.02

    Jan 20th, 1995. Quite a big bugfix: "connection refused" to the ident
    port would kill the perl process with a SIGPIPE if the connect didn't
    immediately signal it (ie. almost always on remote machines). Also
    recognises the perl5 package separator :: now on fully qualified
    descriptors. This is still perl4-compatible, a perl5- only version
    would require a rewrite to make it neater.  Fixed the constants
    normally found in .ph files (but you shouldn't use those anyway).

    \[this release wasn't called **Net::Ident**, of course, it was called
    **rfc931.pl**\]

- V1.01

    Around November 1994. Removed a spurious **perl5 -w** complaint. First
    public release.  Has been tested against **perl 5.000** and **perl 4.036**.

- V1.00

    Dunno, somewhere 1994. First neat collection of dusty routines put in
    a package.

# SEE ALSO

[Socket](https://metacpan.org/pod/Socket)
RFC1413, RFC931
