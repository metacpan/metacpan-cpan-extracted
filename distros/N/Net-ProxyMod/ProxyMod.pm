#
# Copyright (c) 2001,2003,2004 Stephanie Wehner <_@r4k.net>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the company ITSX nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Small tcp proxy package for packet(payload) alteration/debugging.
#
# $Id: ProxyMod.pm,v 1.3 2003/09/23 15:07:32 _ Exp $
#

package Net::ProxyMod;

use strict;
use vars qw($VERSION);
use POSIX ":sys_wait_h";
use Carp;

use IO::Socket;
use IO::Select;

$VERSION = '0.04';

my $do_debug = 0;

my @parnames = qw/
-local_host
-local_port
-remote_host
-remote_port
-debug
/;


# create a new proxy object
sub new
{
    my($caller) = shift;
    my($class)  = ref($caller) || $caller;

    my $self = {};

    bless($self, $class);

    # set defaults, for form
    $self->{-mode} = "forking";

    # initialize the proxy object
    $self->_init(@_);

    return($self);
}


# initialize
sub _init
{
    my $self = shift;

    # care for unnamed and named params
    my $i = 0;
    while (($_[0] !~ /^-/) && ($i < 5)) {
       $self->{$parnames[$i]} = shift;
       $i++;
    }
    my %named = @_;
    $self->{$_} = $named{$_} for keys(%named);

    # check if we need root
    if($self->{-local_port} < 1024 ) {
        croak "Need to be root to create a socket with port < 1024.";
    }

    $do_debug = $self->{-debug};

    # setup the proxy socket
    $self->{MAIN} = IO::Socket::INET->new(
        LocalAddr => $self->{-local_host},
        LocalPort => $self->{-local_port},
        Listen    => Socket::SOMAXCONN,
        ReuseAddr => 1,
        Proto => 'tcp',
    ) or croak "Can't open socket: $!\n";

    _debug(
       "Started server at ",
       $self->{-local_host},
       ":",
       $self->{-local_port},
    );

    # set autoflush
    $self->{MAIN}->autoflush(1);

    if ( $self->{-mode} eq 'nonforking' ) {

        require Tie::RefHash;

        # setup a lookup hash
        tie my %lookup, 'Tie::RefHash'
            or croak "couldn't tie lookup hash";
        $self->{LOOKUP} = \%lookup;

        # setup IO::Select object
        $self->{ALLSOCKS} = IO::Select->new;
        $self->{ALLSOCKS}->add($self->{MAIN});
    }

    return;
}


# handle client connections (this is similar to fwdport
# in the perl coobook in some ways)
sub get_conn
{
    my $self = shift;
    my($infunc, $outfunc) = @_;

    my $func = $self->{-mode} eq 'nonforking' ?
        \&_nonforking
        :
        \&_forking;

    $func->($self, $infunc, $outfunc);
}


# handle forked connections
sub _forking
{
    my $self = shift;
    my($infunc, $outfunc) = @_;

    my($client, $remote, $pid, $buf);

    _debug("Forking server started");

    # reap children
    $SIG{CHLD} = \&_REAPER;

    # get connection
    while($client = $self->{MAIN}->accept()) {

        _debug(
            "Connect from ", 
            $client->peerhost(), 
            ':', 
            $client->peerport(),
        );

        # connect to remote host
        $remote = $self->_make_conn($client);
        next unless $remote;
        $remote->autoflush(1);
        _debug(
            "Remote connection to ",
            $remote->peerhost(),
            ":",
            $remote->peerport()
        );

        $pid = fork();
        unless ( defined($pid) ) {
            carp "Cannot fork: $!\n";
            close($client);
            close($remote);
            next;
        }

        if($pid) {                       # mum
            close($client);
            close($remote);
            next;
        }

        # child
        close($self->{MAIN});

        # create a twin handling the other side
        $pid = fork();
        unless ( defined($pid) ) {
            croak "Cannot fork: $!\n";
        }

        if ( $pid ) {                        # mum # 2

            select($client);
            $| = 1;

            # shovel data from remote to client
            while($remote->sysread($buf, 1024, length($buf))) {
                print $infunc->($buf);
            }

            select(STDOUT);
            _debug(
                "Session closed from remote side ",
                $remote->peerhost(),
                ":",
                $remote->peerport()
            );

            # done, kill child
            kill('TERM', $pid);

        } else {

            select($remote);
            # turn off buffering
            $| = 1;

            # shovel data from client to remote
            while($client->sysread($buf, 1024, length($buf))) {
                print $outfunc->($buf);
            }

            select(STDOUT);
            _debug(
                "Session closed from client side ",
                $client->peerhost(),
                ":",
                $client->peerport()
            );

            # kill parent, since done
            kill('TERM', getppid());
         }
         $remote->close();
         $client->close();

    } # while

    return;
}


