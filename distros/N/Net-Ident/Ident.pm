package Net::Ident;

use strict;
use warnings;

use Socket;
use Fcntl;
use FileHandle;
use Carp;
use Config;
use Errno;
require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(ident_lookup lookup lookupFromInAddr);
our @EXPORT_FAIL;
our %EXPORT_TAGS;

# EXPORT_HOOKS is a sortof Exporter extension. Whenever one of the keys
# of this hash is imported as a "tag", the corresponding function is called
our %EXPORT_HOOKS = (
    'fh'     => \&_add_fh_method,
    'apache' => \&_add_apache_method,
    'debug'  => \&_set_debug,
);

# provide import magic
sub _export_hooks () {
    my ( $tag, $hook );
    while ( ( $tag, $hook ) = each %EXPORT_HOOKS ) {
        my $hookname = "_export_hook_$tag";    # pseudo-function name
        $EXPORT_TAGS{$tag} = [$hookname];
        push @EXPORT_OK,   $hookname;
        push @EXPORT_FAIL, $hookname;
    }
}

# put the export hooks in the standard Exporter structures
_export_hooks();

# for compatibility mode, uncomment the next line @@ s/^#\s*// @@
# @EXPORT = qw(_export_hook_fh);

our $VERSION = "1.25";

our $DEBUG = 0;
*STDDBG = *STDERR;

sub _set_debug {
    $DEBUG++;
    print STDDBG "Debugging turned to level $DEBUG\n";
}

# protocol number for tcp.
my $tcpproto = ( getprotobyname('tcp') )[2] || 6;

# get identd port (default to 113).
my $identport = ( getservbyname( 'ident', 'tcp' ) )[2] || 113;

# what to use to make nonblocking sockets
my $NONBLOCK = eval "&$Config{o_nonblock}";

# turn a filehandle passed as a string, or glob, into a ref
# private subroutine
sub _passfh ($) {
    my ($fh) = @_;

    # test if $fh is a reference. if it's not, we need to process...
    if ( !ref $fh ) {
        print STDDBG "passed fh: $fh is not a reference\n" if $DEBUG;

        # check for fully qualified name
        if ( $fh !~ /'|::/ ) {
            print STDDBG "$fh is not fully qualified\n" if $DEBUG;

            # get our current package
            my $mypkg = (caller)[0];
            print STDDBG "We are package $mypkg\n" if $DEBUG;

            # search for calling package
            my $depth = 1;
            my $otherpkg;
            $depth++ while ( ( $otherpkg = caller($depth) ) eq $mypkg );
            print STDDBG "We are called from package $otherpkg\n" if $DEBUG;
            $fh = "${otherpkg}::$fh";
            print STDDBG "passed fh now fully qualified: $fh\n" if $DEBUG;
        }

        # turn $fh into a reference to a $fh. we need to disable strict refs
        no strict 'refs';
        $fh = \*{$fh};
    }
    $fh;
}

# create a Net::Ident object, and perform a non-blocking connect()
# to the remote identd port.
# class method, constructor
sub new {
    my ( $class, $fh, $timeout ) = @_;
    my ( $localaddr, $remoteaddr );

    print STDDBG "Net::Ident::new fh=$fh, timeout=" . ( defined $timeout ? $timeout : "<undef>" ) . "\n"
      if $DEBUG > 1;

    # "try"
    eval {
        defined $fh or die "= fh undef\n";
        $fh = _passfh($fh);

        # get information about this (the local) end of the connection. We
        # assume that $fh is a connected socket of type SOCK_STREAM. If
        # it isn't, you'll find out soon enough because one of these functions
        # will return undef real fast.
        $localaddr = getsockname($fh) or die "= getsockname failed: $!\n";

        # get information about remote end of connection
        $remoteaddr = getpeername($fh) or die "= getpeername failed: $!\n";
    };
    if ( $@ =~ /^= (.*)/ ) {

        # here's the catch of the throw
        # return false, try to preserve errno
        local ($!);

        # we make a "fake" $self
        my $self = {
            'state' => 'error',
            'error' => "Net::Ident::new: $1\n",
        };
        print STDDBG $self->{error} if $DEBUG;

        # return our blessed $self
        return bless $self, $class;
    }
    elsif ($@) {

        # something else went wrong. barf up completely.
        confess($@);
    }

    # continue with the NewFromInAddr constructor
    $class->newFromInAddr( $localaddr, $remoteaddr, $timeout );
}

