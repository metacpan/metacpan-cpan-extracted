package Patro;
use strict;
use warnings;
use Patro::Mony;
use Patro::LeumJelly;
use Scalar::Util;
use Data::Dumper;
use Socket ();
use Carp;
use base 'Exporter';
no overloading '%{}', '${}';

our @EXPORT = qw(patronize getProxies);
our $VERSION = '0.16';

BEGIN { *CORE::GLOBAL::ref = \&Patro::ref };

sub import {
    my ($class, @args) = @_;
    my @tags = grep /^:/, @args;
    @args = grep !/^:/, @args;
    foreach my $tag (@tags) {
	if ($tag eq ':test') {
	    require Patro::Server;
	    Patro::Server->TEST_MODE;

	    # a poor man's Data::Dumper, but works for Patro::N objects.
	    *xjoin = sub {
		join(",", map { my $r = $_;
				my $rt = Patro::reftype($_) || "";
				$rt eq 'ARRAY' ? "[" . xjoin(@$r) . "]" :
				$rt eq 'HASH' ? do {
			"{".xjoin(map{"$_:'".$r->{$_}."'"}sort keys %$r)."}" 
				} : $_ } @_)
	    };
	    push @EXPORT, 'xjoin';
	}
	if ($tag eq ':insecure') {
	    $Patro::Server::OPTS{secure_filehandles} = 0;
	    $Patro::Server::OPTS{steal_lock_ok} = 1;
	}
    }

    if (defined($ENV{PATRO_THREADS}) &&
	!$ENV{PATRO_THREADS}) {
	$INC{'threads.pm'} = 1;
    }		
    eval "use threads;1";
    eval "use threadsx::shared";
    $Patro::Server::threads_avail = $threads::threads;
    if (!defined &threads::tid) {
	*threads::tid = sub { 0 };
    }
    if ($ENV{PATRO_THREADS} && !$Patro::Server::threads_avail) {
	warn "Threaded Patro server was requested but was not available\n";
    }
    Patro->export_to_level(1, 'Patro', @args, @EXPORT);
}

# make Patro::nize a synonym for patronize
sub nize { goto &patronize }

sub patronize {
    croak 'usage: Patro::patronize(@refs)' if @_ == 0;
    require Patro::Server;
    my $server = Patro::Server->new({}, @_);
    return $server->{config};
}

sub ref (_) {
    my $obj = @_ ? $_[0] : $_;
    my $ref = CORE::ref($obj);
    if (!Patro::LeumJelly::isProxyRef($ref)) {
	return $ref;
    }
    my $handle = Patro::LeumJelly::handle($obj);
    return $handle->{ref};
}

sub reftype {
    my $ref = CORE::ref($_[0]);
    if (!Patro::LeumJelly::isProxyRef($ref)) {
	return Scalar::Util::reftype($_[0]);
    }
    my $handle = Patro::LeumJelly::handle($_[0]);
    return $handle->{reftype};
}

sub _allrefs {
    return (CORE::ref($_[0]), Patro::ref($_[0]),
	    Scalar::Util::reftype($_[0]), Patro::reftype($_[0]));
}

sub client {
    if (!Patro::LeumJelly::isProxyRef(CORE::ref($_[0]))) {
	return;     # not a remote proxy object
    }
    return Patro::LeumJelly::handle($_[0])->{client};
}

sub main::xdiag {
    my @lt = localtime;
    my $lt = sprintf "%02d:%02d:%02d", @lt[2,1,0];
    my $pid = $$;
    $pid .= "-" . threads->tid if $threads::threads;
    my @msg = map { CORE::ref($_)
		        ? CORE::ref($_) =~ /^Patro::N/
			? "<" . CORE::ref($_) . ">"
			: Data::Dumper::Dumper($_) : $_ } @_;
    if ($INC{'Test/More.pm'}) {
	Test::More::diag("xdiag $pid $lt: ",@msg);
    } else {
	print STDERR "xdiag $pid $lt: @msg\n";
    }
}

# proxy synchronization

sub synchronize ($&;$$) {
    no overloading '%{}';
    my ($proxy, $block, $timeout, $steal) = @_;
    my $status = Patro::lock($proxy, $timeout, $steal);
    my @r = eval {
	if (wantarray) {
	    $block->();
	} elsif (defined wantarray) {
	    scalar $block->();
	} else {
	    $block->();
	    0;
	}
    };
    my $error = $@;
    $status = Patro::unlock($proxy);
    if ($error) {
	carp "Exception in synchronized block: $error";
	return;
    }
    if (!$status) {
	# does not warn if status was "0 but true"
	carp "Patro::unlock: unlock on proxy failed: $!";
    }
    return wantarray ? @r : @r ? $r[-1] : undef;
}

