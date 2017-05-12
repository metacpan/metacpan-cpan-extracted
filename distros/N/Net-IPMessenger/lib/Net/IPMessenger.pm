package Net::IPMessenger;

use warnings;
use strict;
use 5.008001;
use Carp;
use IO::Socket::INET;
use Net::IPMessenger::ClientData;
use Net::IPMessenger::Encrypt;
use Net::IPMessenger::MessageCommand;
use Net::IPMessenger::RecvEventHandler;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(
    qw(
        packet_count    sending_packet      user            message
        nickname        groupname           username        hostname
        socket          serveraddr          sendretry       broadcast
        event_handler   encrypt             debug
        )
);

our $VERSION    = '0.14';
my $PROTO       = 'udp';
my $PORT        = 2425;
my $BROADCAST   = '255.255.255.255';
my $MAX_SOCKBUF = 65535;
my $SEND_RETRY  = 3;

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {};
    bless $self, $class;

    $self->packet_count(0);
    $self->user( {} );
    $self->message(       [] );
    $self->event_handler( [] );
    $self->sending_packet( {} );
    $self->broadcast( [] );

    $self->nickname( $args{NickName} )       if $args{NickName};
    $self->groupname( $args{GroupName} )     if $args{GroupName};
    $self->username( $args{UserName} )       if $args{UserName};
    $self->hostname( $args{HostName} )       if $args{HostName};
    $self->serveraddr( $args{ServerAddr} )   if $args{ServerAddr};
    $self->debug( $args{Debug} )             if $args{Debug};
    $self->add_broadcast( $args{BroadCast} ) if $args{BroadCast};
    $self->sendretry( $args{SendRetry} || $SEND_RETRY );

    # encryption support
    my $encrypt = Net::IPMessenger::Encrypt->new;
    # enable only encrypt modules are available
    $self->encrypt($encrypt) if $encrypt;

    my $sock = IO::Socket::INET->new(
        Proto     => $PROTO,
        LocalPort => $args{Port} || $PORT,
    ) or return;

    $self->socket($sock);
    $self->add_event_handler( Net::IPMessenger::RecvEventHandler->new );

    return $self;
}

sub get_connection {
    shift->socket;
}

sub add_event_handler {
    my $self = shift;
    push @{ $self->event_handler }, shift;
}

sub add_broadcast {
    my $self = shift;
    push @{ $self->broadcast }, shift;
}

sub recv {
    my $self = shift;
    my $sock = $self->socket;

    my $msg;
    $sock->recv( $msg, $MAX_SOCKBUF ) or croak "recv: $!\n";
    my $peeraddr = inet_ntoa( $sock->peeraddr );
    my $peerport = $sock->peerport;
    # ignore yourself
    if ( $self->serveraddr ) {
        return if ( $peeraddr eq $self->serveraddr );
    }

    my $user = Net::IPMessenger::ClientData->new(
        Message  => $msg,
        PeerAddr => $peeraddr,
        PeerPort => $peerport,
    );
    $self->update_userlist( $user, $msg );

    my $command  = $self->messagecommand( $user->command );
    my $modename = $command->modename;
    # invoke event handler
    my $ev_handler = $self->event_handler;
    if ( ref $ev_handler and ref $ev_handler eq 'ARRAY' ) {
        for my $handler ( @{$ev_handler} ) {
            if ( $self->debug and $handler->can('debug') ) {
                $handler->debug( $self, $user );
            }
            $handler->$modename( $self, $user ) if $handler->can($modename);
        }
    }
    return $user;
}

sub update_userlist {
    my $self = shift;
    my $user = shift;
    my $msg  = shift;
    my $key  = $user->key;

    # exists in user list
    if ( exists $self->user->{$key} ) {
        $self->user->{$key}->parse($msg);
    }
    # new user
    else {
        my $command  = $self->messagecommand( $user->command );
        my $modename = $command->modename;
        unless ( $modename eq 'SENDMSG' and $command->get_noaddlist ) {
            $self->user->{$key} = $user;
        }
    }
}

