package Net::IPMessenger::ToStdoutEventHandler;

use warnings;
use strict;
use Encode qw( from_to );
use IO::Socket;
use POSIX;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
use base qw( Net::IPMessenger::EventHandler );

sub output {
    my $str = shift;
    from_to($str, 'shiftjis', 'euc-jp');
    my $time = strftime("%Y-%m-%d %H:%M:%S", localtime);
    print YELLOW "At \"$time\", " . $str;
    print RESET "\n";
}

sub debug {
    my $self = shift;
    my $them = shift;
    my $user = shift;

    my $peeraddr = inet_ntoa( $them->socket->peeraddr );
    my $peerport = $them->socket->peerport;
    my $command  = $them->messagecommand( $user->command );
    my $modename = $command->modename;

    print CYAN "Received $modename from [$peeraddr:$peerport]";
    print RESET "\n";
}

sub BR_ENTRY {
    my $self = shift;
    my $them = shift;
    my $user = shift;

    output($user->nickname . " joined.");
}

sub BR_EXIT {
    my $self = shift;
    my $them = shift;
    my $user = shift;

    output($user->nickname . " left.");
}

sub SENDMSG {
    my $self = shift;
    my $them = shift;
    my $user = shift;

    output("you got message from " . $user->nickname . " .\a");
}

1;
__END__

=head1 NAME

Net:IPMessenger::ToStdoutEventHandler - event handler for standard output

=head1 SYNOPSIS

    use Net::IPMessenger::ToStdoutEventHandler;

    ...

    $ipmsg->add_event_handler( new Net::IPMessenger::ToStdoutEventHandler );


=head1 DESCRIPTION

IP Messenger receive event handler for standard output.


=head1 METHODS

=head2 output

    output($user->nickname . " joined.");

This actually converts encodings and output to STDOUT.

=head2 debug

Outputs debug receive message.

=head2 BR_ENTRY

Outputs "someone joined." message.

=head2 BR_EXIT

Outputs "someone left." message.

=head2 SENDMSG

Outputs "you've got message from someone." message.


=head1 SEE ALSO

L<Net::IPMessenger::EventHandler>

=cut
