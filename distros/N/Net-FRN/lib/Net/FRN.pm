package Net::FRN;
use strict;
use warnings;

use base 'Exporter';
use Net::FRN::Const;

use vars qw($VERSION @ISA @EXPORT_OK @EXPORT);

@EXPORT_OK = qw(
    FRN_PROTO_VERSION
    FRN_TYPE_PC_ONLY
    FRN_TYPE_CROSSLINK
    FRN_TYPE_PARROT

    FRN_MESSAGE_BROADCAST
    FRN_MESSAGE_PRIVATE

    FRN_STATUS_ONLINE
    FRN_STATUS_AWAY
    FRN_STATUS_NA

    FRN_MUTE_OFF
    FRN_MUTE_ON

    FRN_RESULT_OK
    FRN_RESULT_NOK
    FRN_RESULT_WRONG

    mkLinkName
);

@EXPORT = qw(
    FRN_PROTO_VERSION
    FRN_TYPE_PC_ONLY
    FRN_TYPE_CROSSLINK
    FRN_TYPE_PARROT

    FRN_MESSAGE_BROADCAST
    FRN_MESSAGE_PRIVATE

    FRN_STATUS_ONLINE
    FRN_STATUS_AWAY
    FRN_STATUS_NA

    FRN_MUTE_OFF
    FRN_MUTE_ON
    
    FRN_RESULT_OK
    FRN_RESULT_NOK
    FRN_RESULT_WRONG
);

$VERSION = '0.06';

sub client {
    my $class = shift;
    $class = ref $class if ref $class;
    require Net::FRN::Client;
    return Net::FRN::Client->new(@_);
}

sub server {
    my $class = shift;
    $class = ref $class if ref $class;
    require Net::FRN::Server;
    return Net::FRN::Server->new(@_);
}

sub authServer {
    my $class = shift;
    $class = ref $class if ref $class;
    require Net::FRN::AuthServer;
    return Net::FRN::AuthServer->new(@_);
}

# utility subs

sub mkLinkName {
    my %args = shift;
    my $mod = $args{Modulation};
    if (exists($args{FM})) {
        $mod = $args{FM} ? 'FM' : 'AM';
    } elsif (exists($args{AM})) {
        $mod = $args{AM} ? 'AM' : 'FM';
    }
    return sprintf(
        "%03i Ch%03i %2s CT%02i",
        $args{Band},
        $args{Channel},
        $mod,
        $args{CTCSS}
    );
}

1;


__END__

=head1 NAME

Net::FRN - Perl interface to Free Radio Network protocol.

=head1 SYNOPSYS

    use Net::FRN;

    my $client = Net::FRN->client (
        Host     => '01server.lpdnet.ru',
        Port     => 10026,
        Callsign => 'SP513',
        Name     => 'Alexander',
        Email    => 'sp513@example.org',
        Password => 'MYPASSWD',
        Net      => 'Russia',
        Type     => FRN_TYPE_CROSSLINK,
        Country  => 'Russian Federation',
        City     => 'St-Petersburg',
        Locator  => 'KP50FA'
    );

    $client->run;

=head1 DESCRIPTION

Net::FRN is an implementation of Free Radio Network protocol.

Free Radio Network client/server is a program package which is widely used by
radio amateurs to link radio repeaters over Internet. For more information
on FRN see http://freeradionetwork.eu

There are 4 components implementing different parts of the FRN service:

=over

=item *

Net::FRN

Wrapper around everything else, containing methods to generate Client, Server
and AuthServer objects (see below).

=item *

Net::FRN::Client

Component implementing fully functional FRN client.

=item *

Net::FRN::Server

Not yet implemented.

=item *

Net::FRN::AuthServer

Not yet implemented.

=back

=head1 GETTING STARTED

=head2 Initialization

    use Net::FRN;

    my $client = Net::FRN->client(
        Host     => '01server.lpdnet.ru',
        Port     => 10026,
        Callsign => 'SP513',
        Name     => 'Alexander',
        Email    => 'sp513@example.org',
        Password => 'MYPASSWD',
        Net      => 'Russia',
        Type     => FRN_TYPE_CROSSLINK,
        Country  => 'Russian Federation',
        City     => 'St-Petersburg',
        Locator  => 'KP50FA'
    );

