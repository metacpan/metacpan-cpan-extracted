package Socket::Mmsg;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(

)] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = (
	'sendmmsg',
	'recvmmsg'
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Socket::Mmsg', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Socket::Mmsg - Perl extension for recvmmsg and sendmmsg Linux syscalls

=head1 SYNOPSIS

#!/usr/bin/perl
use strict;
use Socket;
use Socket::Mmsg;

### Creating sending udp socket
my $snd_sock;
socket($snd_sock, PF_INET, SOCK_DGRAM, getprotobyname('udp'));

### Generating array of messages for sendmmsg
my $msg_array = [];
foreach (1..8){
    push @$msg_array , [(pack_sockaddr_in('9999', INADDR_LOOPBACK)), 'Hello number:'.$_]
}

### Creating receiving udp socket
my $recv_sock;
socket($recv_sock, PF_INET, SOCK_DGRAM, getprotobyname('udp'));
bind ($recv_sock, sockaddr_in('9999', INADDR_LOOPBACK));

### Send all messages in one syscall
my $snt_msg = &sendmmsg($snd_sock,$msg_array);
print "Sent messages: $snt_msg\n";

### Receive all messages in one syscall
my $recv_buffer = &recvmmsg($recv_sock, 8, 1000, 1);
print "Recieved messages: ".scalar @$recv_buffer."\n";

### Print received messages
foreach my $pkt(@$recv_buffer){
    my ($port,$ip) = sockaddr_in($pkt->[0]);
    print $pkt->[1].' from:'.inet_ntoa($ip).':'.$port."\n";
}

=head1 DESCRIPTION

C<Socket::Mmsg> - Is wrapper around two Linux-specific syscalls : recvmmsg and sendmmsg.
Basically it was made for using in gather-type scripts (like snmp requests on huge number of devices),
for more info you can read man pages of recvmmsg(2) and sendmmsg(2) syscalls.

=head2 FUNCTIONS

=over 4

=item sendmmsg SOCKET, MSG_ARRAY_REF

  Send all messages from specified array reference to specified socket.
Returns number of sent messages and removes sent messages from array.
Number of sent messages is limited by UIO_MAXIOV (for linux is 1024).
Structure of array is :

C<$array_ref = [
     [sockaddr_in(), $message_string]
     ...
];>

=item recvmmsg SOCKET, NUMBER_OF_MSG, BUFFER_FOR_EACH_MSG, TIMEOUT_FLOAT

  Receive NUMBER_OF_MSG from specified SOCKET.
Return $array_ref with recieved messages in format :

C<$array_ref = [
     [sockaddr_in(), $message_string]
     ...
];>

Syscall is running with MSG_WAITFORONE flag.

=back

=head2 EXPORT

c<Socket::Mmsg> exports sendmmsg and recvmmsg by default into the caller's namespace.

=head1 SEE ALSO

=head1 AUTHOR

Vladimir Krasulia hithim@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Vladimir Krasulya

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
