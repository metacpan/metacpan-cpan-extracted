# -*- perl -*-
#
#  Net::Server::Proto - Net::Server Protocol compatibility layer
#
#  Copyright (C) 2001-2022
#
#    Paul Seamons <paul@seamons.com>
#
#  This package may be distributed under the terms of either the
#  GNU General Public License
#    or the
#  Perl Artistic License
#
#  All rights reserved.
#
################################################################

package Net::Server::Proto;

use strict;
use warnings;
use Socket ();
use Exporter ();
use constant NIx_NOHOST => 1; # The getNameInfo Xtended flags are too difficult to obtain on some older systems,
use constant NIx_NOSERV => 2; # So just hard-code the constant numbers.

my $requires_ipv6 = 0;
my $ipv6_package;
my $can_disable_v6only;
my $exported = {};

BEGIN {
    if (!eval { Socket->import("IPV6_V6ONLY") }) { # Get the actual platform value
        # XXX: Do we have to hard-code magic numbers based on OS for old Perl < 5.14 / Socket < 1.94?
        my $IPV6_V6ONLY = $^O eq 'linux' ? 26 : # XXX: Why is Linux different?
            $^O =~ /^(?:darwin|freebsd|openbsd|netbsd|dragonfly|MSWin32|solaris|svr4)$/ ? 27 : undef; # XXX: Most common
        if ($IPV6_V6ONLY) {
            import constant IPV6_V6ONLY => $IPV6_V6ONLY;
        } else { # XXX: Scrape it from kernel header files? Last ditch effort ugly hack!
            my $d = "/tmp/IP6Cache";
            !eval { require "$d.pl" } and $IPV6_V6ONLY = do { mkdir $d; `h2ph -d $d -a netinet/in.h 2>/dev/null`; eval `grep -rl "sub IPV6_V6ONLY" $d|xargs cat|grep "sub IPV6_V6ONLY";echo "IPV6_V6ONLY()"`} and `rm -rf $d;echo "sub IPV6_V6ONLY{$IPV6_V6ONLY}1">$d.pl`;
        }
        die "IPV6_V6ONLY unknown on this platform: $@" unless defined &IPV6_V6ONLY;
    }
}

sub import {
    my $class = shift;
    my $callpkg = caller;
    # Keep track of who imports any fake stub wrappers
    $exported->{$_}->{$callpkg}=1 foreach @_;
    return Exporter::export($class, $callpkg, @_);
}

our @EXPORT;
our @EXPORT_OK;
BEGIN {
    # If the underlying constant or routine really isn't available in Socket nor Socket6,
    # then it will not die until run-time instead of crashing at compile-time.
    # It can still be caught with eval.
    @EXPORT_OK = qw[
        AF_INET
        AF_INET6
        AF_UNIX
        AF_UNSPEC
        AI_PASSIVE
        INADDR_ANY
        NI_NUMERICHOST
        NI_NUMERICSERV
        NIx_NOHOST
        NIx_NOSERV
        SOCK_DGRAM
        SOCK_STREAM
        SOMAXCONN
        SOL_SOCKET
        SO_TYPE
        IPPROTO_IPV6
        IPV6_V6ONLY
        sockaddr_in
        sockaddr_in6
        sockaddr_family
        inet_ntop
        inet_ntoa
        inet_aton
        getaddrinfo
        getnameinfo
    ];

    # Load just in time once explicitly invoked.
    my $sub = {};
    my $s = sub {
        my @c = caller 1;
        (my $basename = (my $fullname = $c[3])) =~ s/.*:://;
        # Manually run routine if import failed to brick over symbol in local namespace during the last attempt.
        $sub->{$fullname} ? (return $sub->{$fullname}->(@_)) : (die "$fullname: Unable to replace symbol") if exists $sub->{$fullname};
        my @res = ();
        no strict 'refs';
        foreach my $pkg ($ipv6_package,"Socket","Socket6") {
            # Some symbols, such as NI_NUMERICHOST, will not exist until explicitly called via AUTOLOAD
            last if $pkg and eval { @res = &{"$pkg\::$basename"}(@_); $sub->{$fullname} = $pkg->can($basename); };
        }
        if (my $code = $sub->{$fullname}) {
            no warnings qw(redefine prototype); # Don't spew when redefining the stub in the packages that imported it (as well as mine) with the REAL routine
            eval { *{"$_\::$basename"}=$code foreach keys %{$exported->{$basename}}; *$fullname=$code } or warn "$fullname: On-The-Fly replacement failed: $@";
            return @res < 2 && !$c[5] ? $res[0] : @res;
        }
        if ($ipv6_package) {
            $sub->{$fullname} = undef;
            die "$fullname: Failed to locate true symbol even using $ipv6_package at $c[1] line $c[2]\n";
        } else {
            warn "WARNING: Cheater pre-loading IPv6 attempt since non-Socket.pm $fullname called too early at $c[1] line $c[2]\n";
            __PACKAGE__->ipv6_package({}) and $ipv6_package and return &{$basename}(@_);
        }
    };
    foreach my $func (@EXPORT_OK) { eval "sub $func { \$s->(\@_) }" if !defined &$func; }
}
foreach (@EXPORT_OK) { $_ = "safe_$1\_$2" if /^get(....)(info)$/ && defined &{"safe_$1\_$2"}; }

