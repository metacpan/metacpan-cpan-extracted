package Net::IPMessenger::RecvEventHandler;

use warnings;
use strict;
use IO::Socket;
use base qw( Net::IPMessenger::EventHandler );

sub BR_ENTRY {
    my( $self, $ipmsg, $user ) = @_;
    my $command = $ipmsg->messagecommand('ANSENTRY');
    $command->set_encrypt if $ipmsg->encrypt;
    $ipmsg->send(
        {
            command => $command,
            option  => $ipmsg->my_info,
        }
    );
}

sub ANSLIST {
    my( $self, $ipmsg, $user ) = @_;
    my $key      = $user->key;
    my $peeraddr = inet_ntoa( $ipmsg->socket->peeraddr );

    $ipmsg->parse_anslist( $user, $peeraddr );
    delete $ipmsg->user->{$key};
}

sub SENDMSG {
    my( $self, $ipmsg, $user ) = @_;
    my $command = $ipmsg->messagecommand( $user->command );
    if ( $command->get_sendcheck ) {
        $ipmsg->send(
            {
                command => $ipmsg->messagecommand('RECVMSG'),
                option  => $user->packet_num,
            }
        );
    }

    # decrypt message if the message is encrypted
    # and encryption support is available
    if ( $command->get_encrypt and $ipmsg->encrypt ) {
        my $encrypt = $ipmsg->encrypt;
        my $decrypted = $encrypt->decrypt_message( $user->get_message );
        $user->option($decrypted);
        if ( $command->get_fileattach ) {
            $user->attach( $encrypt->attach );
        }
    }
    elsif ( $command->get_fileattach ) {
        my( $option, $attach ) = split /\0/, $user->get_message;
        $user->option($option);
        $user->attach($attach);
    }
    push @{ $ipmsg->message }, $user;
}

sub RECVMSG {
    my( $self, $ipmsg, $user ) = @_;
    my $option = $user->option;
    $option =~ s/\0//g;
    if ( exists $ipmsg->sending_packet->{$option} ) {
        delete $ipmsg->sending_packet->{$option};
    }
}

sub READMSG {
    my( $self, $ipmsg, $user ) = @_;
    my $command = $ipmsg->messagecommand( $user->command );
    if ( $command->get_readcheck ) {
        $ipmsg->send(
            {
                command => $ipmsg->messagecommand('ANSREADMSG'),
                option  => $user->packet_num,
            }
        );
    }
}

sub GETINFO {
    my( $self, $ipmsg, $user ) = @_;
    $ipmsg->send(
        {
            command => $ipmsg->messagecommand('SENDINFO'),
            option  => sprintf( "Net::IPMessenger-%s", $ipmsg->VERSION ),
        }
    );
}

sub GETPUBKEY {
    my( $self, $ipmsg, $user ) = @_;
    return unless $ipmsg->encrypt;
    $ipmsg->send(
        {
            command => $ipmsg->messagecommand('ANSPUBKEY'),
            option  => $ipmsg->encrypt->public_key_string,
        }
    );
}

sub ANSPUBKEY {
    my( $self, $ipmsg, $user ) = @_;
    return unless $ipmsg->encrypt;
    my $key     = $user->key;
    my $message = $user->get_message;
    my( $option, $public_key ) = split /:/,  $message;
    my( $exponent, $modulus )  = split /\-/, $public_key;
    $ipmsg->user->{$key}->pubkey(
        {
            option   => $option,
            exponent => $exponent,
            modulus  => $modulus,
        }
    );
}

1;
__END__

=head1 NAME

Net::IPMessenger::RecvEventHandler - default event handler

=head1 SYNOPSIS

    use Net::IPMessenger::RecvEventHandler;

    ...

    $self->add_event_handler( new Net::IPMessenger::RecvEventHandler );

    use Net::IPMessenger::RecvEventHandler;


=head1 DESCRIPTION

IP Messenger receive event handler.
This is added default by Net::IPMessenger.

=head1 METHODS

=head2 BR_ENTRY

Replies ANSENTRY packet.

=head2 BR_EXIT

Deletes user from the user HASH.

=head2 ANSLIST

Parses message and deletes user from the user HASH
(because user is an exchange server).

=head2 SENDMSG

Replies RECVMSG packet if the message has SENDCHECK flag.
And adds message to the message ARRAY.

=head2 RECVMSG

Compare received message option field with messages in the queue.
If matchs found, delete the message in the queue.

=head2 READMSG

Replies ANSREADMSG packet if the message has READCHECK flag.

=head2 GETINFO

Replies SENDINFO packet. Version message is "Net::IPMessenger-version".

=head2 GETPUBKEY

Replies ANSPUBKEY packet.

=head2 ANSPUBKEY

Gets RSA public key and store it.

=head1 SEE ALSO

L<Net::IPMessenger::EventHandler>
