package Net::IPMessenger::CommandLine;

use warnings;
use strict;
use IO::Socket;
use base qw( Net::IPMessenger );

__PACKAGE__->mk_accessors( qw( use_secret ) );

our $AUTOLOAD;

# sort by IP address
sub by_addr {
    my( $ipa1, $ipa2, $ipa3, $ipa4 ) = split( /\./, $a->peeraddr, 4 );
    my( $ipb1, $ipb2, $ipb3, $ipb4 ) = split( /\./, $b->peeraddr, 4 );

           $ipa1 <=> $ipb1
        || $ipa2 <=> $ipb2
        || $ipa3 <=> $ipb3
        || $ipa4 <=> $ipb4;
}

# DEBUG
sub dumper {
    require Data::Dumper;
    import Data::Dumper qw(Dumper);

    my $self   = shift;
    my $output = Dumper($self) . "\n";
    return $output;
}

sub debuguserbyaddr {
    my $self = shift;
    my $addr = shift;

    my $output;
    for my $key ( keys %{ $self->user } ) {
        my $hashref = $self->user->{$key};
        if ( $hashref->addr eq $addr ) {
            $output .= $key . "\n";
            for my $item ( sort keys %{$hashref} ) {
                $output .= sprintf "\t%-12s : %s\n", $item, $hashref->{$item}
                    if defined $hashref->{$item};
            }
        }
    }

    return $output;
}

sub socktest {
    my $self = shift;
    return sprintf "socktest %s\n", inet_ntoa( $self->socket->peeraddr );
}

# Command
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    return "$name is not the command";
}

sub join {
    my $self = shift;
    $self->user( {} );

    my $command = $self->messagecommand('BR_ENTRY')->set_broadcast;
    if ( $self->encrypt ) {
        $command->set_encrypt;
    }
    $self->send(
        {
            command => $command,
            option  => $self->my_info,
        }
    );
    return;
}

sub quit {
    my $self = shift;

    my $command = $self->messagecommand('BR_EXIT')->set_broadcast;
    $self->send( { command => $command, } );
    return 'exiting';
}

sub list {
    my $self = shift;
    my $output;

    my $i = 0;
    print "      ip address : port : nickname\n";
    print "-----------------:------:---------\n";
    if ( $self->user ) {
        for my $val ( sort by_addr values %{ $self->user } ) {
            $output .= sprintf "%16s : %s : %s\n", $val->peeraddr,
                $val->peerport, $val->nickname;
            $i++;
        }
    }
    $output .= sprintf "%s users listed\n", $i;
    return $output;
}

sub messages {
    my $self = shift;
    my $output;
    my $j;
    if ( $self->message and @{ $self->message } ) {
        for my $message ( @{ $self->message } ) {
            $output .= sprintf "%03d : %s : %s\n", ++$j, $message->time,
                $message->nickname;
        }
    }
    else {
        $output = "no message arrived";
    }
    return $output;
}

sub read {
    my $self = shift;
    my $output;

    if ( $self->message and @{ $self->message } ) {
        my $message = shift @{ $self->message };

        $output = sprintf "%s: %s\n%s\n", $message->time, $message->nickname,
            $message->get_message;

        my $command = $self->messagecommand( $message->command );
        if ( $command->get_secret ) {
            $self->send(
                {
                    command  => $self->messagecommand('READMSG'),
                    option   => $message->packet_num,
                    peeraddr => $message->peeraddr,
                    peerport => $message->peerport
                }
            );
        }
    }
    else {
        $output = "no message arrived";
    }
    return $output;
}

sub write {
    my $self   = shift;
    my $sendto = shift;

    unless ( defined $sendto ) {
        return ("Usage: write nickname_to_send");
    }

    my $target;
    for my $user ( values %{ $self->user } ) {
        if ( $user->nickname eq $sendto ) {
            if ( $user->encrypt and $self->encrypt and not $user->pubkey ) {
                my $option = sprintf "%x",
                    $self->encrypt->support_encryption;
                $self->send(
                    {
                        command  => $self->messagecommand('GETPUBKEY'),
                        option   => $option,
                        peeraddr => $user->peeraddr,
                        peerport => $user->peerport,
                    }
                );
            }
            $target = $user;
            last;
        }
    }
    return "no target found" unless defined $target;

    $self->{_target}       = $target;
    $self->{_write_buffer} = "";

    return <<__MESSAGE__;
writing message to '$sendto' is ready
input message then '.' to finish and send it.
__MESSAGE__
}