# ($err, $hostname, $servicename) = safe_name_info($sockaddr, [$flags, [$xflags]])
# Compatibility routine to always act like Socket::getnameinfo even if it doesn't exist or if IO::Socket::IP is not available.
# XXX: Why are there two different versions of getnameinfo?
# The old Socket6 only allows for a single option $flags after the $sockaddr input and an error might be the first element. ($host,$sevice)=Socket6::getnameinfo($sockaddr, [$flags])
# The new Socket also allows for an optional $xflags input and always returns its $err as the first element, even on success.
sub safe_name_info {
    return ('IPv6 not ready yet') if !$ipv6_package && !Socket->can("getnameinfo");
    my ($sockaddr, $flags, $xflags) = @_; $flags ||= 0; $xflags ||= 0;
    my @res;
    eval { @res = getnameinfo $sockaddr, $flags, $xflags; 1 } or do { # Force 3-arg input to ensure old version will die: "Usage: Socket6::getnameinfo"
        @res = getnameinfo @_[0,1]; # Probably old Socket6 version, so hide NIx_* $xflags in $_[2]
        @res<2 ? ($res[0]||="EAI_NONAME") : do {
            @res = @res[-3,-2,-1]; $res[0] ||= ""; # Create first $err output element, if doesn't exist.
            $res[NIx_NOHOST] = undef if $xflags | NIx_NOHOST; # Emulate $xflags
            $res[NIx_NOSERV] = undef if $xflags | NIx_NOSERV; # so output matches
        };
    };
    return @res;
}

# ($err, @result) = safe_addr_info($host, $service, [$hints])
# Compatibility routine to always act like Socket::getaddrinfo even if IO::Socket::IP is not available.
# XXX: Why are there two different versions of getaddrinfo?
# The old Socket6 accepts a list of optional hints and returns a multiple of 5 output. (@fiver_chunks)=Socket6::getaddrinfo($node,$port,[$family,$socktype,$proto,$flags])
# The new Socket accepts an optional HASHREF of hints and returns an $err followed by a list of HASHREFs.
sub safe_addr_info {
    return ('IPv6 not ready yet') if !$ipv6_package && !Socket->can("getaddrinfo");
    my ($host, $port, $h) = @_;
    $h ||= {};
    my @res;
    return @res = ('EAI_BADFLAGS: Usage: safe_addr_info($hostname, $servicename, \%hints)') if "HASH" ne ref $h or @_ < 2 or @_ > 3;
    eval { @res = getaddrinfo( $host, $port, $h ); die ($res[0] || "EAI_NONAME") if @res < 2; 1 } # Nice new Socket "HASH" method
    or eval { # Convert Socket6 Old Array "C" method to "HASH" method
        @res = (''); # Pretend like no error so far
        my @results = getaddrinfo( $host, $port, $h->{family}||0, $h->{socktype}||0, $h->{protocol}||0, $h->{flags}||0 );
        while (@results > 4) {
            my $r = {};
            (@$r{qw[family socktype protocol addr canonname]}, @results) = @results;
            push @res, $r;
        }
        $res[0] = "EAI_NONAME" if @res < 2;
        1;
    }
    or $res[0] = ($@ || "getaddrinfo: failed $!");
    return @res;
}