sub newFromInAddr {
    my ( $class, $localaddr, $remoteaddr, $timeout ) = @_;
    my $self = {};

    print STDDBG "Net::Ident::newFromInAddr localaddr=", sub { inet_ntoa( $_[1] ) . ":$_[0]" }
      ->( sockaddr_in($localaddr) ), ", remoteaddr=", sub { inet_ntoa( $_[1] ) . ":$_[0]" }
      ->( sockaddr_in($remoteaddr) ), ", timeout=", defined $timeout ? $timeout : "<undef>", "\n"
      if $DEBUG > 1;

    eval {
        # unpack addresses and store in
        my ( $localip, $remoteip );
        ( $self->{localport},  $localip )  = sockaddr_in($localaddr);
        ( $self->{remoteport}, $remoteip ) = sockaddr_in($remoteaddr);

        # create a local binding port. We cannot bind to INADDR_ANY, it has
        # to be bind (bound?) to the same IP address as the connection we're
        # interested in on machines with multiple IP addresses
        my $localbind = sockaddr_in( 0, $localip );

        # store max time
        $self->{maxtime} = defined($timeout) ? time + $timeout : undef;

        # create a remote connect point
        my $identbind = sockaddr_in( $identport, $remoteip );

        # create a new FileHandle
        $self->{fh} = new FileHandle;

        # create a stream socket.
        socket( $self->{fh}, PF_INET, SOCK_STREAM, $tcpproto )
          or die "= socket failed: $!\n";

        # bind it to the same IP number as the local end of THESOCK
        bind( $self->{fh}, $localbind ) or die "= bind failed: $!\n";

        # make it a non-blocking socket
        if ( $^O ne 'MSWin32' ) {
            fcntl( $self->{fh}, F_SETFL, $NONBLOCK ) or die "= fcntl failed: $!\n";
        }

        # connect it to the remote identd port, this can return EINPROGRESS.
        # for some reason, reading $! twice doesn't work as it should
        connect( $self->{fh}, $identbind )
          or $!{EINPROGRESS}
          or die "= connect failed: $!\n";
        $self->{fh}->blocking(0) if $^O eq 'MSWin32';
    };
    if ( $@ =~ /^= (.*)/ ) {

        # here's the catch of the throw
        # return false, try to preserve errno
        local ($!);
        $self->{error} = "Net::Ident::new: $1\n";
        print STDDBG $self->{error} if $DEBUG;

        # this deletes the FileHandle, which gets closed,
        # so that might change errno
        delete $self->{fh};

        # do NOT return, so the constructor always succeeds
    }
    elsif ($@) {

        # something else went wrong. barf up completely.
        confess($@);
    }

    # clear errno in case it contains EINPROGRESS
    $! = 0;

    # mark the state of the connection
    $self->{state} = 'connect';

    # return a blessed reference
    bless $self, $class;
}

