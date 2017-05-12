#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

# looking forward Net::Server...

package ServBase;
use strict;

use vars qw($VERSION);

use Data::Hexdumper;
use POSIX;
use IO::Select;
use IO::Socket;
use P2P::pDonkey::Packet ':all';
use P2P::pDonkey::Util ':all';

use constant CS_CONNECTING  => 1;
use constant CS_ACTIVE      => 2;
use constant CS_CLOSED      => 3;
use constant CS_PROXY       => 4;

sub new {
    my $class = shift;
    my %opt = @_;

    my %connections;
    tie %connections, "Tie::RefHash";
#    my $selRead  = new IO::Select;
#    my $selWrite = new IO::Select;

    $opt{SelRead}   = new IO::Select;
    $opt{SelWrite}  = new IO::Select;
    $opt{CONN}      = \%connections;
    $opt{Log} || ($opt{Log} = \&Log);
    my $self = \%opt;

    bless($self, $class);
    return $self;
}

sub connections {
    my $self = shift;
    return $self->{CONN};
}

sub stop {
    my $self = shift;
    $self->{STOP} = 1;
}

sub watch {
    my $self = shift;
    my ($sock) = @_;
    $self->{SelRead}->add($sock);
}

sub unwatch {
    my $self = shift;
    my ($sock) = @_;
    $self->{SelRead}->remove($sock);
}

sub ProcessPacket {
    my $self = shift;
    my ($conn) = @_;

    my ($data, $up, $pp);
    $data = \$conn->{RBuffer};

    my $pt = unpack('C', $$data);
    my $pname = PacketTagName($pt);
    $pname = "Unknown" if !$pname;
    $self->{Log}->($conn, sprintf("-> %s(%x) [%d]\n", $pname, $pt, $conn->{PLength} + SZ_TCP_HEADER));
    print hexdump(data => $conn->{Header} . $$data) if $self->{Dump};

    my @d;
    my $off = 0;
    $pp = $self->{ProcTable}->[$pt];
    
    if (!($pp && (@d = unpackBody(\$pt, $$data, $off)))) {
        if ($pp) {
            $self->{Log}->($conn, "\tdropped: incorrect packet format\n"); 
        } else {
            $self->{Log}->($conn, "\tdropped: no processing function\n"); 
        }
        return;
    }

    if ($off != length($$data)) {
        $self->{Log}->($conn, ": there are left ", length($$data)-$off, 
                       " unpacked bytes in packet\n");
    }

    &$pp($conn, @d);
}

sub AddSocket {
    my $self = shift;
    my ($sock, $addr, $port) = @_;

    my %rec = (
        Socket => $sock,
        IP => addr2ip($addr), Addr => $addr, Port => $port, 
        # read buffer
        RBuffer => '', RLength => 0, 
        PLength => undef, Header => '', Protocol => undef,
        # write buffer
        WBuffer => '', WLength => 0
    );

    $self->{CONN}->{$sock} = \%rec;
    return \%rec;
}

# incoming connection, we will wait for hello
sub Connected {
    my $self = shift;
    my ($sock) = @_;

    my ($other_end, $port, $iaddr, $addr);

    $other_end      = getpeername($sock)
        || warn "Couldn't identify other end: $!\n" && return;
    ($port, $addr)  = unpack_sockaddr_in($other_end);
    $addr = inet_ntoa($addr);

    my $conn = $self->AddSocket($sock, $addr, $port);
    $self->{SelRead}->add($sock);

    $conn->{State} = CS_ACTIVE;
    $self->{Log}->($conn, "=> CONNECTED client at $self->{LocalPort}\n");
    $self->{OnClientConnect} && $self->{OnClientConnect}->($conn);
    return $conn;
}