# Capability test function (stolen from IO::Socket::IP in case only IO::Socket::INET6 is available)
sub CAN_DISABLE_V6ONLY {
    return $can_disable_v6only if defined $can_disable_v6only;
    socket my $testsock, AF_INET6, SOCK_STREAM, 0 or die "Cannot socket(PF_INET6) - $!";
    setsockopt $testsock, IPPROTO_IPV6, IPV6_V6ONLY, 0 and return $can_disable_v6only = 1;
    $!{EINVAL} || $!{EOPNOTSUPP} and return $can_disable_v6only = 0; # OpenBSD, WindowsXP, etc
    die "Cannot setsockopt(IPV6_V6ONLY) - $!";
}

sub parse_info {
    my ($class, $port, $host, $proto, $ipv, $server) = @_;

    my $info;
    if (ref($port) eq 'HASH') {
        die "Missing port in hashref passed in port argument.\n" if ! $port->{'port'};
        $info = $port;
    } else {
        $info = {};
        $info->{'unix_type'} = $1
                    if $port =~ s{ (?<=[\w*\]]) [,|\s:/]+ (sock_stream|sock_dgram) \b }{}x; # legacy /some/path|sock_dgram
        $ipv   = $1 if $port =~ s{ (?<=[\w*\]]) [,|\s:/]+ IPv([*\d]+) }{}xi; # allow for 80|IPv*
        $ipv  .= $1 if $port =~ s{ (?<=[\w*\]]) [,|\s:/]+ IPv([*\d]+) }{}xi; # allow for 80|IPv4|IPv6 stacked
        $proto = $1 if $port =~ s{ (?<=[\w*\]]) [,|\s:/]+ (tcp|udp|ssl|ssleay|unix|unixdgram|\w+(?: ::\w+)+) $ }{}xi # allow for 80/tcp or 200/udp or 90/Net::Server::Proto::TCP
                    || $port =~ s{ / (\w+) $ }{}x; # legacy 80/MyTcp support
        $host  = $1 if $port =~ s{ ^ (.*?)      [,|\s:]+  (?= \w+ $) }{}x; # allow localhost:80
        $info->{'port'} = $port;
    }
    $info->{'port'} ||= 0;


    $info->{'host'} ||= (defined($host) && length($host)) ? $host : '*';
    $ipv  = $1 if $info->{'host'} =~ s{ (?<=[\w*\]]) [,|\s:/]+ IPv([*\d]+) }{}xi; # allow for 80|IPv*
    $ipv .= $1 if $info->{'host'} =~ s{ (?<=[\w*\]]) [,|\s:/]+ IPv([*\d]+) }{}xi; # allow for 80|IPv4|IPv6 stacked
    if (     $info->{'host'} =~ m{^ \[ ([\w/.\-:]+ | \*?) \] $ }x) { # allow for [::1] or [host.example.com]
        $info->{'host'} = length($1) ? $1 : '*';
    } elsif ($info->{'host'} =~ m{^    ([\w/.\-:]+ | \*?)    $ }x) {
        $info->{'host'} = $1; # untaint
    } else {
        $server->fatal("Could not determine host from \"$info->{'host'}\"");
    }


    $info->{'proto'} ||= $proto || 'tcp';
    $ipv  = $1 if $info->{'proto'} =~ s{ (?<=[\w*\]]) [,|\s:/]+ IPv([*\d]+) }{}xi; # allow for 80|IPv*
    $ipv .= $1 if $info->{'proto'} =~ s{ (?<=[\w*\]]) [,|\s:/]+ IPv([*\d]+) }{}xi; # allow for 80|IPv4|IPv6 stacked
    if ($info->{'proto'} =~ /^(\w+ (?:::\w+)*)$/x) {
        $info->{'proto'} = $1;
    } else {
        $server->fatal("Could not determine proto from \"$proto\"");
    }
    $proto = lc $info->{'proto'};

    if ($info->{'proto'} =~ /^UNIX/i) {
        return ({%$info, ipv => '*'});
    }
    $ipv = $info->{'ipv'} || $ipv || $ENV{'IPV'} || '';
    $ipv = join '', @$ipv if ref($ipv) eq 'ARRAY';
    $server->fatal("Invalid ipv parameter - must contain 4, 6, or *") if $ipv && $ipv !~ /[46*]/;
    my @_info;
    if (!$ipv || $ipv =~ /[*]/ and eval {CAN_DISABLE_V6ONLY}) {
        my @rows = eval { $class->get_addr_info(@$info{qw(host port proto)}, $server) };
        $server->fatal($@ || "Could not find valid addresses for [$info->{'host'}]:$info->{'port'} with ipv set to '*'") if ! @rows;
        foreach my $row (@rows) {
            my ($host, $port, $ipv, $warn) = @$row;
            push @_info, {host => $host, port => $port, ipv => $ipv, proto => $info->{'proto'}, $warn ? (warn => $warn) : ()};
            $requires_ipv6++ if $ipv ne '4' && $proto ne 'ssl'; # we need to know if Proto::TCP needs to reparent as a child of an IPv6 compatible socket library
        }
        if (@rows > 1 && $rows[0]->[1] == 0) {
            $server->log(2, "Determining auto-assigned port (0) for host $info->{'host'} (prebind)");
            my $sock = $class->object($_info[-1], $server);
            $sock->connect($server);
            @$_{qw(port orig_port)} = ($sock->NS_port, 0) for @_info;
        }
        foreach my $_info (@_info) {
            $server->log(2, "Resolved [$info->{'host'}]:$info->{'port'} to [$_info->{'host'}]:$_info->{'port'}, IPv$_info->{'ipv'}")
                if $_info->{'host'} ne $info->{'host'} || $_info->{'port'} ne $info->{'port'};
            $server->log(2, delete $_info->{'warn'}) if $_info->{'warn'};
        }
    } elsif ($ipv =~ /6/ || $info->{'host'} =~ /:/) {
        push @_info, {%$info, ipv => '6'};
        $requires_ipv6++ if $proto ne 'ssl'; # IO::Socket::SSL does its own determination
        push @_info, {%$info, ipv => '4'} if $ipv =~ /4/ && $info->{'host'} !~ /:/;
    } else {
        push @_info, {%$info, ipv => '4'};
    }

    return @_info;
}