sub _nonforking
{
    my $self = shift;
    my($infunc, $outfunc) = @_;

    _debug("Nonforking server started");

    while (1) {

        my @readable = $self->{ALLSOCKS}->can_read(0.05);

        foreach my $sock ( @readable ) {

            if ( $sock == $self->{MAIN} ) {

                # accepting local connection
                my $client = $sock->accept();
                $client->autoflush(1);
                _debug(
                   "Connect from ",
                   $client->peerhost(),
                   ":",
                   $client->peerport()
                );

                # opening remote connection
                my $remote = $self->_make_conn($client);
                next unless $remote;
                $remote->autoflush(1);
                _debug(
                   "Remote connection to ",
                   $remote->peerhost(),
                   ":",
                   $remote->peerport()
                );

                # adding both sockets to IO::Select object
                $self->{ALLSOCKS}->add($client);
                $self->{ALLSOCKS}->add($remote);

                # adding both sockets to socket hash
                # pointing to each other
                $self->{LOOKUP}{$client}  = {
                     sock => $remote,
                     type => 'remote',
                };
                $self->{LOOKUP}{$remote} = {
                     sock  => $client,
                     type  => 'client',
                }

            } elsif ( defined($self->{LOOKUP}{$sock}) ) {

                my $dest   = $self->{LOOKUP}{$sock}{sock};
                my $type   = $self->{LOOKUP}{$sock}{type};
                my $rtype  = $type eq 'client' ? 'remote' : 'client';
                my $func   = $type eq 'client' ? $infunc : $outfunc;

                my $buf;
                my $sel = IO::Select->new($sock);
                while ( $sel->can_read(0.05) ) {
                   last unless $sock->sysread($buf, 1024, length($buf));
                }
    
                my $err = 0;
                if ( !$buf ) {
                    _debug(
                        "Session closed from $rtype side ",
                        $sock->peerhost(),
                        ":",
                        $sock->peerport()
                    );
                    $err = 1;
                } elsif ( ! print $dest $func->($buf) ) {
                    _debug(
                        "Session closed from $type side ",
                        $sock->peerhost(),
                        ":",
                        $sock->peerport()
                    );
                    $err = 1;
                }

                # remove sockets on error
                if ( $err )  {
                    $self->{ALLSOCKS}->remove($sock, $dest);
                    delete($self->{LOOKUP}{$sock});
                    delete($self->{LOOKUP}{$dest});
                    $sock->close();
                    $dest->close();
                }               

            } else {

                # socked already closed?
                next unless $sock->connected();

                # should never happen :-)
                carp "unknown connection ", $sock->peerhost(),
                    ":", $sock->peerport();
            }
        }
    }
}


# reap kids
sub _REAPER
{

    my($child);

    while (($child = waitpid(-1,WNOHANG)) > 0) {
    }

    $SIG{CHLD} = \&_REAPER;
}


#
# Make a connection to the requested destination
#