Acceptable parameters for client() are:

=over

=item *

Host

Host name or IP address of FRN server.

=item *

Port

Port numer which FRN server listens on.

=item *

Name

Operator's real name

=item *

Callsign

Operator's callsign

=item *

Email

Operator's E-mail address.

=item *

Password

The password.

=item *

Net

Network (a.k.a. room) name to connect to. To change network even on the same
server you should disconnect and connect again to the new network.

=item *

Type

Type of FRN client. Use FRN_TYPE_* constants or return value of mkLinkString().

=item *

Country

Country name.

=item *

City

City where operator is located

=item *

Locator

Part of the city or QTH-locator

=back

=head2 Handlers

Use handler() method to set handler.

    $client->handler('onClinetList', &showClientList);
    $client->handler('onMessage',    &printMessage);

Available handlers are:

=over

=item *

onPing()

onPing() is called every time client sends a ping packet right after buffering
ping sequence.

=item *

onLogin()

onLogin() is called right after succeccful logging in.

=item *

onIdle()

onIdle() calls when client is idle.

=item *

onClientList(\@clientList)

onClientList() is called every time the list of clients received from server.

=over

=item $_[0]

Reference to array of client description records.

Client description structure:

    {
        S   => FRN_STATUS_ONLINE,
        M   => FRN_MUTE_OFF,
        NN  => 'Country',
        CT  => 'City - QTH',
        BC  => FRN_TYPE_PC_ONLY,
        ON  => 'Callsign, Name',
        ID  => 11,
        DS  => ''
    }

=back

=item *

onNetworkList(\@networkList)

onNetworkList() is called every time the list of networks recieved from the
server.

=over

=item $_[0];

Reference to array of network names.

=back

=item *

onMessage(\%message)

onMessage() is called every time the message is received.

=over

=item $_[0]

Message structure

    {
        from => \%client,
        type => FRN_MESSAGE_BROADCAST,
        text => 'Hello World!'
    }

=over

=item from

Sender client description record.

=item type

Type of the message.
Use constants FRN_MESSAGE_PRIVATE and FRN_MESSAGE_BROADCAST.

=item text

Message text.

=back

=back

=item *

onPrivateMessage

=item *

onBroadcastMessage

=item *

onRX

=item *

onGSM

=item *

onPCM

=item *

onBanList(\@banList)

onBanList() is called every time the list of banned clients received from server.

=over

=item $_[0]

Reference to array of banned client description records.

Banned client description structure:

    {
        AI  => 'ADMIN, Administrator';
        NN  => 'Country',
        CT  => 'City - QTH',
        BC  => FRN_TYPE_PC_ONLY,
        ON  => 'Callsign, Name',
        ID  => '192.168.0.1',
    }

=back

=item *

onMuteList(\@muteList)

onMuteList() is called every time the list of muted clients received from server.

=over

=item $_[0]

Reference to array of muted client description records.

Muted client description structure:

    {
        AI  => 'ADMIN, Administrator';
        NN  => 'Country',
        CT  => 'City - QTH',
        BC  => FRN_TYPE_PC_ONLY,
        ON  => 'Callsign, Name',
        ID  => '192.168.0.1',
    }

=back

=back

=head1 DESCRIPTION

=head2 Constants

FRN client types:

=over

=item *

FRN_TYPE_PC_ONLY

=item *

FRN_TYPE_CROSSLINK

=item *

FRN_TYPE_PARROT

=back

=head1 AUTHOR

Alexander Frolov E<lt>froller@cpan.orgE<gt>

=head1 URL

Up-to-date source and information about Net::FRN::Client can be found at
http://orn.froller.net

=head1 SEE ALSO

=over

=item *

perl(1)

=item *

http://freeradionetwork.eu, Free Radio Network web site

=item *

http://lpdnet.ru, Russian LPD Network web site

=back

=head1 TODO

=over

=item *

Reorganize parameters of client().

=item *

Add reconnection to backup server.

=back

=cut
