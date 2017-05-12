use strict;
use warnings;

# Mojolicious-based FIX-server which streams quotes with randomly generated prices

use Getopt::Long qw(GetOptions :config no_auto_abbrev no_ignore_case);

use Mojo::IOLoop::Server;
use Mojo::IOLoop;
use Protocol::FIX qw/humanize/;
use POSIX qw(strftime);

GetOptions(
    'p|listening_port=i'      => \my $port,
    's|symbol_list=s'         => \my $symbol_list,
    'S|SenderCompID=s'        => \my $sender_comp_id,
    'T|TargetCompID=s'        => \my $target_comp_id,
    'L|Login=s'               => \my $login,
    'P|Password=s'            => \my $password,
    'h|help'                  => \my $help,
);

my $show_help = $help || !$port || !$symbol_list
    || !$sender_comp_id || !$target_comp_id
    || !$login || !$password
    ;
die <<"EOF" if ($show_help);
usage: $0 OPTIONS

These options are available:
  -p, --listening_port          Port, on which $0 will accept incoming connections
  -s, --symbol_list             Comma-separated symbols list (e.g. EURAUD, EURCAD)
  -S, --SenderCompID            SenderCompID (e.g. FixServer)
  -T, --TargetCompID            TargetCompID (e.g. Client1)
  -L, --Login                   Login
  -P, --Password                Password
  -h, --help                    Show this message.
EOF

my @symbols = sort split /,/, $symbol_list;
my %price_for = map {
    my $s = $_;
    my $price = sprintf('%0.3f', 1000 * rand);
    print "initial price for $s = $price\n";
    $s => $price;
} @symbols;

my $send_quotes;


my $send_message = sub {
    my ($client, $message) = @_;
    print("=> ", $client->{id}, " : ", ($message =~ s/\x{01}/|/gr), "\n");
    $client->{stream}->write($message);
};

Mojo::IOLoop->recurring(1 => sub {
    print("refreshing quotes\n");
    for my $symbol (@symbols) {
        my $price = $price_for{$symbol};
        my $delta = $price * 0.0001;
        $price += (rand() * $delta) - $delta * 0.5;
        $price = sprintf('%0.3f', $price);
        print "$symbol => $price\n";
        $price_for{$symbol} = $price;
    }
    $send_quotes->();
});


my %session_for;
my $fix_protocol = Protocol::FIX->new('FIX44');

$send_quotes = sub {
    for my $client (grep {$_->{status} eq 'authorized'} values %session_for ) {
        for my $symbol (@symbols) {
            my $price = $price_for{$symbol};
            my $timestamp = strftime("%Y%m%d-%H:%M:%S.000", gmtime);
            my $message = $fix_protocol->message_by_name('MarketDataSnapshotFullRefresh')
                ->serialize([
                    SenderCompID => $sender_comp_id,
                    TargetCompID => $target_comp_id,
                    MsgSeqNum    => $client->{msg_seq}++,
                    SendingTime  => $timestamp,
                    Instrument   => [Symbol => $symbol],
                    MDFullGrp    => [ NoMDEntries => [
                        [MDEntryType => 'BID',   MDEntryPx => $price],
                        [MDEntryType => 'OFFER', MDEntryPx => $price],
                    ]],
                ]);
            $send_message->($client, $message);
        }
        print(scalar(@symbols), " has been sent to ", $client->{id}, "\n");
    }
};

my $on_Logon = sub {
    my ($client, $message) = @_;
    if ($client->{status} eq 'unauthorized') {
        my $ok = 1;
        $ok &&= ($message->value('SenderCompID') eq $target_comp_id) || do {
            print "SenderCompID mismatch: ", $message->value('SenderCompID'), " vs $target_comp_id", "\n";
            0;
        };
        $ok &&= ($message->value('TargetCompID') eq $sender_comp_id) || do {
            print "TargetCompID mismatch: ", $message->value('TargetCompID'), " vs $sender_comp_id", "\n";
            0;
        };
        $ok &&= ($message->value('Username') eq $login) || do {
            print "Username mismatch: ", $message->value('Username'), " vs $login", "\n";
            0;
        };
        $ok &&= ($message->value('Password') eq $password) || do {
            print "Password mismatch: ", $message->value('Password'), " vs $password", "\n";
            0;
        };
        if ($ok) {
            print("authorizing ", $client->{id}, "\n");
            $client->{status} = 'authorized';

            my $timestamp = strftime("%Y%m%d-%H:%M:%S.000", gmtime);
            my $message = $fix_protocol->message_by_name('Logon')
                ->serialize([
                    SenderCompID  => $sender_comp_id,
                    TargetCompID  => $target_comp_id,
                    MsgSeqNum     => $client->{msg_seq}++,
                    SendingTime   => $timestamp,
                    EncryptMethod => 'NONE',
                    HeartBtInt    => 60,
                ]);

            $send_message->($client, $message);
        } else {
            print("credentials mismatch ", $client->{id}, "\n");
        }
    } else {
        print("client is already authorized, protocol error\n");
    }
};

my %dispatcher = (
    Logon => $on_Logon,
);

my $on_accept = sub {
    my $client = shift;
    my $stream = $client->{stream};
    $stream->on(read => sub {
        my ($stream, $bytes) = @_;
        $client->{buff} .= $bytes;
        print("Received ", length($bytes), " bytes from client ", $client->{id}, "\n");
        print(humanize($bytes),"\n");

        my ($message, $err) = $fix_protocol->parse_message(\$client->{buff});
        if ($err) {
            print ("Got protocol error from ", $client->{id}, ":", $err, "\n");
        }elsif ($message) {
            my $name = $message->name;
            print("Message '$name'\n");
            my $handler = $dispatcher{$name} // die("No handler for message '$name'");
            $handler->($client, $message);
        } else {
            print("Not enough data to parse message\n");
        }
    });
    $stream->on(close => sub {
        my $stream = shift;
        print("Stream fro cleint ", $client->{id}, " has been closed", "\n");
        delete $session_for{$client->{id}};
    });
    $stream->on(error => sub {
        my ($stream, $err) = @_;
        print("Client ", $client->{id}, " errored with", $err, "\n");
    });
    $stream->start;

};

my $server = Mojo::IOLoop::Server->new;
$server->on(accept => sub {
    my ($server, $handle) = @_;
    #print ref($handle);
    my $client_id = $handle->peerhost . ":" . $handle->peerport;
    print "accepted client: $client_id\n";
    my $stream = Mojo::IOLoop::Stream->new($handle);
    my $client = { id => $client_id, stream => $stream, status => 'unauthorized', buff => '', msg_seq => 1, };
    $session_for{$client_id} = $client;
    $on_accept->($client);
});
$server->listen(port => $port);

$server->start;

# Start reactor if necessary
$server->reactor->start unless $server->reactor->is_running;