sub get_addr_info {
    my ($class, $host, $port, $proto, $server) = @_;
    $host  = '*'   if ! defined $host;
    $port  = 0     if ! defined $port;
    $proto = 'tcp' if ! defined $proto;
    $server = {}   if ! defined $server;
    return ([$host, $port, '*']) if $proto =~ /UNIX/i;
    $port = (getservbyname($port, $proto))[2] or die "Could not determine port number from host [$host]:$_[2]\n" if $port =~ /\D/;

    my @info;
    if ($host =~ /^\d+(?:\.\d+){3}$/) {
        my $addr = inet_aton($host) or die "Unresolveable host [$host]:$port: invalid ip\n";
        push @info, [inet_ntoa($addr), $port, 4];
    } elsif (eval { $class->ipv6_package($server) }) { # Hopefully IPv6 package has already been loaded by now, if it's available.
        my $proto_id = getprotobyname(lc($proto) eq 'udp' ? 'udp' : 'tcp');
        my $socktype = lc($proto) eq 'udp' ? SOCK_DGRAM : SOCK_STREAM;
        my @res = safe_addr_info($host eq '*' ? '' : $host, $port, { family=>AF_UNSPEC, socktype=>$socktype, protocol=>$proto_id, flags=>AI_PASSIVE });
        my $err = shift @res; die "Unresolveable [$host]:$port: $err\n" if $err or (@res < 1 and $err = "getaddrname: $host: FAILURE!");
        while (my $r = shift @res) {
            my ($err, $ip) = safe_name_info($r->{addr}, NI_NUMERICHOST | NI_NUMERICSERV);
            die "safe_name_info failed on [$host]:$port [$err]\n" if $err || !$ip;
            my $ipv = ($r->{family} == AF_INET) ? 4 : ($r->{family} == AF_INET6) ? 6 : '*';
            push @info, [$ip, $port, $ipv];
        }
        my %ipv6mapped = map {$_->[0] eq '::' ? ('0.0.0.0' => $_) : $_->[0] =~ /^::ffff:(\d+(?:\.\d+){3})$/i ? ($1 => $_) : ()} @info;
        if (keys %ipv6mapped and grep {$ipv6mapped{$_->[0]}} @info) {
            for my $i4 (@info) {
                my $i6 = $ipv6mapped{$i4->[0]} or next;
                if (!eval{$ipv6_package->new(LocalAddr=>$i6->[0],Type=>$socktype)}) {
                    $i4->[3] = "Host [$host] resolved to IPv6 address [$i6->[0]] but $ipv6_package->new fails: $@";
                    $i6->[0] = '';
                } elsif ($i6->[2] eq '6' and eval {CAN_DISABLE_V6ONLY}) { # If IPv* can bind to both, upgrade '6' to '*', and disable the corresponding '4' entry
                    $i6->[3] = "Not including resolved host [$i4->[0]] IPv4 because it will be handled by [$i6->[0]] IPv6";
                    $i6->[2] = '*';
                    $i4->[0] = '';
                }
            }
            @info = grep {length $_->[0]} @info;
        }
    } elsif ($host =~ /:/) {
        die "Unresolveable host [$host]:$port - could not load IPv6: $@";
    } else {
        my @addr;
        if ($host eq '*') {
            push @addr, INADDR_ANY;
        } else {
            (undef, undef, undef, undef, @addr) = gethostbyname($host);
            die "Unresolveable host [$host]:$port via IPv4 gethostbyname\n" if !@addr;
        }
        push @info, [inet_ntoa($_), $port, 4] for @addr
    }

    return @info;
}