# send the query to the remote daemon.
# object method
sub query {
    my ($self) = @_;
    my ( $wmask, $timeout, $emask, $fileno, $err, $query );

    print STDDBG "Net::Ident::query\n" if $DEBUG > 1;

    # bomb out if no fh
    return undef unless $self->{fh};

    # "try"
    eval {
        $self->{state} eq 'connect' or die "= calling in the wrong order\n";
        $fileno = fileno $self->{fh};

        # calculate the time left, abort if necessary. Note that $timeout
        # is simply left undef if $self->{maxtime} is not defined
        if ( defined( $self->{maxtime} )
            && ( $timeout = $self->{maxtime} - time ) < 0 ) {
            die "= Connection timed out\n";
        }

        # wait until the socket becomes writable.
        $wmask = '';
        vec( $wmask, $fileno, 1 ) = 1;
        scalar select( undef, $wmask, $emask = $wmask, $timeout )
          or die "= Connection timed out\n";

        # Check for errors via select (you never know)
        vec( $emask, $fileno, 1 ) and die "= connection error: $!\n";

        # fh must be writable now
        vec( $wmask, $fileno, 1 ) or die "= connection timed out or error: $!\n";

        # check for errors via getsockopt(SO_ERROR)
        $err = getsockopt( $self->{fh}, SOL_SOCKET, SO_ERROR );
        if ( !defined($err) || ( $! = unpack( 'L', $err ) ) ) {
            die "= connect: $!\n";
        }

        # create the query, based on the remote port and the local port
        $query = "$self->{remoteport},$self->{localport}\r\n";

        # write the query. Ignore the chance that such a short
        # write will be fragmented.
        syswrite( $self->{fh}, $query, length $query ) == length $query
          or die "= fragmented write on socket: $!\n";
    };
    if ( $@ =~ /^= (.*)/ ) {

        # here's the catch of the throw
        # return false, try to preserve errno
        local ($!);
        $self->{error} = "Net::Ident::query: $1\n";
        print STDDBG $self->{error} if $DEBUG;

        # this deletes the FileHandle, which gets closed,
        # so that might change errno
        delete $self->{fh};
        return undef;
    }
    elsif ($@) {

        # something else went wrong. barf up completely.
        confess($@);
    }

    # initialise empty answer to prevent uninitialised value warning
    $self->{answer} = '';

    # mark the state of the connection
    $self->{state} = 'query';

    # return the same object on success
    $self;
}

# read data, if any, and check if it's enough.
# object method
sub ready {
    my ( $self, $blocking ) = @_;
    my ( $timeout, $rmask, $emask, $answer, $ret, $fileno );

    print STDDBG "Net::Ident::ready blocking=" . ( $blocking ? "true\n" : "false\n" ) if $DEBUG > 1;

    # perform the query if not already done.
    if ( $self->{state} ne 'query' ) {
        $self->query or return undef;
    }

    # exit immediately if ready returned 1 before.
    elsif ( $self->{state} eq 'ready' ) {
        return 1;
    }

    # bomb out if no fh
    return undef unless $self->{fh};

    # "try"
    $ret = eval {
        $fileno = fileno $self->{fh};

        # while $blocking, but at least once...
        do {
            # calculate the time left, abort if necessary.
            if ( defined( $self->{maxtime} )
                && ( $timeout = $self->{maxtime} - time ) < 0 ) {
                die "= Timeout\n";
            }

            # zero timeout for non-blocking
            $timeout = 0 unless $blocking;

            # wait for something
            $rmask = '';
            vec( $rmask, $fileno, 1 ) = 1;
            if ( select( $rmask, undef, $emask = $rmask, $timeout ) ) {

                # something came in
                vec( $emask, $fileno, 1 ) and die "= error while reading: $!\n";

                # check for incoming data
                if ( vec( $rmask, $fileno, 1 ) ) {

                    # try to read as much data as possible.
                    $answer = '';
                    defined sysread( $self->{fh}, $answer, 1000 )
                      or die "= read returned error: $!\n";

                    # append incoming data to total received
                    $self->{answer} .= $answer;

                    # check for max length
                    length( $self->{answer} ) <= 1000
                      or die "= remote daemon babbling too much\n";

                    # if data contains a CR or LF, we are ready receiving.
                    # strip everything after and including the CR or LF and
                    # return success
                    if ( $self->{answer} =~ /[\n\r]/ ) {
                        $self->{answer} =~ s/[\n\r].*//s;
                        print STDDBG "Net::Ident::ready received: $self->{answer}\n"
                          if $DEBUG;

                        # close the socket to the remote identd
                        close( $self->{fh} );
                        $self->{state} = 'ready';
                        return 1;
                    }
                }
            }
        } while $blocking;

        # we don't block, but we didn't receive everything yet... return false.
        0;
    };
    if ( $@ =~ /^= (.*)/ ) {

        # here's the catch of the throw
        # return undef, try to preserve errno
        local ($!);
        $self->{error} = "Net::Ident::ready: $1\n";
        print STDDBG $self->{error} if $DEBUG;

        # this deletes the FileHandle, which gets closed,
        # so that might change errno
        delete $self->{fh};
        return undef;
    }
    elsif ($@) {

        # something else went wrong. barf up completely.
        confess($@);
    }

    # return the return value from the eval{}
    $ret;
}