sub parse_anslist {
    my $self     = shift;
    my $user     = shift;
    my $listaddr = shift;

    my @list  = split( /\a/, $user->option );
    my $title = shift(@list);
    my $count = shift(@list);

    my %present;
    my %new;
    for my $key ( keys %{ $self->user } ) {
        if ( defined $self->user->{$key}->listaddr
            and $listaddr eq $self->user->{$key}->listaddr )
        {
            $present{$key} = 1;
        }
    }

    while (1) {
        my $uname = shift @list or last;
        my $host  = shift @list or last;
        my $pnum  = shift @list or last;
        my $addr  = shift @list or last;
        my $com   = shift @list or last;
        my $nick  = shift @list or last;
        my $group = shift @list or last;

        if ( $self->serveraddr ) {
            next if ( $addr eq $self->serveraddr );
        }

        my $newuser = Net::IPMessenger::ClientData->new(
            Ver       => 1,
            PacketNum => $pnum,
            User      => $uname,
            Host      => $host,
            Command   => $com,
            Nick      => $nick,
            Group     => $group,
            PeerAddr  => $addr,
            PeerPort  => $PORT,
            ListAddr  => $listaddr,
        );
        my $newkey = $newuser->key;
        $self->user->{$newkey} = $newuser;
        $new{$newkey} = 1;
    }

    my @deleted;
    foreach my $pkey ( keys %present ) {
        unless ( exists $new{$pkey} ) {
            push @deleted, $self->user->{$pkey}->nickname;
            delete $self->user->{$pkey};
        }
    }
    return (@deleted);
}

sub generate_packet {
    my( $self, $args ) = @_;
    my $command    = $args->{command};
    my $option     = $args->{option} || '';
    my $packet_num = $args->{packet_num} || $self->get_new_packet_num;
    $args->{option} = $option;
    $args->{packet_num} = $packet_num;

    my $msg = sprintf "1:%s:%s:%s:%s:%s", $packet_num, $self->username,
        $self->hostname, $command, $option;
    return $msg;
}

sub send {
    my( $self, $args ) = @_;
    my $sock       = $self->socket;
    my $command    = $args->{command};
    my $msg        = $self->generate_packet($args);
    my $packet_num = $args->{packet_num};
    # TODO check max msg length check by MAX_SOCKBUF

    # stack sendmsg packet number
    if (    $command->modename eq 'SENDMSG'
        and $command->get_sendcheck
        and not exists $self->sending_packet->{$packet_num} )
    {
        $args->{sendretry} = $self->sendretry;
        $self->sending_packet->{$packet_num} = $args;
    }

    my $peerport = $args->{peerport};
    if ( not defined $peerport ) {
        $peerport = $sock->peerport || $PORT;
    }

    # send broadcast packet
    if ( $command->get_broadcast ) {
        $sock->sockopt( SO_BROADCAST() => 1 )
            or croak "failed sockopt : $!\n";

        unless ( @{ $self->broadcast } ) {
            $self->add_broadcast($BROADCAST);
        }
        for my $broadcast_addr ( @{ $self->broadcast } ) {
            my $dest = sockaddr_in( $peerport, inet_aton($broadcast_addr) );
            $sock->send( $msg, 0, $dest )
                or croak "send() failed : $!\n";
        }

        $sock->sockopt( SO_BROADCAST() => 0 )
            or croak "failed sockopt : $!\n";
    }
    # send packet
    else {
        my $peeraddr = $args->{peeraddr};
        if ( not defined $peeraddr ) {
            $peeraddr = inet_ntoa( $sock->peeraddr );
        }

        my $dest = sockaddr_in( $peerport, inet_aton($peeraddr) );
        $sock->send( $msg, 0, $dest )
            or croak "send() failed : $!\n";
    }
}

sub flush_sendings {
    my $self = shift;

    for my $packet_num ( keys %{ $self->sending_packet } ) {
        my $args = $self->sending_packet->{$packet_num};
        if ( 0 > --$args->{sendretry} ) {
            delete $self->sending_packet->{$packet_num};
            next;
        }
        $args->{packet_num} = $packet_num;
        $self->send($args);
    }
}

sub messagecommand {
    my $self = shift;
    return Net::IPMessenger::MessageCommand->new(shift);
}

sub get_new_packet_num {
    my $self  = shift;
    my $count = $self->packet_count;
    $self->packet_count( ++$count );
    return ( time + $count );
}