sub lock {
    my ($proxy, $timeout, $steal) = @_;
    my $handle = Patro::LeumJelly::handle($proxy);
    if (!$handle) {
	carp "Patro::lock: not a proxy";
	return;
    }
    my $status = Patro::LeumJelly::proxy_request(
	$handle,
	{ topic => 'SYNC',
	  command => 'lock', context => 1,
	  id => $handle->{id},
	  has_args => defined($timeout),
	  args => [ $timeout, $steal ] } );
    if (!$status) {
	carp "Patro::lock: lock on proxy $handle->{id} was not acquired";
	return;
    }
    return $status;
}

sub unlock {
    my ($proxy, $count) = @_;
    $count ||= 1;
    my $handle = Patro::LeumJelly::handle($proxy);
    if (!$handle) {
	carp "Patro::unlock: not a proxy";
    }
    my $status = Patro::LeumJelly::proxy_request(
	$handle,
	{ topic => 'SYNC', command => 'unlock', context => 1,
	  id => $handle->{id},
	  has_args => 1, args => [ $count ] });
    if (!$status) {
	# does not warn if status was "0 but true"
	carp "Patro::unlock: unlock operation on $handle->{id} failed";
    }
    return $status;
}

sub wait {
    my ($proxy,$timeout) = @_;
    no overloading '%{}';
    my $handle = Patro::LeumJelly::handle($proxy);
    my $status = Patro::LeumJelly::proxy_request(
	$handle, { topic => 'SYNC', command => 'wait', context => 1,
		   has_args => defined($timeout), args => [$timeout] });
    return $status;		   
}

sub notify {
    my ($proxy, $count) = @_;
    no overloading '%{}';
    my $handle = Patro::LeumJelly::handle($proxy);
    my $status = Patro::LeumJelly::proxy_request(
	$handle, { topic => 'SYNC', command => 'notify', context => 1,
		   has_args => defined($count), args => [ $count ] } );
    return $status;
}

sub lock_state {
    my ($proxy) = @_;
    no overloading '%{}';
    my $handle = Patro::LeumJelly::handle($proxy);
    my $state = Patro::LeumJelly::proxy_request( 
	$handle, { topic => 'SYNC', command => 'state', context => 1,
		   id => $handle->{id}, has_args => 0 } );
    my ($num,$str) = split /,/, $state;
    return Scalar::Util::dualvar($num,$str);
}



# Patro OO-interface

sub new {
    my ($pkg,$config) = @_;

    # want config to be a Patro::Config
    # but it could be a string or a filenae (from Patro::Config::to_string
    # or to_file)
    if (!CORE::ref($config)) {
	if (-f $config) {
	    $config = Patro::Config->from_file($config);
	} else {
	    $config = Patro::Config->from_string($config);
	}
    }

    croak __PACKAGE__,": no host" unless $config->{host};
    croak __PACKAGE__,": no port" unless $config->{port};

    my $iaddr = Socket::inet_aton($config->{host});
    my $paddr = Socket::pack_sockaddr_in($config->{port}, $iaddr);

    socket(my $socket, Socket::PF_INET(), Socket::SOCK_STREAM(),
	   getprotobyname("tcp")) or croak __PACKAGE__,": socket $!";
    connect($socket,$paddr) 
	or croak(__PACKAGE__, ": connect to $config->{host}:$config->{port}",
		 " failed: $!");

    my $self = bless {
	config => $config,
	socket => $socket,
	proxies => {},
	objs => [],
    }, $pkg;

    $Patro::SERVER_VERSION = $config->{version};

    my $fh0 = select $socket;
    $| = 1;
    select $fh0;

    foreach my $odata (@{$config->{store}}) {
	my $proxyref = Patro::LeumJelly::getproxy($odata,$self);
	$self->{proxies}{$odata->{id}} = $proxyref;
	push @{$self->{objs}}, $proxyref;
    }
    return $self;
}

sub getProxies {
    my $patro = shift;
    if (CORE::ref($patro) ne 'Patro') {
	$patro = Patro->new($patro);
    }
    return wantarray ? @{$patro->{objs}} : $patro->{objs}[0];
}

########################################

1;

=head1 NAME

