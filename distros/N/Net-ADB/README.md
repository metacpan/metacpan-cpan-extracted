[![Release](https://img.shields.io/github/release/giterlizzi/perl-Net-ADB.svg)](https://github.com/giterlizzi/perl-Net-ADB/releases) [![Actions Status](https://github.com/giterlizzi/perl-Net-ADB/actions/workflows/perltest.yml/badge.svg)](https://github.com/giterlizzi/perl-Net-ADB/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-Net-ADB.svg)](https://github.com/giterlizzi/perl-Net-ADB) [![Stars](https://img.shields.io/github/stars/giterlizzi/perl-Net-ADB.svg)](https://github.com/giterlizzi/perl-Net-ADB) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-Net-ADB.svg)](https://github.com/giterlizzi/perl-Net-ADB) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-Net-ADB.svg)](https://github.com/giterlizzi/perl-Net-ADB/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-Net-ADB/badge.svg)](https://coveralls.io/github/giterlizzi/perl-Net-ADB)

# Net::ADB - Client for ADB (Android Debug Bridge) Server

Pure-Perl client for the ADB server protocol: it talks directly to the ADB server
(`adb start-server`, `127.0.0.1:5037`) without running the `adb` executable.

## Synopsis

### Net::ADB

```perl
use Net::ADB;

my $adb = Net::ADB->new;

say $adb->version; # 41

# List the connected devices
for my $device ($adb->devices) {
    say "$device->{serial} $device->{state}";
}

# Run a command on the only connected device
my $res = $adb->shell_v2(command => 'getprop ro.product.model');

say $res->stdout;    # Example Phone
say $res->exit_code; # 0

# Select a device by serial, USB or TCP/IP
$res = $adb->shell_v2(serial => 'emulator-5554', command => 'uptime');
$res = $adb->shell_v2(usb    => 1,               command => 'uptime');

# Connect a device over TCP/IP (Wi-Fi)
$adb->connect(host => '192.168.0.10', port => 5555);

# Pair a device with wireless debugging (Android 11+)
$adb->pair(host => '192.168.0.10', port => 37099, code => '123456');

# Forward a local port to the device
my $port = $adb->forward(usb => 1, local => 'tcp:0', remote => 'tcp:8080');

for my $forward ($adb->list_forward) {
    say "$forward->{serial} $forward->{local} $forward->{remote}";
}
```

### Net::ADB::Device

```perl
use Net::ADB;

my $adb    = Net::ADB->new;
my $device = $adb->device(serial => '192.168.0.10:5555');

my $info = $device->info;

say "$info->{manufacturer} $info->{model}"; # Example Example Phone
say "Android $info->{android}";             # Android 13

my $memory = $device->memory;

printf "%d MB available of %d MB\n", $memory->{available} / 2**20, $memory->{total} / 2**20;

say $device->getprop->{'persist.sys.timezone'}; # Europe/Rome

say $device->loadavg->{avg1}; # 2.15

my $res = $device->shell('ls /sdcard');
print $res->stdout if $res->is_success;
```

## Requirements

- Perl 5.16 or later
- A running ADB server (`adb start-server`), local or reachable via TCP
- Android 7.0 or later on the device for `shell` (shell protocol v2)

## Install

Using Makefile.PL:

To install `Net::ADB` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using `App::cpanminus`:

    cpanm Net::ADB


## Documentation

- `perldoc Net::ADB`
- `perldoc Net::ADB::Device`
- `perldoc Net::ADB::Shell::Result`
- https://metacpan.org/release/Net-ADB
- Android Debug Bridge (adb): https://developer.android.com/tools/adb
- ADB server services: https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/master/docs/dev/services.md


## License

Licensed under the [Artistic License 2.0](LICENSE).


## Copyright

- Copyright 2026 © Giuseppe Di Terlizzi
