package Net::IPMessenger::Bot::EventHandler;

use strict;
use warnings;

use base qw/Net::IPMessenger::RecvEventHandler/;
use Encode qw();
use IO::Socket;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

sub new {
    my ($class, %args) = @_;

    my $self = shift->SUPER::new();

    $self->{handler}
        = ( ref $args{handler} eq 'ARRAY' )
        ? $args{handler}
        : [ qr// => $args{handler} ];

    return $self;
}

sub debug {
    my ( $self, $them, $user ) = @_;

    my $peeraddr = inet_ntoa( $them->socket->peeraddr );
    my $peerport = $them->socket->peerport;
    my $command  = $them->messagecommand( $user->command );
    my $modename = $command->modename;

    print CYAN "Received $modename from [$peeraddr:$peerport]";
    print RESET "\n";
}

sub handle {
    my ( $self, $user ) = @_;

    return unless ( $self->{handler} );

    my $msg = Encode::decode( 'shiftjis', $user->get_message );
    my $res;

    for ( my $i = 0; $i < @{ $self->{handler} }; $i += 2 ) {
        my $regex   = $self->{handler}->[$i];
        my $handler = $self->{handler}->[ $i + 1 ];

        if ( $msg =~ $regex ) {
            $res = $handler->($user);
            last;
        }
    }

    return $res;
}

sub SENDMSG {
    my ($self, $ipmsg, $user ) = @_;

    $ipmsg->message([]); #  clear cached-messages
    $self->SUPER::SENDMSG($ipmsg, $user);

    my $command = $ipmsg->messagecommand( $user->command );
    if ( $command->get_readcheck() ) {
        $ipmsg->send(
            {
                command => $ipmsg->messagecommand('READMSG'),
                option  => $user->packet_num,
            }
        );
    }

    if ( my $res = $self->handle($user) ) {
        $ipmsg->send(
            {
                command => $ipmsg->messagecommand('SENDMSG'),
                option  => Encode::encode( 'shiftjis', $res ),
            }
        );
    }
}

1;