# outgoing connection, should send hello
sub Connect {
    my $self = shift;
    my ($addr, $port) = @_;

    my ($sock, $err, $state);

    $self->{Log}->(undef, "connecting to $addr:$port\n");
    if ($self->{ProxyAddr}) {
        $sock = new IO::Socket::INET(PeerAddr => $self->{ProxyAddr},
                                     PeerPort => $self->{ProxyPort},
                                     Proto => 'tcp',
                                     Blocking => 0);
        if (!$sock) {
            warn "Failed connect to proxy!\n";
            return;
        }
        $state = CS_PROXY;
    } else {
        $sock = new IO::Socket::INET(PeerAddr => $addr,
                                     PeerPort => $port,
                                     Proto => 'tcp',
                                     Blocking => 0)
            || return;
        $state = CS_CONNECTING;
    }

    my $conn = $self->AddSocket($sock, $addr, $port);
    $self->{SelRead}->add($sock);
    $self->{SelWrite}->add($sock);
    $conn->{State} = $state;
    return $conn;
}

sub Disconnect {
    my $self = shift;
    my ($sock) = @_;

    $self->{SelRead}->remove($sock);
    $self->{SelWrite}->remove($sock);
    $sock->shutdown(2);

    my $conn = $self->{CONN}->{$sock};
    $self->{Log}->($conn, "== DISCONNECTED\n");
    $conn->{State} = CS_CLOSED;
    delete $self->{CONN}->{$sock};

    $self->{OnDisconnect} && $self->{OnDisconnect}->($conn);
}

sub Queue {
    my $self = shift;
    my ($conn, $pt) = (shift, shift);
   
    my ($body, $data, $dlen);
    $body = packBody($pt, @_);
    $data = packTCPHeader($dlen = length $body) . $body;
    $dlen += SZ_TCP_HEADER;

    my $class;
    if ($conn && ($conn eq 'Client' || $conn eq 'Server' || $conn eq 'Admin')) {
        $class = $conn;
        $conn = undef;
    }
    
    my @whom = $conn ? ($conn) : values %{$self->{CONN}};

    my $is_dest = 0;
    foreach $conn (@whom) {
        next if $conn->{Socket}->sockopt(SOL_SOCKET, SO_ERROR);
        next if $class && !$conn->{$class};

        $conn->{WBuffer} .= $data;
        $conn->{WLength} += $dlen;
        $self->{SelWrite}->add($conn->{Socket});

        my $pname = PacketTagName($pt) || "Unknown";
        $self->{Log}->($conn, sprintf("<- %s(%x) [%d]\n", $pname, $pt, $dlen));
        $is_dest = 1;
    }

    print hexdump(data => $data) if $is_dest && $self->{Dump};
}