Patro - proxy access to remote objects


=head1 VERSION

0.16


=head1 SYNOPSIS

    # on machine 1 (server)
    use Patro;
    my $obj = ...
    $config = patronize($obj);
    $config->to_file( 'config_file' );


    # on machines 2 through n (clients)
    use Patro;
    my ($proxy) = Patro->new( 'config_file' )->getProxies;
    ...
    $proxy->{key} = $val;         # updates $obj->{key} for obj on server
    $val = $proxy->method(@args); # calls $obj->method for obj on server


=head1 DESCRIPTION

C<Patro> is a mechanism for making any Perl reference in one Perl program
accessible is other processes, even processes running on different hosts.
The "proxy" references have the same look and feel as the native references
in the original process, and any manipulation of the proxy reference
will have an effect on the original reference.

=head2 Some important features:

=over 4

=item * Hash members and array elements

Accessing or updating hash values or array values on a remote reference
is done with the same syntax as with the local reference:

    # host 1
    use Patro;
    my $hash1 = { abc => 123, def => [ 456, { ghi => "jkl" }, "mno" ] };
    my $config = patronize($hash1);
    ...

    # host 2
    use Patro;
    my $hash2 = Patro->new($config)->getProxies;
    print $hash2->{abc};                # "123"
    $hash2->{def}[2] = "pqr";           # updates $hash1 on host 1
    print delete $hash2->{def}[1]{ghi}; # "jkl", updates $hash1 on host1

=item * Remote method calls

Method calls on the proxy object are propagated to the original object,
affecting the remote object and returning the result of the call.

    # host 1
    use Patro;
    sub Foofie::new { bless \$_[1],'Foofie' }
    sub Foofie::blerp { my $self=shift; wantarray ? (5,6,7,$$self) : ++$$self }
    patronize(Foofie->new(17))->to_file('/config/file');
    ...

    # host 2
    use Patro;
    my $foo = Patro->new('/config/file')->getProxies;
    my @x = $foo->blerp;           # (5,6,7,17)
    my $x = $foo->blerp;           # 18

=item * Overloaded operators

Any overloaded operations on the original object are supported on the
remote object.

    # host 1
    use Patro;
    my $obj = Barfie->new(2,5);
    $config = patronize($obj);
    $config->to_file( 'config' );
    package Barfie;
    use overload '+=' => sub { $_ += $_[1] for @{$_[0]->{vals}};$_[0] },
         fallback => 1;
    sub new {
        my $pkg = shift;
        bless { vals => [ @_ ] }, $pkg;
    }
    sub prod { my $self = shift; my $z=1; $z*=$_ for @{$_[0]->{vals}}; $z }

    # host 2
    use Patro;
    my $proxy = getProxies('config');
    print $proxy->prod;      # calls Barfie::prod($obj) on host1, 2 * 5 => 10
    $proxy += 4;             # calls Barfie '+=' sub on host1
    print $proxy->prod;      # 6 * 9 => 54

=item * Code references

Patro supports sharing code references and data structures that contain
code references (think dispatch tables). Proxies to these code references
can invoke the code, which will then run on the server.

    # host 1
    use Patro;
    my $foo = sub { $_[0] + 42 };
    my $d = {
        f1 => sub { $_[0] + $_[1] },
        f2 => sub { $_[0] * $_[1] },
        f3 => sub { int( $_[0] / ($_[1] || 1) ) },
        g1 => sub { $_[0] += $_[1]; 18 },
    };
    patronize($foo,$d)->to_file('config');
    ...

    # host 2
    use Patro;
    my ($p_foo, $p_d) = getProxies('config');
    print $p_foo->(17);        # "59"   (42+17)
    print $p_d->{f1}->(7,33);  # "40"   (7+33)
    print $p_d->{f3}->(33,7);  # "4"    int(33/7)
    ($x,$y) = (5,6);
    $p_d->{g1}->($x,$y);
    print $x;                  # "11"   ($x:6 += 5)

=item * filehandles

Filehandles can also be shared through the Patro framework.

    # host 1
    use Patro;
    open my $fh, '>', 'host1.log';
    patronize($fh)->to_file('config');
    ...

    # host 2
    use Patro;
    my $ph = getProxies('config');
    print $ph "A log message for the server\n";