# return the username from the rfc931 query return.
# object method
sub username {
    my ($self) = @_;
    my (
        $remoteport, $localport, $port1, $port2, $replytype, $reply, $opsys,
        $userid,     $error
    );

    print STDDBG "Net::Ident::username\n" if $DEBUG > 1;

    # wait for data, if necessary.
    return wantarray ? ( undef, undef, $self->{error} ) : undef
      unless $self->ready(1);

    # parse the received string, split it into parts.
    ( $port1, $port2, $replytype, $reply ) = ( $self->{answer} =~ /^\s*(\d+)\s*,\s*(\d+)\s*:\s*(ERROR|USERID)\s*:\s*(.*)$/ );

    # make sure the answer parsed properly, and that the ports are the same.
    if (   !defined($reply)
        || ( $self->{remoteport} != $port1 )
        || ( $self->{localport} != $port2 ) ) {
        $self->{error} = "Net::Ident::username couldn't parse reply or port mismatch\n";
        print STDDBG $self->{error} if $DEBUG;
        return wantarray ? ( undef, undef, $self->{error} ) : undef;
    }

    # check for error return type
    if ( $replytype eq "ERROR" ) {
        print STDDBG "Net::Ident::username: lookup returned ERROR\n" if $DEBUG;
        $userid = undef;
        $opsys  = "ERROR";
        ( $error = $reply ) =~ s/\s+$//;
    }
    else {
        # a normal reply, parse the opsys and userid. Note that the opsys may
        # contain \ escaped colons, which is why the hairy regexp is necessary.
        unless ( ( $opsys, $userid ) = ( $reply =~ /\s*((?:[^\\:]+|\\.)*):(.*)$/ ) ) {

            # didn't parse properly, abort.
            $self->{error} = "Net::Ident::username: couldn't parse userid\n";
            print STDDBG $self->{error} if $DEBUG;
            return wantarray ? ( undef, undef, $self->{error} ) : undef;
        }

        # remove trailing whitespace, except backwhacked whitespaces from opsys
        $opsys =~ s/([^\\])\s+$/$1/;

        # un-backwhack opsys.
        $opsys =~ s/\\(.)/$1/g;

        # in all cases is leading whitespace removed from the username, even
        # though rfc1413 mentions that it shouldn't be done, current
        # implementation practice dictates otherwise. What insane OS would
        # use leading whitespace in usernames anyway...
        $userid =~ s/^\s+//;

        # Test if opsys is "special": if it contains a charset definition,
        # or if it is "OTHER". This means that it is rfc1413-like, instead
        # of rfc931-like. (Why can't they make these RFCs non-conflicting??? ;)
        # Note that while rfc1413 (the one that superseded rfc931) indicates
        # that _any_ characters following the final colon are part of the
        # username, current implementation practice inserts a space there,
        # even "modern" identd daemons.
        # Also, rfc931 specifically mentions escaping characters, while
        # rfc1413 does not mention it (it isn't really necessary). Anyway,
        # I'm going to remove trailing whitespace from userids, and I'm
        # going to un-backwhack them, unless the opsys is "special".
        unless ( $opsys =~ /,/ || $opsys eq 'OTHER' ) {

            # remove trailing whitespace, except backwhacked whitespaces.
            $userid =~ s/([^\\])\s+$/$1/;

            # un-backwhack
            $userid =~ s/\\(.)/$1/g;
        }
        $error = undef;
    }

    # return the requested information, depending on whether in array context.
    if ( $DEBUG > 1 ) {
        print STDDBG "Net::Ident::username returns:\n";
        print STDDBG "userid = ", defined $userid ? $userid : "<undef>", "\n";
        print STDDBG "opsys = ",  defined $opsys  ? $opsys  : "<undef>", "\n";
        print STDDBG "error = ",  defined $error  ? $error  : "<undef>", "\n";
    }
    wantarray ? ( $userid, $opsys, $error ) : $userid;
}

