#
# Copyright (c) 2001, Stephanie Wehner <atrak@itsx.com>
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
#
# Net::Divert - FreeBSD Divert sockets in perl
#
# $Id: Divert.pm,v 1.2 2001/07/13 13:40:31 atrak Exp $

package Net::Divert;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);

$VERSION = '0.01';

# variables
my $IP_MAXPACKET = 65535;


BEGIN {

    my (@mods,$mod);

    @mods = qw(POSIX IO::Socket IO::Select);

    for $mod (@mods) {

        unless(eval "require $mod") {
            die "Can't find required module $mod: $!\n";
        }
    }
}

sub new 
{
    my $class = shift;
    my $self = {};

    bless($self, $class);

    # initialize the divert object
    $self->_init(@_);

    return($self);
}

# initialize

sub _init
{
    my $self = shift;
    my ($host, $port) = @_;
    
    # check if we're root
    if(POSIX::getuid() != 0) {
        die "Need to be root to create a divert socket.\n";
    }

    # record host and port
    $self->{HOST} = $host;
    $self->{PORT} = $port;

    # set the initial fwrule tag where the packet is 
    # reinserted (see man divert)
    $self->{FWTAG} = 0;

    # nothing to be written now
    $self->{OUT} = -1;
    $self->{DATA} = "";

    # setup the divert socket
    $self->{SOCK} = IO::Socket::INET->new(LocalHost => $host,
                                          LocalPort => $port,
                                          Type => IO::Socket::SOCK_RAW,
                                          Proto => 'divert');

    # set autoflush
    $self->{SOCK}->autoflush(1);

    return;
}

# clean up at the end

sub DESTROY 
{
    # socket cleanup will be done by IO::Socket::INET
}

# fetch data and call user supplied function, this is perhaps
# a bit overly cautious :)

sub getPackets
{
    my $self = shift;
    my $pFunc = shift;
    my ($select,$data,$fwtag,$s);

    # initialize the select object
    $select = new IO::Select($self->{SOCK});

    # get packets
    while(1) {

        # see if things still need to be written
        if($self->{OUT} == -1) {

            # check if one can read
            foreach $s ($select->can_read) {

                if($s == $self->{SOCK}) {

                    # fetch the packet
                    $fwtag = recv($s,$data,$IP_MAXPACKET,0) or
                        die "Unable to read packet: $!\n";

                    # call the user supplied function
                    &$pFunc($data,$fwtag);
                }
            }

        } else {

            # check if one can write
            foreach $s ($select->can_write) {

                if($s == $self->{SOCK}) {
                
                    # write outstanding packet
                    send($s,$self->{DATA},0,$self->{FWTAG}) or 
                        die "Unable to write packet: $!\n";

                    # XXX robustness

                    $self->{OUT} = -1 ;
                }
            }
        }

    }

    return;
}

# put a packet back on track, that'll be written next

sub putPacket
{
    my $self = shift;
    
    $self->{DATA} = shift;
    $self->{FWTAG} = shift;
    $self->{OUT} = $self->{SOCK};

    return;
}

1;
__END__

=head1 NAME

Net::Divert - Divert socket module

=head1 SYNOPSIS

  use Net::Divert;

=head1 DESCRIPTION

The C<Net::Divert> module facilitates the use of divert
sockets for packet alteration on FreeBSD and MacOSX.

Divert sockets can be bound to a certain port. This port
will then receive all packets you divert to it with the 
help of a divert filter rule. On FreeBSD and MacOSX ipfw
allows you to add such a rule. Please refer to the divert
and ipfw manpages for more information.

This module allows you to create a divert socket and then
just supply a function that will deal with the incoming packets.

new(host,port) will create a new divert object. It will also 
create a divert socket bound to the specified port at the given
host/ip.

getPackets(func) will create a loop getting all incoming
packets and pass them onto the specified function you created. 
This function will be called with two arguments: packet and
fwtag. Fwtag contains the rule number where the packet is reinserted. 
Refer to divert(4) for more information.

putPacket(packet,fwtag) reinsert a packet at the specified fw rule
(normally you don't want to alter fwtag, as it is easy to create 
infinite loops this way)

=head1 FRAMEWORK EXAMPLE

First of all, you need a ipfw divert rule, for example:
ipfw add divert 9999 all from any to www.somesite.com 80

Basic framework:

use Net::Divert;

$divobj = Net::Divert->new('yourhostname',9999);

$divobj->getPackets(\&alterPacket);

sub alterPacket
{
    my($packet,$fwtag) = @_;

    # here you can do things to the packet

    # write it back out
    $divobj->putPacket($packet,$fwtag);
}

=head1 EXAMPLES

You can modify the header of the packet as well as its payload.
Say you wanted to turn on the tcp ece and cwr flags in all tcp 
packets:

use Net::Divert;
use NetPacket::IP;
use NetPacket::TCP;

$divobj = Net::Divert->new('yourhostname',9999);

$divobj->getPackets(\&alterPacket);

sub alterPacket
{
    my($packet,$fwtag) = @_;

    # decode the IP header
    $ip_obj = NetPacket::IP->decode($packet);

    # check if this is a TCP packet
    if($ip_obj->{proto} == IP_PROTO_TCP) {

        # decode the TCP header
        $tcp_obj = NetPacket::TCP->decode($ip_obj->{data});

        # set the ece and cwr flags
        $tcp_obj->{flags} |= ECE | CWR;

        # construct the new ip packet
        $ip_obj->{data} = $tcp_obj->encode($ip_obj);
        $packet = $ip_obj->encode;

    }

    # write it back out
    $divobj->putPacket($packet,$fwtag);
}

When you alter the payload of an IP packet, the total length in the
IP header will be adjusted automatically when the packet is reencoded. 

=head1 NOTES

Altering the payload in TCP packets does not work this easily. You 
can modify the payload in such a way that the length of the payload 
stays the same. If you just want to modify, say, an outgoing webrequest
you can also make the payload smaller. The problem is inherent in
the way TCP uses sequence numbers. Data flowing from one host to the
other is a stream of data, spread out over multiple packets. The 
sequence number identifies the byte in this stream of data from
the sender to the receiver that the first byte in this segment 
represents. If you change the size of a packet in between the
state on both ends will be disynchronized. See TCP/IP Illustrated
Vol. 1 for more information on TCP.

You need at least NetPacket 0.03 to do the modifications described 
above.

=head1 LIMITATIONS

Packet modifications are done on packet per packet basis. If you
would want to make modifications spanning multiple packets, you
would have to keep packets in a alterPacket yourself. Keep in mind
though that because of retransmissions on the sending side, this might
not be possible for too long.

=head1 AUTHOR

Stephanie Wehner, atrak@itsx.com

=head1 COPYRIGHT

Copyright (c) 2001 Stephanie Wehner. All rights reserved. This
module is released under the BSD License. See the file LICENSE
for details.

=head1 SEE ALSO

perl(1), divert(4), ipfw(8)

=cut