sub object {
    my ($class, $info, $server) = @_;
    my $proto_class = $info->{'proto'};
    if ($proto_class !~ /::/) {
        $server->fatal("Invalid proto class \"$proto_class\"") if $proto_class !~ /^\w+$/;
        $proto_class = "Net::Server::Proto::" .uc($proto_class);
    }
    (my $file = "${proto_class}.pm") =~ s|::|/|g;
    $server->fatal("Unable to load module for proto \"$proto_class\": $@") if ! eval { require $file };
    return $proto_class->object($info, $server);
}

sub requires_ipv6 { $requires_ipv6 ? 1 : undef }

sub ipv6_package {
    my ($class, $server) = @_;
    return $ipv6_package if $ipv6_package;
    return undef if $ENV{'NO_IPV6'};

    my $pkg = $server->{'server'}->{'ipv6_package'};
    if ($pkg) {
        (my $file = "$pkg.pm") =~ s|::|/|g;
        eval { require $file } or $server->fatal("Could not load ipv6_package $pkg: $@");
    } elsif ($INC{'IO/Socket/IP.pm'}) { # already loaded
        $pkg = 'IO::Socket::IP';
    } elsif ($INC{'IO/Socket/INET6.pm'}) {
        $pkg = 'IO::Socket::INET6';
    } elsif (eval { require IO::Socket::IP }) {
        $pkg = 'IO::Socket::IP';
    } else {
        my $err = $@;
        if (eval { require IO::Socket::INET6 }) {
            $pkg = 'IO::Socket::INET6';
        } else {
            die "Port configuration using IPv6 could not be started.  Could not find or load IO::Socket::IP or IO::Socket::INET6:\n  $err  $@"
        }
    }
    return $ipv6_package = $pkg;
}

1;

__END__

=head1 NAME

Net::Server::Proto - Net::Server Protocol compatibility layer

