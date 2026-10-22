package Test::Net::ADB::Server;

use strict;
use warnings;

use Test::TCP;

sub read_request {
    my $client = shift;
    read($client, my $length, 4) == 4 or return undef;
    my $size = hex $length;
    return '' unless $size;
    read($client, my $request, $size) == $size or return undef;
    return $request;
}

sub shell_v2_packet { pack 'C V/a*', @_ }

sub shell_v2_reply {
    my ($stdout, $stderr, $exit) = @_;
    return
          'OKAY'
        . (length($stdout // '') ? shell_v2_packet(1, $stdout) : '')
        . (length($stderr // '') ? shell_v2_packet(2, $stderr) : '')
        . shell_v2_packet(3, chr($exit // 0));
}

sub adb_string { sprintf('%04x', length $_[0]) . $_[0] }

my %TRANSPORT = ('host:transport-any' => 'emulator-5554', 'host:transport-local' => '192.168.0.10:5555');
my @DEVICES   = (
    ['emulator-5554',     'device product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64 device:emu64x transport_id:1'],
    ['192.168.0.10:5555', 'device product:example model:Example_Phone device:example transport_id:2'],
    ['EX0123456789',      'unauthorized usb:1-1 transport_id:3']
);

my $DEVICES = join '', map { sprintf("%-22s %s\n", @{$_}) } @DEVICES;

my %DEVICE = ('emulator-5554' => {'shell,v2:echo Hello' => shell_v2_reply("Hello\n", '', 0)}, 'slow-1337' => undef);

my %HOST = (
    'host:get-serialno'             => 'OKAY' . adb_string('emulator-5554'),
    'host-local:get-serialno'       => 'OKAY' . adb_string('192.168.0.10:5555'),
    'host:version'                  => 'OKAY' . adb_string('0029'),
    'host-serial:offline:get-state' => 'FAIL' . adb_string('device offline'),
    'host-serial:broken:get-state'  => 'OKAY00',
    'host:transport-usb'            => 'FAIL' . adb_string('no devices found'),
    'host:devices-l'                => 'OKAY' . adb_string($DEVICES),
);

sub start { Test::TCP->new(listen => 1, code => \&serve) }

sub serve {
    my ($server) = @_;
    my @hold;

    while (my $client = $server->accept) {
        binmode $client;
        $client->autoflush(1);

        my $request = read_request($client) // next;

        my $reply  = undef;
        my $serial = $request =~ /^host:transport:(.+)$/ ? $1 : $TRANSPORT{$request};

        if (defined $serial && exists $DEVICE{$serial}) {
            my $device = $DEVICE{$serial};
            print {$client} 'OKAY';

            $request = read_request($client) // next;

            if (!defined $device) {
                push @hold, $client;
                next;
            }

            $reply = $device->{$request} // 'FAIL' . adb_string("unknown service: $request");
        }
        else {
            $reply = $HOST{$request} // 'FAIL' . adb_string("unknown host service: $request");
        }

        print {$client} $reply;
        close $client;
    }
}

1;