Calling C<open> through a proxy filehandle presents some security concerns.
A client could read or write any file on the server host visible to the
server's user id. Or worse, a client could open a pipe through the handle
to run an arbitrary command on the server. C<open> and C<close> operations
on proxy filehandles will not be allowed unless the process running the
Patro server imports C<Patro> with the C<:insecure> tag.
See L<Patro::Server/"SERVER OPTIONS"> for more information.

=back


=head1 FUNCTIONS

=head2 patronize

    CONFIG = patronize(@REFS)

Creates a server on the local machine that provides proxy access to
the given list of references. It returns an object
with information about how to connect to the server. 

The returned object has C<to_string> and C<to_file> methods
to store the configuration where it can be read by other processes.
Either the object, its string representation, or the filename 
containing config information may be used as input to the
L<"getProxies"> function to retrieve proxies to the shared
references.

=head2 getProxies

    PROXIES = getProxies(CONFIG)
    PROXIES = getProxies(STRING)
    PROXIES = getProxies(FILENAME)

Connects to a server on another machine, specified in the C<CONFIG>
string, and returns proxies to the list of references that are served.
In scalar context, returns a proxy to the first reference that is
served.

See the L<"PROXIES"> section below for what you can do with the output
of this function.

=head2 ref

    TYPE = Patro::ref(PROXY)

For the given proxy object, returns the ref type of the remote object
being served. If the input is not a proxy, returns C<undef>.
See also L<"reftype">.

=head2 reftype

    TYPE = Patro::reftype(PROXY)

Returns the simple reference type (e.g., C<ARRAY>) of the remote
object associated with the given proxy, as if we were calling
C<Scalar::Util::reftype> on the remote object. Returns C<undef> if
the input is not a proxy object.

=head2 client

    CLIENT = Patro::client(PROXY)

Returns the IPC client object used by the given proxy to communicate
with the remote object server. The client object contains information
about how to communicate with the server and other connection 
configuration.

Also see the functions related to remote resource synchronization
in the L<"SYNCHRONIZATION"> section below.


=head1 PROXIES

Proxy references, as returned by the L<"getProxies"> function above,
or sometimes returned in other calls to the server, are designed
to look and feel as much as possible as the real references on the
remote server that they provide access to, so any operation or
expression with the proxy on the local machine should evaluate
to the same value(s) as the same operation or expression with the
real object/reference on the remote server. 
When the server if using threads and is sharing the served
objects between threads, an update to the
proxy object will affect the remote object, and vice versa.

=head2 Example 1: network file synchronization

Network file systems are notoriously flaky when it comes to
synchronizing files that are being written to by processes on
many different hosts [citation needed]. C<Patro> provides a
workaround, in that every machine can hold to a proxy to an object
that writes to a file, with the object running on a single machine.

    # master
    package SyncWriter;
    use Fcntl qw(:flock SEEK_END);
    sub new {
        my ($pkg,$filename) = @_;
        open my $fh, '>', $filename;
        bless { fh => $fh }, $pkg;
    }
    sub print {
        my $self = shift;
        flock $self->{fh}, LOCK_EX;
        seek $self->{fh}, 0, SEEK_END;
        print {$self->{fh}} @_;
        flock $self->{fh}, LOCK_UN;
    }
    sub printf { ... }

    use Patro;
    my $writer = SyncWriter->new("file.log");
    my $cfg = patronize($writer);
    open my $fh,'>','/network/accessible/file';
    print $fh $cfg;
    close $fh;
    ...

    # slaves
    use Patro;
    open my $fh, '<', '/network/accessible/file';
    my $cfg = <$fh>;
    close $fh;
    my $writer = Patro->new($cfg)->getProxies;
    ...
    # $writer->print with a proxy $writer
    # invokes $writer->print on the host. Since all
    # the file operations are done on a single machine,
    # there are no network synchronization issues
    $writer->print("a log message\n");
    ...

=head2 Example 2: Distributed queue

A program that distributes tasks to several threads or several
child processes can be extended to distribute tasks to
several machines.

    # master
    use Patro;
    my $queue = [ 'job 1', 'job 2', ... ];
    patronize($queue)->to_file('/network/accessible/file');
    ...

    # slaves
    use Patro;
    my $queue = Patro->new('/network/accessible/file')->getProxies;

    while (my $task = shift @$queue) {
        ... do task ...
    }

(This example will not work without threads. For a more robust
network-safe queue that will run with forks, see L<Forks::Queue>)

=head2 Example 3: Keep your code secret