# do the entire rfc931 lookup in one blow.
# exportable subroutine, not a method
sub lookup ($;$) {
    my ( $fh, $timeout ) = @_;

    print STDDBG "Net::Ident::lookup fh=$fh, timeout=", defined $timeout ? $timeout : "<undef>", "\n"
      if $DEBUG > 1;

    Net::Ident->new( $fh, $timeout )->username;
}

# do the entire rfc931 lookup from two in_addr structs
sub lookupFromInAddr ($$;$) {
    my ( $localaddr, $remoteaddr, $timeout ) = @_;

    print STDDBG "Net::Ident::lookupFromInAddr localaddr=", sub { inet_ntoa( $_[1] ) . ":$_[0]" }
      ->( sockaddr_in($localaddr) ), ", remoteaddr=", sub { inet_ntoa( $_[1] ) . ":$_[0]" }
      ->( sockaddr_in($remoteaddr) ), ", timeout=", defined $timeout ? $timeout : "<undef>", "\n"
      if $DEBUG > 1;

    Net::Ident->newFromInAddr( $localaddr, $remoteaddr, $timeout )->username;
}

# alias Net::Ident::ident_lookup to Net::Ident::lookup
sub ident_lookup ($;$);
*ident_lookup = \&lookup;

# prevent "used only once" warning
ident_lookup(0) if 0;

# get the FileHandle ref from the object, to be used in an external select().
# object method
sub getfh ($) {
    my ($self) = @_;

    $self->{fh};
}

# get the last error message.
# object method
sub geterror ($) {
    my ($self) = @_;

    $self->{error};
}

# this is called whenever a function in @EXPORT_FAIL is imported.
# simply calls the installed export hooks from %EXPORT_HOOKS, or
# passes along the export_fail up the inheritance chain
sub export_fail {
    my $pkg = shift;
    my $fail;
    my @other;
    foreach $fail (@_) {
        if ( $fail =~ /^_export_hook_(.*)$/ && $EXPORT_HOOKS{$1} ) {
            &{ $EXPORT_HOOKS{$1} };
        }
        else {
            push @other, $fail;
        }
    }
    if (@other) {
        @other = SUPER::export_fail(@other);
    }
    @other;
}

# add lookup method for FileHandle objects. Note that this relies on the
# use FileHandle;
sub _add_fh_method {

    # determine package to add method to
    my $pkg = grep( /^IO::/, @FileHandle::ISA ) ? "IO::Handle" : "FileHandle";

    # insert method in package. Arguments are already OK for std lookup
    # turn off strict refs for this glob-mangling trick
    no strict 'refs';
    *{"${pkg}::ident_lookup"} = \&lookup;

    print STDDBG "Added ${pkg}::ident_lookup method\n" if $DEBUG;
}

sub _add_apache_method {

    # add method to Apache::Connection class
    no strict 'refs';
    *{"Apache::Connection::ident_lookup"} = sub {
        my ( $self, $timeout ) = @_;

        print STDDBG "Apache::Connection::ident_lookup self=$self, ", "timeout=", defined $timeout ? $timeout : "<undef>", "\n"
          if $DEBUG > 1;
        lookupFromInAddr( $self->local_addr, $self->remote_addr, $timeout );
    };

    print STDDBG "Added Apache::Connection::ident_lookup method\n" if $DEBUG;
}

1;

__END__

=head1 NAME

Net::Ident - lookup the username on the remote end of a TCP/IP connection