=head1 SYNOPSIS

    NOTE: Beginning in Net::Server 2.005, the default value for
          ipv is IPv* meaning that if no host is passed, or a
          hostname is passed, all available socket types will be
          bound.  You can force IPv4 only by adding an ipv => 4
          configuration in any of the half dozen ways we let you
          specify it.

    NOTE: For IPv6 Net::Server will first try and use the module
          listed in server config ipv6_package, then IO::Socket::IP,
          then IO::Socket::INET6 (which is deprecated).

    # Net::Server::Proto and its accompanying modules are not
    # intended to be used outside the scope of Net::Server.

    # That being said, here is how you use them.  This is
    # only intended for anybody wishing to extend the
    # protocols to include some other set (ie maybe a
    # database connection protocol)

    use Net::Server::Proto;

    my @info = Net::Server::Proto->parse_info(
        $port,            # port to connect to
        $default_host,    # host to use if none found in port
        $default_proto,   # proto to use if none found in port
        $default_ipv,     # default of IPv6 or IPv4 if none found in port
        $server_obj,      # Net::Server object
    );

    my @raw_info = Net::Server::Proto->get_addr_info($host, $port, $proto, $server_obj);
    # returns arrayref of resolved ips, ports, and ipv values

    my $sock = Net::Server::Proto->object({
        port  => $port,
        host  => $host,
        proto => $proto,
        ipv   => $ipv, # * (IPv*) if false (default false)
    }, $server);

    # Net::Server::Proto will attempt to interface with
    # sub modules named similar to Net::Server::Proto::TCP
    # Individual sub modules will be loaded by
    # Net::Server::Proto as they are needed.

    use Net::Server::Proto::TCP; # or UDP or UNIX etc

    # Return an object which is a sub class of IO::Socket
    # At this point the object is not connected.
    # The method can gather any other information that it
    # needs from the server object.
    my $sock = Net::Server::Proto::TCP->object({
        port  => $port,
        host  => $host,
        proto => $proto,
        ipv   => 6, # IPv6 - default is * - can also be '4'
    }, $server);


    # Log that a connection is about to occur.
    # Use the facilities of the passed Net::Server object.
    $sock->log_connect( $server );

    # Actually bind to port or socket file.  This
    # is typically done by calling the configure method.
    $sock->connect();

    # Allow for rebinding to an already open fileno.
    # Typically will just do an fdopen.
    $sock->reconnect();

    ### Return a unique identifying string for this sock that
    # can be used when reconnecting.
    my $str = $sock->hup_string();

    # Return the proto that is being used by this module.
    my $proto = $sock->NS_proto();


=head1 DESCRIPTION

Net::Server::Proto is an intermediate module which returns IO::Socket
style objects blessed into its own set of classes (ie
Net::Server::Proto::TCP, Net::Server::Proto::UNIX).

Only three or four protocols come bundled with Net::Server.  TCP, UDP,
UNIX, UNIXDGRAM, and SSLEAY.  TCP is an implementation of SOCK_STREAM
across an INET socket.  UDP is an implementation of SOCK_DGRAM across
an INET socket.  UNIX uses a unix style socket file with the
SOCK_STREAM protocol.  UNIXGRAM uses a unix style socket file with the
SOCK_DGRAM protocol.  SSLEAY is actually just a layer on top of TCP
but uses Net::SSLeay to read and write from the stream.

The protocol that is passed to Net::Server can be the name of another
module which contains the protocol bindings.  If a protocol of
MyServer::MyTCP was passed, the socket would be blessed into that
class.  If Net::Server::Proto::TCP was passed, it would get that
class.  If a bareword, such as tcp, udp, unix, unixdgram or ssleay, is
passed, the word is uppercased, and post pended to
"Net::Server::Proto::" (ie tcp = Net::Server::Proto::TCP).

=head1 METHODS

Protocol names used by the Net::Server::Proto should be sub classes of
IO::Socket.  These classes should also contain, as a minimum, the
following methods should be provided:

=over 4

=item object

Return an object which is a sub class of IO::Socket At this point the
object is not connected.  The method can gather any other information
that it needs from the server object.  Arguments are default_host,
port, and a Net::Server style server object.

=item log_connect

Log that a connection is about to occur.  Use the facilities of the
passed Net::Server object.  This should be an informative string
explaining which properties are being used.

=item connect

Actually bind to port or socket file.  This is typically done
internally by calling the configure method of the IO::Socket super
class.

=item reconnect

Allow for rebinding to an already open fileno.  Typically will just do
an fdopen using the IO::Socket super class.

=item hup_string

Return a unique identifying string for this sock that can be used when
reconnecting.  This is done to allow information including the file
descriptor of the open sockets to be passed via %ENV during an exec.
This string should always be the same based upon the configuration
parameters.

=item NS_port

Net::Server protocol.  Return the port that is being used by this
module.  If the underlying type is UNIX then port will actually be
the path to the unix socket file.

=item NS_host