If you distribute your Perl code for others to use, it is very
difficult to keep others from being able to see (and potentially
steal) your code. L<Obfuscators|Acme::Bleach> are penetrable by
any determined reverse engineer. Most other suggestions for keeping
your code secret revolve around running your code on a server,
and having your clients send input and receive output through a
network service.

The C<Patro> framework can make this service model easier to use.
Design a small set of objects that can execute your code, provide
your clients with a public API for those objects, and make proxies
to your objects available through C<Patro>.

    # code to run on client machine
    use Patro;
    my $cfg = ...    # provided by you
    my ($obj1,$obj2) = Patro->new($cfg)->getProxies;
    $result = $obj1->method($arg1,$arg2);
    ...

In this model, the client can use the objects and methods of your code,
and inspect the members of your objects through the proxies, but the
client cannot see the source code.


=head1 SYNCHRONIZATION

A C<Patro> server may make the same reference available to more
than one client. If the server is running in "threads" mode, each
client will have an instance of the reference in a different thread,
and the reference will be L<shared|threads::shared> between
threads. For thread safety, we will want threads and processes
to have exclusive access to the reference. This also applies to client
processes that have a proxy to a remote resource.

C<Patro> provides a few functions to request and manage exclusive
access to remote references. Like most such "locks" in Perl, these
locks are "advisory", meaning clients that do not use this
synchronization scheme may still manipulate remote references 
that are locked with this scheme by other clients.

=head2 synchronize

=head2 @list = Patro::synchronize $proxy, BLOCK [, options]

=head2 $list = Patro::synchronize $proxy, BLOCK [, options]

Requests exclusive access to the underlying remote object
that the C<$proxy> refers to. When access is granted,
executes the given C<BLOCK> in either list or scalar context.
When the code C<BLOCK> is finished, relinquish control of
the remote resource and return the results of the code.

    use Patro;
    $proxy = getProxies('config/file');
    Patro::synchronize $proxy, sub {
        $proxy->method_call_that_needs_thread_safety()
    };

C<options> may be a hash or reference to a hash, with these
two key-value pairs recognized:

=over 4

=item C<< timeout => $seconds >>

Waits at least C<$seconds> seconds until the lock for the
remote resource is available, and gives up after that. 
Using a negative value for C<$seconds> has the semantics of
a non-blocking lock call. If C<$seconds> is negative and
the lock is not acquired on the first attempt, the
C<synchronize> call does not make any further attempts.
If the lock is not acquired, C<synchronize> will
return the empty list and set C<$!>.

=item C<< steal => $bool >>

If true, and if allowed by the server, acquires the lock
for the remote resource even if it is held by another
process. If C<timeout> is also specified, waits until
the timeout expires before stealing the lock.

Whether one monitor may steal the lock from another monitor
is a setting on the server. If stealing is not allowed
and if this call can not acquire the lock conventionally,
the C<synchronize> call returns the empty list and
sets C<$!>.

=back

=head2 lock

=head2 unlock

=head2 $status = Patro::lock($proxy [, $timeout [, $steal]])

=head2 $status = Patro::unlock($proxy [,$count])

An alternative to the C<Patro::synchronize($proxy, $code)>
syntax is to use C<Patro::lock> and C<Patro::unlock>
explicitly.

C<Patro::lock> attempts to acquire an exclusive (but advisory)
lock on the remote resource referred to by the C<$proxy>.
It returns true if the lock was successfully acquired, and
returns false and sets C<$!> if there was an issue acquiring the
lock. As in the options to C<Patro::synchronize>, you may
specify a timeout -- a maximum number of seconds to wait to
acquire the lock, and/or set the steal flag, which will always
acquire the lock even if it is held by another monitor (if the
server allows stealing).

C<Patro::lock> may be called on a proxy that already possesses
the lock on its remote resource. Successive C<lock> calls "stack"
so that you must call C<Patro::unlock> on the proxy the same
number of times that you call C<Patro::lock> (or provide a
C<$count> argument to C<Patro::unlock>, see below) before the lock on
the remote resource will be released.

C<Patro::unlock> release the (a) lock on the remote resource
referred to by the C<$proxy>. Returns true if the lock was
successfully removed. A false return value generally means that
the given C<$proxy> was not in possession of the remote resource's
lock at the time the function was called.

Since lock calls "stack", a proxy may hold the lock on a remote
resource more than one time. If a C<$count> argument is provided
to C<Patro::unlock>, more than one of those stacked locks can
be released. If C<$count> is positive, C<Patro::unlock> will release
up to C<$count> locks held by the proxy. If C<$count> is negative,
all locks will be released and the lock on the remote resource
will become available.