sub my_info {
    my $self = shift;
    return sprintf "%s\0%s\0", $self->nickname || '', $self->groupname || '';
}

1;
__END__

=head1 NAME

Net::IPMessenger - Interface to the IP Messenger Protocol


=head1 VERSION

This document describes Net::IPMessenger version 0.14


=head1 SYNOPSIS

    use Net::IPMessenger;

    my $ipmsg = Net::IPMessenger->new(
        NickName  => 'myname',
        GroupName => 'mygroup',
        UserName  => 'myuser',
        HostName  => 'myhost',
    ) or die;

    $ipmsg->serveraddr($addr);
    $ipmsg->add_broadcast($broadcast);

    $ipmsg->send(...);

    ...

    $ipmsg->recv(...);

    ...


=head1 DESCRIPTION

This is a client class of the IP Messenger (L<http://ipmsg.org/index.html.en>)
Protocol. Sending and Receiving the IP Messenger messages.


=head1 METHODS

=head2 new

    my $ipmsg = Net::IPMessenger->new(
        NickName   => $name,
        GroupName  => $group,
        UserName   => $user,
        HostName   => $host,
        ServerAddr => $server,
        Port       => $port,
        SendRetry  => $sendretry,
        BroadCast  => $broadcast,
    ) or die;

The new method creates object, sets initial variables and create socket.
When this returns undef, it means you failed to create socket
(i.e. port already in use).
Check $! to see the error reason.

Encrypt option is automatically enabled if enough modules are found.

=head2 get_connection

    my $socket = $ipmsg->get_connection;

Returns socket object.

=head2 add_event_handler

    $ipmsg->add_event_handler( new MyEventHandler );

Adds event handler. Handler method will be invoked when you do $ipmsg->recv().

=head2 add_broadcast

    $ipmsg->add_broadcast($broadcast);

Adds broadcast address.

=head2 recv

    $ipmsg->recv;

Receives a message.

=head2 update_userlist

Updates user HASH.

=head2 parse_anslist

    $ipmsg->parse_anslist( $message, $peeraddr );

Parses an ANSLIST to the list and stores it into the user list.

=head2 send

    $ipmsg->send(
        {
            command    => $self->messagecommand('READMSG'),
            option     => $option,
            peeraddr   => $message->peeraddr,
            peerport   => $message->peerport
            packet_num => $packet_num,
        }
    );

Creates message from command, option. You can specify packet_num to send
reply packet or packet_num just automatically generated.
Then sends it to the peeraddr:peerport (or gets the destination from the socket).

If BROADCAST flag is set, sends broadcast packet.

NOTE. Method arguments are changed from v0.04. It used to be
    $ipmsg->send( $cmd, $option, $broadcast, $peeraddr, $peerport );

=head2 flush_sendings

    if ( $ipmsg->sending_packet ) {
        $ipmsg->flush_sendings;
    }

Re-sending messages in the message queue. Message will be push into the queue
when you send SENDMSG with SENDCHECK flag.

It will be deleted when you receive RECVMSG which contains same packet number
you sent in option field, or after tried to send sendretry time(s).
You can change retry count like below.

    my $ipmsg = Net::IPMessenger->new(
        SendRetry  => 5,
    );
    # or
    $ipmsg->sendretry(5);

To access message queue, use sending_packet method.

=head2 generate_packet

    my $msg = $self->generate_packet($args);

Generates sending packet in order

=head2 messagecommand

    my $command = $ipmsg->messagecommand('SENDMSG')->set_secret;

Creates Net::IPMessenger::MessageCommand object and returns it.

=head2 get_new_packet_num

    my $packet_num = $self->get_new_packet_num;
    my $msg = sprintf "1:%s:%s:%s:%s:%s", $packet_num, $self->username,
        $self->hostname, $command, $option;

Increments packet count and returns it with current time.

=head2 my_info

    my $my_info = $self->my_info;

Returns information of yourself.

=head1 CONFIGURATION AND ENVIRONMENT

Net::IPMessenger requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-net-ipmessenger@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Masanori Hara  C<< <massa.hara at gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010-2011, Masanori Hara C<< <massa.hara at gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