sub MainLoop {
    my $self = shift;

    my $selRead = $self->{SelRead};
    my $selWrite = $self->{SelWrite};

    my ($server, $admin);
    if ($self->{LocalPort}) {
        $server = new IO::Socket::INET(LocalPort => $self->{LocalPort}, 
                Listen    => $self->{MaxClients} || 5, 
                Reuse     => 1,
                Blocking  => 0)
            or return;
        $selRead->add($server);
    }
    if ($self->{AdminPort}) {
        $admin = new IO::Socket::INET(LocalPort => $self->{AdminPort}, 
                Listen    => 1,
                Reuse     => 1,
                Blocking  => 0)
            or return;
        $selRead->add($admin);
    }

    $self->{Log}->(undef, "Ready\n");

    my ($rready, $wready, $h, $conn, $err);
    my ($data, $dlen, $plen, $len);

    while (!$self->{STOP}) {

#        print "Select\n";
        ($rready, $wready) = IO::Select->select($selRead, $selWrite, undef);

        foreach $h (@$wready) {
#            print "Write\n";
            $self->{CanWriteHook} && $self->{CanWriteHook}->($h) && next;

            $conn = $self->{CONN}->{$h};
            next if $conn->{State} == CS_CLOSED;

            next if !$conn;
            $err = $h->sockopt(SOL_SOCKET, SO_ERROR);
            if ($err) {
                $self->Disconnect($h) unless $err == EINPROGRESS;
                next;
            }

            if ($conn->{State} == CS_PROXY) {
                my $proxy_req = "CONNECT $conn->{Addr}:$conn->{Port} HTTP/1.1\n"
                    . "Pragma: no-cache\n"
                    . "Cache-Control: no-cache\n"
                    . "Connection: Keep-Alive\n"
                    . "Proxy-Connection: Keep-Alive\n"
                    . "User-Agent: Mozilla/4.0 (compatible; MSIE 5.01; Windows NT; Hotbar 2.0)\n"
                    . "\n";
                $len = syswrite($h, $proxy_req, length $proxy_req);
                if (!$len || $len != length $proxy_req) {
                    $self->{Log}->($conn, "proxy traversal failed\n");
                    $self->Disconnect($h);
                    next;
                }
                $selWrite->remove($h);
            }

            if ($conn->{State} == CS_CONNECTING) {
                $conn->{State} = CS_ACTIVE;
                $self->{Log}->($conn, "<= CONNECTED\n");
                $self->{OnConnect} && $self->{OnConnect}->($conn);
                next;
            }

            ($data, $dlen) = (\$conn->{WBuffer}, \$conn->{WLength});
            if ($$dlen) {
                $len = syswrite($h, $$data, $$dlen);
                if (!$len) {
                    $self->Disconnect($h);
                    next;
                }
                if ($len > 0) {
                    $$data = unpack("x$len a*", $$data);
                    $$dlen -= $len;
                }
            }
            $$dlen || $selWrite->remove($h);
        }

        foreach $h (@$rready) {
#            print "Read\n";

            if ($server && $h == $server) {
                $h = $server->accept();
                $conn = $self->Connected($h) or next;
                $conn->{Client} = 1;
            }
            if ($admin && $h == $admin) {
                $h = $admin->accept();
                $conn = $self->Connected($h) or next;
                $conn->{Admin} = 1;
            }

            $self->{CanReadHook} && $self->{CanReadHook}->($h) && next;

            $conn = $self->{CONN}->{$h};
            next if $conn->{State} == CS_CLOSED;

            next if !$conn;
            $err = $h->sockopt(SOL_SOCKET, SO_ERROR);
            if ($err) {
                $self->Disconnect($h) unless $err == EINPROGRESS;
                next;
            }

            if ($conn->{State} == CS_PROXY) {
                my $proxy_ans;
                $len = sysread($h, $proxy_ans, 1024);
#                print "$proxy_ans";
                if (!$len) {
                    $self->{Log}->($conn, "proxy traversal failed (can't read answer)\n");
                    $self->Disconnect($h);
                    next;
                }
                if ($proxy_ans =~ /HTTP\/\S+ (\d+)/) {
                    if (int($1 / 100) != 2) {
                        $self->{Log}->($conn, "proxy traversal failed (code $1)\n");
                        $self->Disconnect($h);
                        next;
                    }
                    $conn->{State} = CS_CONNECTING;
                } else {
                    $self->{Log}->($conn, "proxy traversal failed (can't parse answer)\n");
                    $self->Disconnect($h);
                    next;
                }
            }
            if ($conn->{State} == CS_CONNECTING) {
                $conn->{State} = CS_ACTIVE;
                $self->{Log}->($conn, "<= CONNECTED\n");
                $self->{OnConnect} && $self->{OnConnect}->($conn);
                next;
            }

            ($data, $dlen, $plen) = (\$conn->{RBuffer}, \$conn->{RLength}, \$conn->{PLength});
            if (!$$plen) {
                # try to read header
                $len = sysread($h, $$data, SZ_TCP_HEADER-$$dlen, $$dlen);
                if (!$len) {
                    $self->Disconnect($h);
                    next;
                }
                $$dlen += $len;
                if ($$dlen == SZ_TCP_HEADER)
                {
                    my ($prot, $npl) = unpack('CL', $$data);
                    if ($prot == PT_HEADER)
                    {
                        $conn->{Header}   = $$data;
                        $conn->{Protocol} = $prot;
                        $$plen            = $npl;
                    }
                    ($$data, $$dlen) = ('', 0);
                }
            }
            if ($$plen) {
                # try to read packet
                $len = sysread($h, $$data, $$plen-$$dlen, $$dlen);
                if (!$len) {
                    $self->Disconnect($h);
                    next;
                }
                $$dlen += $len;
                if ($$dlen == $$plen) {
                    $self->ProcessPacket($conn);
                    ($$data, $$dlen, $$plen) = ('', 0, undef);
                }
            }
        }
    }
}

sub Log {
    my $conn = shift;
#    print strftime "%b %e %H:%M:%S ", gmtime;
    print "$conn->{Addr}:$conn->{Port} " if $conn;
    print @_;
}

1;