Net::Server protocol.  Return the protocol that is being used by this
module.  This does not have to be a registered or known protocol.

=item NS_proto

Net::Server protocol.  Return the protocol that is being used by this
module.  This does not have to be a registered or known protocol.

=item show

Similar to log_connect, but simply shows a listing of which
properties were found.  Can be used at any time.

=back

=head1 HOST

The hostname may be either blank, '*', be an IPv4 address, an IPv6 address,
a bare hostname, or a hostname with IPv* specifications.

    host => "127.0.0.1",  # an IPv4 address

    host => "::1",        # an IPv6 address

    host => 'localhost',  # addresses returned by localhost (default IPv* - IPv4 and/or IPv6)

    host => 'localhost/IPv*',  # same

    ipv  => '*',
    host => 'localhost',  # same

    ipv  => 6,
    host => 'localhost',  # addresses returned by localhost (IPv6)

    ipv  => 'IPv4 IPv6',
    host => 'localhost',  # addresses returned by localhost (requires IPv6 and IPv4)


    host => '*',          # any local interfaces (default IPv*)

    ipv  => '*',
    host => '*',          # any local interfaces (any IPv6 or IPv4)

    host => '*/IPv*',     # same

=head1 IPV

In addition to being able to specify IPV as a separate parameter, ipv may
also be passed as a part of the host, as part of the port, as part of the protocol
or may be specified via $ENV{'IPV'}.  The order of precedence is as follows:

     1) Explicit IPv4 or IPv6 address - wins
     2) ipv specified in port
     3) ipv specified in host
     4) ipv specified in proto
     5) ipv specified in default settings
     6) ipv specified in $ENV{'IPV'}
     7) default to IPv*

=head1 PORT

The port is the most important argument passed to the sub
module classes and to Net::Server::Proto itself.  For tcp,
udp, and ssleay style ports, the form is generally host:port/protocol,
[host]:port/protocol, host|port|protocol, host/port, or port.
If I<host> is a numerical IPv6 address it should be enclosed in square
brackets to avoid ambiguity in parsing a port number, e.g.: "[::1]:80".
Separating with spaces, commas, or pipes is also allowed, e.g. "::1, 80".
For unix sockets the form is generally socket_file|unix or socket_file.

To help overcome parsing ambiguity, it is also possible to pass port as
a hashref (or as an array of hashrefs) of information such as:

    port => {
        host  => "localhost",
        ipv   => 6, # could also pass IPv6 (* is default)
        port  => 20203,
        proto => 'tcp',
    }

If a hashref does not include host, ipv, or proto - it will use the default
value supplied by the general configuration.

A socket protocol family PF_INET or PF_INET6 is derived from a specified
address family of the binding address. A PF_INET socket can only accept
IPv4 connections. A PF_INET6 socket accepts IPv6 connections, but may also
accept IPv4 connections if ipv is '*' or 'v4v6'. For example, binding to
host [::] can accept IPv4 or IPv6 connections.

The Net::Server::Proto::object method returns a list of objects corresponding
to created sockets. For Unix and INET sockets the list typically contains
just one element, but may return multiple objects when multiple protocol
families are allowed or when a host name resolves to multiple local
binding addresses.  This is particularly true when an ipv value of '*' is
passed in allowing hostname resolution.

You can see what Net::Server::Proto parsed out by looking at
the logs to see what log_connect said.  You could also include
a post_bind_hook similar to the following to debug what happened:

    sub post_bind_hook {
        my $self = shift;
        foreach my $sock ( @{ $self->{server}->{sock} } ){
            $self->log(2,$sock->show);
        }
    }