=head1 SYNOPSIS

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

=head1 OVERVIEW

B<Net::Ident> is a module that looks up the username on the remote
side of a TCP/IP connection through the ident (auth/tap) protocol
described in RFC1413 (which supersedes RFC931). Note that this
requires the remote site to run a daemon (often called B<identd>) to
provide the requested information, so it is not always available for
all TCP/IP connections.

=head1 DESCRIPTION

You can either use the simple interface, which does one ident
lookup at a time, or use the asynchronous interface to perform
(possibly) many simultaneous lookups, or simply continue serving other
things while the lookup is proceeding.

=head2 Simple Interface

The simple interface comes in four varieties. An object oriented method
call of a FileHandle object, an object oriented method of an Apache::Connection
object, and as one of two different simple subroutine calls. Other than the
calling method, these routines behave exactly the same.

=over 4

=item C<Net::Ident::lookup (SOCKET> [C<, $timeout>]C<)>

B<Net::Ident::lookup> is an exportable function. However, due to the
generic name of the B<lookup> function, it is recommended that you
instead import the alias function B<Net::Ident::ident_lookup>. Both
functions are exported through C<@EXPORT_OK>, so you'll have to
explicitly ask for it if you want the function B<ident_lookup> to be
callable from your program.

You can pass the socket using either a string, which doesn't have to be
qualified with a package name, or using the more modern FileHandle calling
styles: as a glob or as a reference to a glob. The Socket has to be a
connected TCP/IP socket, ie. something which is either B<connect()>ed
or B<accept()>ed. The optional timeout parameter specifies a timeout
in seconds. If you do not specify a timeout, or use a value of undef,
there will be no timeout (apart from any default system timeouts like
TCP connection timeouts).

=item C<Net::Ident::lookupFromInAddr ($localaddr, $remoteaddr> [C<, $timeout>]C<)>

B<Net::Ident::lookupFromInAddr> is an exportable function (via C<@EXPORT_OK>).
The arguments are the local and remote address of a connection, in packed
``sockaddr'' format (the kind of thing that C<getsockname> returns). The
optional timeout value specifies a timeout in seconds, see also the
description of the timeout value in the C<Net::Ident::lookup> section above.

The given localaddr B<must> have the IP address of a local interface of
the machine you're calling this on, otherwise an error will occur.

You can use this function whenever you have a local and remote socket address,
but no direct access to the socket itself. For example, because you are
parsing the output of "netstat" and extracting socket address, or because you
are writing a mod_perl script under apache (in that case, also see the
Apache::Connection method below).

=item C<ident_lookup SOCKET> [C<$timeout>]

When you import the ``magic'' tag ':fh' using C<use Net::Ident ':fh';>,
the B<Net::Ident> module extends the B<FileHandle> class with one
extra method call, B<ident_lookup>. It assumes that the object (a
FileHandle) it is operating on, is a connected TCP/IP socket,
ie. something which is either B<connect()>ed or B<accept()>ed. The optional
parameter specifies the timeout in seconds, just like the timeout parameter
of the function calls above.

=cut
# add a paragraph about compatibility mode if appropriate. The non-breaking
# spaces are to force a new paragraph.
# @@12 s/^#// @@
#
#=pod
#
#S< >
#
#Adding the B<ident_lookup> method to the B<FileHandle> class used to be
#automatic in previous version of B<Net::Ident>. During the installation
#of this B<Net::Ident> package, the system administrator choose to install
#it in a compatible way, meaning that on this machine, the B<ident_lookup>
#method is automatically added if you use just C<use Net::Ident;>
#
#=cut
# end of extra paragraph

=pod

S< >

Some people do not like the way that ``proper'' object design is broken
by letting one module add methods to another class. This is why, starting
from version 1.20, you have to explicitly ask for this behaviour to occur.
Personally, I this it's a compromise: if you want an object-oriented
interface, then either you make a derived class, like a
FileHandleThatCanPerformIdentLookups, and make sure all appropriate
internal functions get wrappers that do the necessary re-blessing. Or,
you simply extend the FileHandle class. And since Perl doesn't object to this
(pun intended :), I find this an acceptable solution. But you might think
otherwise.