sub writing {
    my $self = shift;
    my $data = shift;

    return unless defined $data;

    if ( $data eq '.' ) {
        my $target   = $self->{_target};
        my $peeraddr = $target->peeraddr;
        my $peerport = $target->peerport;

        if ( $peeraddr and $peerport ) {
            my $command = $self->messagecommand('SENDMSG');
            $command->set_sendcheck;
            $command->set_secret if $self->use_secret;
            # encrypt message
            if ( $target->encrypt and $self->encrypt ) {
                $command->set_encrypt;
                my $encrypted = $self->encrypt->encrypt_message(
                    $self->{_write_buffer},
                    $target->pubkey,
                );
                $self->{_write_buffer} = $encrypted;
            }

            $self->send(
                {
                    command  => $command,
                    option   => $self->{_write_buffer},
                    peeraddr => $peeraddr,
                    peerport => $peerport
                }
            );
        }

        delete $self->{_write_buffer};
        delete $self->{_target};
    }
    else {
        $self->{_write_buffer} .= $data . "\n";
    }
}

sub is_writing {
    my $self = shift;
    if ( exists $self->{_write_buffer} ) {
        return 1;
    }
    return;
}

sub info {
    my $self = shift;

    my $output = "It's Your information\n";
    $output .= sprintf "nickname       : %s\n", $self->nickname;
    $output .= sprintf "groupname      : %s\n", $self->groupname;
    $output .= sprintf "username       : %s\n", $self->username;
    $output .= sprintf "hostname       : %s\n", $self->hostname;
    $output .= sprintf "server addr    : %s\n", $self->serveraddr;
    $output .= sprintf "broadcast addr : %s\n", @{ $self->broadcast } || '';
    return $output;
}

sub help {
    my $self   = shift;
    my $output = <<__OUTPUT__;
Text IP Messenger Client Help:

    This is just another IP messenger client for text console.
    These commands are available.

Command list (shortcut) :
    join    (j) : send entry packet (BR_ENTRY) to the broad cast address
    info    (i) : show information of yourself
    list    (l) : list users
    message (m) : show message list
    read    (r) : read 1 oldest message and delete
    write   (w) : write message to the nickname user
    quit    (q) : send exit packet (BR_EXIT) to the broad cast address
    help    (h) : show this help
__OUTPUT__

    return $output;
}

# regist some shortcuts
sub j { shift->join(@_); }
sub q { shift->quit(@_); }
sub l { shift->list(@_); }
sub m { shift->messages(@_); }
sub r { shift->read(@_); }
sub w { shift->write(@_); }
sub i { shift->info(@_); }
sub h { shift->help(@_); }

1;
__END__

=head1 NAME

Net::IPMessenger::CommandLine - Console Interface Command for IP Messenger

=head1 SYNOPSIS

    use Net::IPMessenger::CommandLine;

    my $ipmsg = Net::IPMessenger::CommandLine->new(
        ...
    );

    $ipmsg->join;
    ...


=head1 DESCRIPTION

Net::IPMessenger's sub class which adds console interface commands.


=head1 SUBROUTINE

=head2 by_addr

    for my $val ( sort by_addr values %{ $self->user } ) {
        ...
    }

Subroutine for sort. sorts user by IP address.

=head1 METHODS

=head2 dumper

Returns Data::Dumper-ed $self.

=head2 debuguserbyaddr

Sorts users by IP address and returns it.

=head2 socktest

Returns socket's peeraddr.

=head2 join

Clears all users and send broadcast ENTRY packet.

=head2 quit

Sends broadcast EXIT packet.

=head2 list

Lists up users and returns it.

=head2 messages

Shows message list which you've got.

=head2 read

Reads oldest message and deletes it.

=head2 write

Starts writing message to the target.

=head2 writing

Adds message body to the message buffer.
When only '.' line is input, sends message buffer to the target and
clears message buffer.

=head2 is_writing

Checks if you are actually writing a message.

=head2 info

Shows your information.

=head2 help

Shows help message.

=head2 j

Shortcut of join.

=head2 q

Shortcut of quit.

=head2 l

Shortcut of list.

=head2 m

Shortcut of messages.

=head2 r

Shortcut of read.

=head2 w

Shortcut of write.

=head2 i

Shortcut of info.

=head2 h

Shortcut of help.

=cut
