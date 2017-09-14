package Patro;
use strict;
use warnings;
use Patro::LeumJelly;
use Scalar::Util;
use Data::Dumper;
use Socket ();
use Carp;
use base 'Exporter';
our @EXPORT = qw(patronize getProxies);

our $VERSION = '0.14';

BEGIN {
    if (defined &CORE::read) {
	*CORE::GLOBAL::read = sub (*\$$;$) {
	    $Patro::read_sysread_flag = 'read';
	    goto &CORE::read if defined &CORE::read;
	};
	*CORE::GLOBAL::sysread = sub (*\$$;$) {
	    $Patro::read_sysread_flag = 'sysread';
	    goto &CORE::sysread if defined &CORE::sysread;
	};
    } else {
	$Patro::read_sysread_flag = 'read?';
    }
    *CORE::GLOBAL::ref = \&Patro::ref;
    *CORE::GLOBAL::truncate = \&Patro::_truncate;
    *CORE::GLOBAL::stat = \&Patro::_stat;
    *CORE::GLOBAL::flock = \&Patro::_flock;
    *CORE::GLOBAL::fcntl = \&Patro::_fcntl;

    *CORE::GLOBAL::sysopen = \&Patro::_sysopen;
    *CORE::GLOBAL::lstat = \&Patro::_lstat;

    *CORE::GLOBAL::opendir = \&Patro::_opendir;
    *CORE::GLOBAL::closedir = \&Patro::_closedir;
    *CORE::GLOBAL::readdir = \&Patro::_readdir;
    *CORE::GLOBAL::seekdir = \&Patro::_seekdir;
    *CORE::GLOBAL::telldir = \&Patro::_telldir;
    *CORE::GLOBAL::rewinddir = \&Patro::_rewinddir;
    *CORE::GLOBAL::chdir = \&Patro::_chdir;
}

sub import {
    my ($class, @args) = @_;
    my @tags = grep /^:/, @args;
    @args = grep !/^:/, @args;
    $Patro::SECURE = 1;
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
	    $Patro::SECURE = 0;
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
    return _fetch($handle, "ref");
}

sub reftype {
    my $ref = CORE::ref($_[0]);
    if (!Patro::LeumJelly::isProxyRef($ref)) {
	return Scalar::Util::reftype($_[0]);
    }
    my $handle = Patro::LeumJelly::handle($_[0]);
    return _fetch($handle, "reftype");
}

sub _allrefs {
    return (CORE::ref($_[0]), Patro::ref($_[0]),
	    Scalar::Util::reftype($_[0]), Patro::reftype($_[0]));
}

sub client {
    if (!Patro::LeumJelly::isProxyRef(CORE::ref($_[0]))) {
	return;     # not a remote proxy object
    }
    return _fetch(Patro::LeumJelly::handle($_[0]),"client");
}

sub _fetch {
    # _fetch HASH, LIST
    #     where HASH is an object that overloads the '%{}' 
    #     operator, temporarily unbless it, fetch values for
    #     one or more keys, and restore the original blessing.
    #     Returns the retrieved values.
    
    my ($hash, @keys) = @_;
    my $ref = CORE::ref($hash);
    my @r;
    if (!$ref) {
	@r = @{$hash}{@keys};
    } else {
	bless $hash, '###';
	@r = @{$hash}{@keys};
	bless $hash, $ref;
    }
    return wantarray ? @r : @r > 0 ? $r[-1] : undef;
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

sub _truncate {
    my ($fh,$len) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	return $fh->_tied->__('TRUNCATE',1,$len);
    } else {
	return CORE::truncate($fh,$len);
    }
}

sub _fcntl {
    my ($fh,$func,$scalar) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	return $fh->_tied->__('FCNTL',1,$func,$scalar);
    } else {
	return CORE::fcntl($fh,$func,$scalar);
    }
}

sub _stat {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	my $context = defined(wantarray) + wantarray + 0;
	return $fh->_tied->__('STAT',$context);
    } else {
	return CORE::stat $fh;
    }
}

sub _flock {
    my ($fh,$op) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	return $fh->_tied->__('FLOCK',1,$op);
    } else {
	return CORE::flock($fh,$op);
    }
}

sub _sysopen {
    my ($fh,$fname,$mode,$perm) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('SYSOPEN',1,$fname,$mode,$perm);
    } elsif (defined ($perm)) {
        return CORE::sysopen($fh,$fname,$mode,$perm);
    } else {
        return CORE::sysopen($fh,$fname,$mode);
    }
}

sub _lstat (;*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
	my $context = defined(wantarray) + wantarray + 0;
	return $fh->_tied->__('LSTAT',$context);
    }
    return CORE::lstat $fh;
}

sub _opendir (*$) {
    if (CORE::ref($_[0]) eq 'Patro::N5') {
        return $_[0]->_tied->__('OPENDIR',1,$_[1]);
    }
    return CORE::opendir($_[0],$_[1]);
}

sub _closedir (*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('CLOSEDIR',1);
    }
    return CORE::closedir($fh);
}

sub _readdir (*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('READDIR',undef);
    }
    return CORE::readdir($fh);
}

sub _seekdir (*$) {
    my ($fh,$pos) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('SEEKDIR',1,$pos);
    }
    return CORE::seekdir($fh,$pos);
}

sub _telldir (*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('TELLDIR',1);
    }
    return CORE::telldir($fh);
}

sub _rewinddir (*) {
    my ($fh) = @_;
    if (CORE::ref($fh) eq 'Patro::N5') {
        return $fh->_tied->__('REWINDDIR',1);
    }
    return CORE::rewinddir($fh);
}

sub _chdir (;$) {
    my ($fh) = @_;
    if ($fh && CORE::ref($fh) eq 'Patro::N5') {
	return $fh->_tied->__('CHDIR',1);
    }
    return CORE::chdir($fh);
}

1;

=head1 NAME

Patro - proxy access to remote objects


=head1 VERSION

0.14


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