=item C<ident_lookup Apache::Connection> [C<$timeout>]

When you import the ``magic'' tag ':apache' using C<use Net::Ident ':apache';>,
the B<Net::Ident> module extends the B<Apache::Connection> class with one
extra method call, B<ident_lookup>. This method takes one optional parameter:
a timeout value in seconds.

This is a similar convenience function as the FileHandle::ident_lookup method,
to be used with mod_perl scripts under Apache.

=back

What these functions return depends on the context:

=over 4

=item scalar context

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
See I<RFC1413> for more information.

=item array context

In array context, these functions return: C<($username, $opsys,
$error)>.  The I<$username> is the remote username or ID, as returned
in the scalar context, or undef on error.

The I<$opsys> is the remote operating system as reported by the remote
ident daemon, or undef on a network error, or B<"ERROR"> when the
remote ident daemon reported an error. This could also contain the
character set of the returned username. See RFC1413.

The I<$error> is the error message, either the error reported by the
remote ident daemon (in which case I<$opsys> is B<"ERROR">), or the
internal message from the B<Net::Ident> module, which includes the
system errno C<$!> whenever possible. A likely candidate is
B<"Connection refused"> when the remote site isn't running an ident
daemon, or B<"Connection timed out"> when the remote site isn't
answering our connection request.

When I<$username> has a value, I<$error> is always undef, and vice versa.

=back

=head2 EXAMPLE

The following code is a complete example, implementing a server that
waits for a connection on a port, tells you who you are and what time
it is, and closes the connection again. The majority of the code will
look very familiar if you just read L<perlipc>.

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

=head2 Asynchronous Interface