Rather than try to explain further, please look at the following
examples:

    # example 1 #----------------------------------

    $port      = "20203";
    $def_host  = "default-domain.com";
    $def_proto = undef;
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => 'default-domain.com',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => *, # IPv*
    # };

    # example 2 #----------------------------------

    $port      = "someother.com:20203";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => 'someother.com',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => *,
    # };

    # example 3 #----------------------------------

    $port      = "someother.com:20203/udp";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => 'someother.com',
    #     port  => 20203,
    #     proto => 'udp', # will use Net::Server::Proto::UDP
    #     ipv   => *,
    # };

    # example 4 #----------------------------------

    $port      = "someother.com:20203/Net::Server::Proto::UDP";
    $def_host  = "default-domain.com";
    $def_proto = "TCP";
    $def_ipv   = 4;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => 'someother.com',
    #     port  => 20203,
    #     proto => 'Net::Server::Proto::UDP',
    #     ipv   => 4,
    # };

    # example 5 #----------------------------------

    $port      = "someother.com:20203/MyObject::TCP";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto);
    # @info = {
    #     host  => 'someother.com',
    #     port  => 20203,
    #     proto => 'MyObject::TCP',
    # };

    # example 6 #----------------------------------

    $port      = "/tmp/mysock.file|unix";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => '*', # irrelevant for UNIX socket
    #     port  => '/tmp/mysock.file', # not really a port
    #     proto => 'unix', # will use Net::Server::Proto::UNIX
    #     ipv   => '*', # irrelevant for UNIX socket
    # };

    # example 7 #----------------------------------

    $port      = "/tmp/mysock.file|unixdgram";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => '*', # irrelevant for UNIX socket
    #     port  => '/tmp/mysock.file', # not really a port
    #     proto => 'unixdgram', # will use Net::Server::Proto::UNIXDGRAM
    #     ipv   => '*', # irrelevant for UNIX socket
    # };

    # example 8 #----------------------------------

    $port      = "/tmp/mysock.file|SOCK_STREAM|unix"; # legacy
    $def_host  = "";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => '*', # irrelevant for UNIX socket
    #     port  => '/tmp/mysock.file', # not really a port
    #     proto => 'unix', # will use Net::Server::Proto::UNIX
    #     unix_type => 'SOCK_STREAM',
    #     ipv   => '*', # irrelevant for UNIX socket
    # };

    # example 9 #----------------------------------

    $port      = "/tmp/mysock.file|SOCK_DGRAM|unix"; # legacy
    $def_host  = "";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => '*', # irrelevant for UNIX socket
    #     port  => '/tmp/mysock.file', # not really a port
    #     proto => 'unix', # will use Net::Server::Proto::UNIXDGRAM
    #     unix_type => 'SOCK_DGRAM',
    #     ipv   => '*', # irrelevant for UNIX socket
    # };

    # example 10 #----------------------------------

    $port = "someother.com:20203/ssleay";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => 'someother.com',
    #     port  => 20203,
    #     proto => 'ssleay', # will use Net::Server::Proto::SSLEAY
    #     ipv   => *,
    # };

    # example 11 #----------------------------------

    $port = "[::1]:20203 ipv6 tcp";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => '::1',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => 6,
    # };

    # example 12 #----------------------------------

    $port = "[::1]:20203 tcp";
    $def_host  = "default-domain.com/IPv6";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = {
    #     host  => '::1',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => 6,
    # };

    # example 13 #----------------------------------

    $port = "[someother.com]:20203 ipv6 ipv4 tcp";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = ({
    #     host  => 'someother.com',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => 4,
    # }, {
    #     host  => 'someother.com',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => 6,
    # });

    # example 14 #----------------------------------

    # depending upon your configuration
    $port = "localhost:20203";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = ({
    #     host  => '127.0.0.1',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => 4, # IPv4
    # }, {
    #     host  => '::1',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => 6, # IPv6
    # });

    # example 15 #----------------------------------

    # depending upon your configuration
    $port = "localhost:20203";
    $def_host  = "default-domain.com IPv*";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = ({
    #     host  => '127.0.0.1',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => 4, # IPv4
    # }, {
    #     host  => '::1',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => 6, # IPv6
    # });

    # example 16 #----------------------------------

    # depending upon your configuration
    $ENV{'IPV'} = '4';
    $port = "localhost:20203";
    $def_host  = "default-domain.com";
    $def_proto = "tcp";
    $def_ipv   = undef;
    @info = Net::Server::Proto->parse_info($port,$def_host,$def_proto,$def_ipv);
    # @info = ({
    #     host  => '127.0.0.1',
    #     port  => 20203,
    #     proto => 'tcp', # will use Net::Server::Proto::TCP
    #     ipv   => 4, # IPv4
    # });

=head1 LICENCE

Distributed under the same terms as Net::Server

=cut