=head2 wait

=head2 $status = Patro::wait($proxy [, $timeout])

For a C<$proxy> that possesses the lock on its remote resource,
releases the lock and puts the resource monitor into a "wait"
state. The monitor will remain in that state until another
monitor on the same resource issues a C<notify> call
(see L<"notify"> below). After the monitor receives a "notify"
call, it will attempt to reacquire the lock before resuming
execution. Returns true if the monitor successfully releases
the lock, waits for a notify call, and reacquires the lock.

If a C<$timeout> is specified, the C<Patro::wait> call
will return after C<$timeout> seconds whether or not the
monitor has been notified and the lock has been reacquired.
C<Patro::wait> will also return false if C<$proxy> is not
currently in possession of its remote resource's lock.

=head2 notify

=head2 $status = Patro::notify($proxy [,$count])

For a C<$proxy> that possess the lock on its remote resource,
move one or more other monitors on the resource that are
currently in a "wait" state into a "notify" state, so that
those other monitor will attempt to acquire the lock to the
remote resource. If C<$count> is provided and is positive,
this function will notify up to C<$count> other monitors.
If C<$count> is negative, this function will notify all
waiting monitors.

Returns false if the C<$proxy> is not in possession of the
lock on the remote resource when the function call is made.
Otherwise, returns the number of monitors notified, or
"0 but true" if there were no monitors to notify.

Note that a C<Patro::notify> call does not release the
remote resource. The notified monitors would still have to
wait for the monitor that called C<notify> to release the
lock on the remote resource.

=head2 lock_state

=head2 $state = lock_state($proxy)

Returns a code indicating the status of the proxy's
monitor on the lock of its remote resource. The return values
will be one of

    0 - NULL - the monitor does not possess the lock
    1 - WAIT - the monitor has received a wait call since it
               last possessed the lock
    2 - NOTIFY - the monitor has received a notify call since
               it last possessed the lock
    3 - STOLEN - the monitor possessed the lock, but it was
               stolen by another monitor
  >=4 - LOCK - the monitor possesses the lock. Values larger than
               4 indicate that the monitor has stacked lock calls


C<Patro> does not export these synchronization functions because
C<lock> and C<wait> are also names for important Perl builtins.

As of v0.16, these synchronization features require that the
server be run on a system that has the C</dev/shm> shared
memory virtual filesystem.


=head1 EXPORTS

C<Patro> exports the L<"patronize"> function, to be used by a server,
and L<"getProxies">, to be used by a client.

The C<:insecure> tag configures the server to allow insecure
operations through a proxy. As of v0.16, this includes calling
C<open> and C<close> on a proxy filehandle, and stealing a lock
(see L<"lock">, above) on a remote reference from another thread.
This tag only affects programs that are serving remote objects.
You can not disable this security, such as it as, in the server
by applying the C<:insecure> tag in a client program.


=head1 ENVIRONMENT

C<Patro> pays attention to the following environment variables.

=head2 PATRO_THREADS

If the environment variable C<PATRO_THREADS> is set, C<Patro> will use
it to determine whether to use a forked server or a threaded server
to provide proxy access to objects. If this variable is not set,
C<Patro> will use threads if the L<threads> module can be loaded.


=head1 LIMITATIONS

The C<-X> file test operations on a proxy filehandle depend on
the file test implementation in L<overload>, which is available
only in Perl v5.12 or better.

When the server uses forks (because threads are unavailable or
because L<"PATRO_THREADS"> was set to a false value), it is less
practical to share variables between processes.
When you manipulate a proxy reference, you are
manipulating the copy of the reference running in a different process
than the remote server. So you will not observe a change in the
reference on the server (unless you use a class that does not save
state in local memory, like L<Forks::Queue>).

The synchronization functions L<Patro::wait|/"wait"> and
L<Patro::notify|/"notify"> seem to require at least version
2.45 of the L<Storable> module.


=head1 DOCUMENTATION AND SUPPORT

Up-to-date (blead version) sources for C<Patro> are on github at
L<https://github.com/mjob/p5-patro>

You can find documentation for this module with the perldoc command.

    perldoc Patro

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

Report bugs and request missing features at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Patro>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Patro>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Patro>

=item * Search CPAN

L<http://search.cpan.org/dist/Patro/>

=back


=head1 LICENSE AND COPYRIGHT

MIT License

Copyright (c) 2017, Marty O'Brien

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