The asynchronous interface is meant for those who know the ins and outs
of the C<select()> call (the 4-argument version of C<select()>, but I
didn't need saying that, did I?). This interface is completely object
oriented. The following methods are available:

=over 4

=item C<new Net::Ident SOCKET, $timeout>

This constructs a new Net::Ident object, and initiates the connection
to the remote ident daemon. The parameters are the same as described
above for the B<Net::Ident::lookup> subroutine. This method returns
immediately, the supplied I<$timeout> is only stored in the object and
used in future methods.

If you want to implement your own timeout, that's fine. Simply throw
away the object when you don't want it anymore.

The constructor will always succeed. When it detects an error,
however, it returns an object that "has already failed" internally. In
this case, all methods will return C<undef> except for the C<geterror>
method, wich will return the error message.

The timeout is I<not> implemented using C<alarm()>. In fact you can
use C<alarm()> completely independent of this library, they do not
interfere.

=item C<newFromInAddr $localaddr, $remoteaddr, $timeout>

Alternative constructor, that takes two packed sockaddr structures. Otherwise
behaves identical to the C<new> constructor above.

=item C<query $obj>

This object method queries the remote rfc931 daemon, and blocks until
the connection to the ident daemon is writable, if necessary (but you
are supposed to make sure it is, of course). Returns true on success
(or rather it returns the I<$obj> itself), or undef on error.

=item C<ready $obj> [C<$blocking>]

This object method returns whether the data received from the remote
daemon is complete (true or false). Returns undef on error. Reads any
data from the connection.  If I<$blocking> is true, it blocks and
waits until all data is received (it never returns false when blocking
is true, only true or undef). If I<$blocking> is not true, it doesn't
block at all (unless... see below).

If you didn't call C<query $obj> yet, this method calls it for you,
which means it I<can> block, regardless of the value of I<$blocking>,
depending on whether the connection to the ident is writable.

Obviously, you are supposed to call this routine whenever you see that
the connection to the ident daemon is readable, and act appropriately
when this returns true.

Note that once B<ready> returns true, there are no longer checks on
timeout (because the networking part of the lookup is over anyway).
This means that even C<ready $obj> can return true way after the
timeout has expired, provided it returned true at least once before
the timeout expired. This is to be construed as a feature.

=item C<username $obj>

This object method parses the return from the remote ident daemon, and
blocks until the query is complete, if necessary (it effectively calls
C<ready $obj 1> for you if you didn't do it yourself). Returns the
parsed username on success, or undef on error. In an array context,
the return values are the same as described for the
B<Net::Ident::lookup> subroutine.

=item C<getfh $obj>

This object method returns the internal FileHandle used for the
connection to the remote ident daemon. Invaluable if you want it to
dance in your select() ring. Returns undef when an error has occurred.

=item C<geterror $obj>

This object method returns the error message in case there was an
error. undef when there was no error.

=back

An asynchronous example implementing the above server in a multi-threaded
way via select, is left as an excersize for the interested reader.

=head1 DISCLAIMER

I make NO WARRANTY or representation, either express or implied,
with respect to this software, its quality, accuracy, merchantability, or
fitness for a particular purpose.  This software is provided "AS IS",
and you, its user, assume the entire risk as to its quality and accuracy.

=head1 AUTHOR

Jan-Pieter Cornet, <johnpc@xs4all.nl>

=head1 COPYRIGHT

Copyright (c) 1995, 1997, 1999 Jan-Pieter Cornet. All rights reserved. You
can distribute and use this program under the same terms as Perl itself.

=head1 REVISION HISTORY

=over 4

=item V1.20

August 2, 1999. Finally implemented the long-asked-for lookupFromInAddr
method. Other changes:

=over 1

=item *

No longer imports ident_lookup into package FileHandle by default, unless you
explicitly ask for it (or unless you installed it that way during compile time
for compatibility reasons).

=item *

Allow adding an ident_lookup method to the Apache::Connection class, as a
convenience for mod_perl script writers.

=item *

Rewritten tests, included test for the Apache::Connection method by actually
launching apache and performing ident lookups from within mod_perl.

=item *

Moved selection of FileHandle/IO::Handle class out of the Makefile.PL. 
PAUSE/CPAN didn't really like modules that weren't present in the
distribution, and it didn't allow you to upgrade your perl version
underneath.

=back

=item V1.11

Jan 15th, 1997. Several bugfixes, and some slight interface changes:

=over 1

=item *

constructor now called C<new> instead of C<initconnect>, constructor
now always succeeds, if something has gone wrong in the constructor,
all methods return undef (like C<getfh>), except for C<geterror>, which
returns the error message.

=item *

The recommended exported function is now C<ident_lookup> instead of
C<lookup>

=item *

Fixed a bug: now chooses O_NDELAY or O_NONBLOCK from %Config, instead
of hardcoding O_NDELAY (argh)

=item *

Adding a method to FileHandle would break in perl5.004, it should get
added in IO::Handle. Added intelligence in Makefile.PL to detect that
and choose the appropriate package.

=item *

Miscellaneous pod fixes.

=item *

Test script now actually tests multiple different things.

=back

=item V1.10

Jan 11th, 1997. Complete rewrite for perl5. Requires perl5.002 or up.

=item V1.02

Jan 20th, 1995. Quite a big bugfix: "connection refused" to the ident
port would kill the perl process with a SIGPIPE if the connect didn't
immediately signal it (ie. almost always on remote machines). Also
recognises the perl5 package separator :: now on fully qualified
descriptors. This is still perl4-compatible, a perl5- only version
would require a rewrite to make it neater.  Fixed the constants
normally found in .ph files (but you shouldn't use those anyway).

[this release wasn't called B<Net::Ident>, of course, it was called
B<rfc931.pl>]

=item V1.01

Around November 1994. Removed a spurious B<perl5 -w> complaint. First
public release.  Has been tested against B<perl 5.000> and B<perl 4.036>.

=item V1.00

Dunno, somewhere 1994. First neat collection of dusty routines put in
a package.

=back

=head1 SEE ALSO

L<Socket>
RFC1413, RFC931

=cut