sub _make_conn
{
    my $self = shift;
    my($sock) = @_;

    # see if this should be transparent proxying or not

    my($dhost, $dport);
    if($self->{-remote_host}) {
        $dhost = $self->{-remote_host};
        $dport = $self->{-remote_port};
    } else {
        # find the actual destination
        $dport = $sock->sockport();
        $dhost = $sock->sockhost();
    }

    _debug("Connecting to ", $dhost, ":", $dport);

    my $newsock = IO::Socket::INET->new(
        PeerAddr => $dhost,
        PeerPort => $dport,
        Proto    => 'tcp',
    ) or carp "Can't connect to $dhost:$dport: $!\n";

    return($newsock);
}


#
# print debug info if desired
#

sub _debug
{
    my(@strings) = @_;

    if ($do_debug) { 
        print @strings, "\n";
    }
}


1;
__END__

=head1 NAME

Net::ProxyMod - Small TCP proxy module for packet alteration.

=head1 SYNOPSIS

  use Net::ProxyMod;

=head1 DESCRIPTION

This is a small module that allows you to create a proxy for packet alteration
and debugging. You just need to specify two functions in and outgoing packets
will be passed to. In these functions you can then modify the packet if desired.
This is useful to get in between an existing client and server for testing
purposes.

C<ProxyMod> can be used as a standard proxy or as a transparent proxy 
together with a firewall package such as ipfw on FreeBSD. Please refer 
to the ipfw documenation for more information.

=head1 METHODS

=over 1

=item B<new>(local_host, local_port, remote_host, remote_port, debug)

or

=item B<new>( param => value [, param => value ...] )

will create a new proxy object.
It will also create a tcp socket bound to the given host and port. If 
dest_host and dest_port are emtpy, the destination address and port 
will be taken from the original request.

The following named parameters are recognized:

B<-local_host>

B<-local_port>

B<-remote_host>

B<-remote_port>


B<-debug>

If debug is 1, the module 
will give you messages about connects.

B<-mode>

If -mode is set to 'nonforking', the proxy will handle the connections 
without forking of child processes for each connection. Quite usefull 
when you don't have fork() :-).


=item B<get_conn>(infunc, outfunc)

will wait for packets to arrive. The payload of packets going from the 
server to the client will passed on to the function infunc. Likewise 
packets going from the client to the original server are passed on to 
outfunc. The return value of infunc and outfunc will be taken as the 
new payload in that direction.

=head1 EXAMPLE

This is a very simple example, more complex things are of course 
possible: This is a transparent proxy bound to localhost port 7777. 
Since host and port of the destination are left out, the final 
destination and port will be taken out of the original request. For 
this you have to add to your firewall config. On FreeBSD you can do:

C<ipfw add 100 fwd localhost,7777 tcp from [client] to [dest] 1234 (in via [iface])>

    #!/usr/bin/perl

    use Net::ProxyMod;

    # create a new proxy object
    $p = Net::ProxyMod->new(localhost, 7777, "", 0, 1);

    # wait for connections
    $p->get_conn(\&infunc,\&outfunc);

    # for packets going from the server to the client:
    sub infunc
    {
        my($data) = @_;
        # increase a number
        $data =~/ (10) /;
        $num = $1 + rand(10);
        $data =~ s/ 10 / $num/g;

        return($data);
    }

    # for packets going from the client to the server:
    sub
    outfunc
    {
        my($data) = @_;

        # adjust the payload, something real simple:
        $data =~ s/index.html/foobar.html/;

        return($data);
    }


=head1 NOTES

If you run the transparent proxy on the same machine as the client
request, be careful not to create infinite loops. This can happen
if the outgoing request from the proxy hits the forward rule as well.

ProxyMod is not programmed for efficiency, but as a quick test tool.
Right now this only proxies TCP connections. If you need UDP you can
use Net::Divert.

=head1 AUTHOR

Stephanie Wehner, _@r4k.net

=head1 SEE ALSO

perl(1), ipfw(8), Net::Divert

=cut
