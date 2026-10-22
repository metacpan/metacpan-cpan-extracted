package Net::ADB;

use strict;
use warnings;
use utf8;
use v5.16;

use Carp;
use Errno qw(EINTR);
use IO::Select;
use IO::Socket::IP;
use Log::Any qw($log);
use Time::HiRes();

use Net::ADB::Device;
use Net::ADB::Util qw(wantlist croak_unknown_params);
use Net::ADB::Shell::Result;

our $VERSION  = '0.01';
our @CARP_NOT = qw(Net::ADB::Device Net::ADB::Shell::Result Net::ADB::Util);

use constant {
    SHELL_ID_STDIN       => 0,
    SHELL_ID_STDOUT      => 1,
    SHELL_ID_STDERR      => 2,
    SHELL_ID_EXIT        => 3,
    SHELL_ID_CLOSE_STDIN => 4,
    SHELL_HEADER_SIZE    => 5,
};

sub new {
    my ($class, %params) = @_;

    my $host    = delete $params{host}    // '127.0.0.1';
    my $port    = delete $params{port}    // 5037;
    my $timeout = delete $params{timeout} // 10;

    my $self = {host => $host, port => $port, timeout => $timeout};

    return bless $self, $class;
}


# Wire protocol

sub _open {
    my $self = shift;

    my $socket = IO::Socket::IP->new(
        PeerHost => $self->{host},
        PeerPort => $self->{port},
        Proto    => 'tcp',
        Timeout  => $self->{timeout},
    ) or Carp::croak("Cannot connect to adb server at $self->{host}:$self->{port}: $@");

    binmode $socket;
    return $socket;
}

sub _send {
    my ($self, $socket, $bytes) = @_;

    $log->tracef('>> %s', $bytes) if $log->is_trace;

    local $SIG{PIPE} = 'IGNORE';

    my $offset = 0;

    while ($offset < length $bytes) {
        my $num = syswrite $socket, $bytes, length($bytes) - $offset, $offset;

        unless (defined $num) {
            next if $! == EINTR;
            Carp::croak("write error: $!");
        }

        $offset += $num;
    }

    return;
}

sub _read {
    my ($self, $socket, $length) = @_;

    my $select = IO::Select->new($socket);
    my $buffer = '';

    while (length $buffer < $length) {
        $select->can_read($self->{timeout}) or Carp::croak("timeout after $self->{timeout}s");

        my $num = sysread $socket, $buffer, $length - length $buffer, length $buffer;

        unless (defined $num) {
            next if $! == EINTR;
            Carp::croak("read error: $!");
        }

        Carp::croak(sprintf 'connection closed (got %d of %d bytes)', length $buffer, $length) if $num == 0;
    }

    return $buffer;
}

sub _read_string {
    my ($self, $socket) = @_;
    my $length = hex $self->_read($socket, 4);
    return $length ? $self->_read($socket, $length) : '';
}

sub _encode_request {
    my $request = shift;
    Carp::croak('Request is undefined') unless defined $request;

    my $bytes = $request;
    utf8::downgrade($bytes, 1) or Carp::croak('Request contains wide characters; encode it to bytes first');

    my $length = length $bytes;
    Carp::croak("Request too long ($length bytes, max 65535)") if $length > 0xFFFF;

    return sprintf('%04x%s', $length, $bytes);
}

sub _request {
    my ($self, $socket, $request) = @_;

    $self->_send($socket, _encode_request($request));
    $self->_check_status($socket);

    return;
}

sub _check_status {
    my ($self, $socket) = @_;

    my $status = $self->_read($socket, 4);

    return if $status eq 'OKAY';

    Carp::croak('adb FAIL: ' . $self->_read_string($socket)) if $status eq 'FAIL';
    Carp::croak("unexpected status '$status'");
}


# Device selection

sub _extract_target {
    my $params = shift;
    my %target = map { exists $params->{$_} ? ($_ => delete $params->{$_}) : () } qw(serial usb tcp);

    Carp::croak("Use only one of 'serial', 'usb', 'tcp'") if keys %target > 1;
    croak_unknown_params($params);

    return %target;
}

sub _host_prefix {
    my ($self, %target) = @_;
    return "host-serial:$target{serial}" if defined $target{serial};
    return 'host-usb'                    if $target{usb};
    return 'host-local'                  if $target{tcp};
    return 'host';
}

sub _transport_request {
    my ($self, %target) = @_;
    return "host:transport:$target{serial}" if defined $target{serial};
    return 'host:transport-usb'             if $target{usb};
    return 'host:transport-local'           if $target{tcp};
    return 'host:transport-any';
}


# Services

sub _host_service {
    my ($self, $service) = @_;

    my $socket = $self->_open;
    $self->_request($socket, $service);

    my $response = $self->_read_string($socket);
    close $socket;

    return $response;
}

sub _host_command {
    my ($self, $service, %opts) = @_;

    my $socket = $self->_open;
    $self->_request($socket, $service);
    $self->_check_status($socket);

    my $response = $opts{reply} ? $self->_read_string($socket) : undef;
    close $socket;

    return $response;
}

sub _transport {
    my ($self, %target) = @_;

    my $socket = $self->_open;
    $self->_request($socket, $self->_transport_request(%target));

    return $socket;
}

sub _local_service {
    my ($self, $target, $service) = @_;

    my $socket = $self->_transport(%{$target});
    $self->_request($socket, $service);

    return $socket;
}


# Server

sub version { hex shift->_host_service('host:version') }

sub devices {
    my $self = shift;
    my $raw  = $self->_host_service('host:devices-l');

    my @devices = ();

    for my $line (split /\n/, $raw) {
        next unless $line;
        push @devices, _parse_device($line);
    }

    return wantlist(\@devices);
}

sub _parse_device {
    my $string = shift;

    my ($serial, $state, @attrs) = split /\s+/, $string;

    my %device = (serial => $serial, state => $state);

    foreach my $attr (@attrs) {
        my ($key, $value) = split(/:/, $attr, 2);
        $device{$key} = $value;
    }

    return \%device;
}

sub kill {
    my $self   = shift;
    my $socket = $self->_open;

    $self->_request($socket, 'host:kill');
    close $socket;

    return 1;
}


# Device

sub device {
    my ($self, %params) = @_;

    my %target = _extract_target(\%params);
    my $serial = $target{serial} // $self->serialno(%target);

    return Net::ADB::Device->new(client => $self, serial => $serial);
}

sub features {
    my ($self, %params) = @_;
    my %target   = _extract_target(\%params);
    my @features = split /,/, $self->_host_service($self->_host_prefix(%target) . ':features');
    return wantlist(\@features);
}

sub state {
    my ($self, %params) = @_;
    my %target = _extract_target(\%params);
    return $self->_host_service($self->_host_prefix(%target) . ':get-state');
}

sub serialno {
    my ($self, %params) = @_;
    my %target = _extract_target(\%params);
    return $self->_host_service($self->_host_prefix(%target) . ':get-serialno');
}

sub devpath {
    my ($self, %params) = @_;
    my %target = _extract_target(\%params);
    return $self->_host_service($self->_host_prefix(%target) . ':get-devpath');
}


# Port forwarding

sub forward {
    my ($self, %params) = @_;

    my $local    = delete $params{local};
    my $remote   = delete $params{remote};
    my $norebind = delete $params{norebind};

    my %target = _extract_target(\%params);

    Carp::croak("Missing 'local'")  unless defined $local  && length $local;
    Carp::croak("Missing 'remote'") unless defined $remote && length $remote;

    my $service = $self->_host_prefix(%target) . ':forward:' . ($norebind ? 'norebind:' : '') . "$local;$remote";

    # The server replies with the bound local port (useful with "tcp:0")
    return $self->_host_command($service, reply => 1);
}

sub killforward {
    my ($self, %params) = @_;

    my $local  = delete $params{local};
    my %target = _extract_target(\%params);

    Carp::croak("Missing 'local'") unless defined $local && length $local;

    $self->_host_command($self->_host_prefix(%target) . ":killforward:$local");

    return 1;
}

sub killforward_all {
    my ($self, %params) = @_;
    my %target = _extract_target(\%params);
    $self->_host_command($self->_host_prefix(%target) . ':killforward-all');
    return 1;
}

sub list_forward {
    my ($self, %params) = @_;

    my %target = _extract_target(\%params);
    my $raw    = $self->_host_service($self->_host_prefix(%target) . ':list-forward');

    my @res = ();

    for my $line (split /\n/, $raw) {
        next unless $line;
        my ($serial, $local, $remote) = split /\s+/, $line, 3;
        push @res, {serial => $serial, local => $local, remote => $remote};
    }

    return wantlist(\@res);
}


# Network

sub connect {
    my ($self, %params) = @_;

    my $host = delete $params{host};
    my $port = delete $params{port};

    Carp::croak("Missing 'host'") unless defined $host && length $host;
    croak_unknown_params(\%params);

    my $response = $self->_host_service('host:connect:' . _tcp_address($host, $port));

    # The server replies OKAY even when the connection fails: the outcome is in the message
    Carp::croak("adb connect: $response") unless $response =~ /^(?:already\s)?connected\sto\s/x;

    return $response;
}

sub disconnect {
    my ($self, %params) = @_;

    my $host = delete $params{host} // '';
    my $port = delete $params{port};

    Carp::croak("'port' requires 'host'") if defined $port && !length $host;
    croak_unknown_params(\%params);

    # An empty address disconnects every TCP/IP device
    return $self->_host_service('host:disconnect:' . _tcp_address($host, $port));
}

sub pair {
    my ($self, %params) = @_;

    my $host = delete $params{host};
    my $port = delete $params{port};
    my $code = delete $params{code};

    Carp::croak("Missing 'host'") unless defined $host && length $host;
    Carp::croak("Missing 'code'") unless defined $code && length $code;
    croak_unknown_params(\%params);

    my $socket = $self->_open;
    $self->_request($socket, "host:pair:$code:" . _tcp_address($host, $port));

    # pair_service replies with FAIL + message on error, or with the bare message on success
    my $head = $self->_read($socket, 4);
    Carp::croak('adb pair: ' . $self->_read_string($socket)) if $head eq 'FAIL';
    Carp::croak("unexpected reply '$head'") unless $head =~ /^[[:xdigit:]]{4}$/;

    my $response = $self->_read($socket, hex $head);
    close $socket;

    return $response;
}

sub _tcp_address {
    my ($host, $port) = @_;

    return $host unless defined $port;

    # IPv6
    $host = "[$host]" if $host =~ /:/ && $host !~ /^\[/;

    return "$host:$port";
}


# Shell

sub shell_v2 {
    my ($self, %params) = @_;

    my $command = delete $params{command};
    my $timeout = delete $params{timeout};
    my %target  = _extract_target(\%params);

    local $self->{timeout} = $timeout if defined $timeout;

    Carp::croak("Missing 'command'") unless defined $command && length $command;

    $log->debugf('shell %s: %s', $self->_transport_request(%target), $command) if $log->is_debug;

    my $start  = Time::HiRes::time;
    my $socket = $self->_local_service(\%target, "shell,v2:$command");

    my %result = (command => $command, stdout => '', stderr => '', exit => undef, duration => undef);

    while (1) {

        my $header = $self->_read($socket, SHELL_HEADER_SIZE);

        my ($id, $length) = unpack 'C V', $header;
        my $data = $length ? $self->_read($socket, $length) : '';

        if    ($id == SHELL_ID_STDOUT) { $result{stdout} .= $data }
        elsif ($id == SHELL_ID_STDERR) { $result{stderr} .= $data }
        elsif ($id == SHELL_ID_EXIT)   { $result{exit} = unpack 'C', $data; last }
        else                           { $log->warning("ignoring unknown shell packet id $id ($length bytes)") }

    }

    close $socket;

    $result{duration} = Time::HiRes::time - $start;

    my $res = Net::ADB::Shell::Result->new(%result);

    if ($log->is_debug) {
        $log->debugf(
            'shell exit %d in %.3fs (%d bytes stdout, %d bytes stderr)',
            $result{exit}, $result{duration},
            length $result{stdout},
            length $result{stderr}
        );
    }

    return $res;
}
1;

__END__

=encoding utf-8

=head1 NAME

Net::ADB - Client for ADB (Android Debug Bridge) Server

=head1 SYNOPSIS

    use Net::ADB;

    my $adb = Net::ADB->new;

    say $adb->version;    # 41

    # List the connected devices
    for my $device ($adb->devices) {
        say "$device->{serial} $device->{state}";
    }

    # Run a command on the only connected device
    my $res = $adb->shell_v2(command => 'getprop ro.product.model');

    say $res->stdout;       # Example Phone
    say $res->exit_code;    # 0

    # Select a device by serial, USB or TCP/IP
    $res = $adb->shell_v2(serial => 'emulator-5554', command => 'uptime');
    $res = $adb->shell_v2(usb    => 1,               command => 'uptime');

    # Connect a device over TCP/IP (Wi-Fi)
    $adb->connect(host => '192.168.0.10', port => 5555);

    # Forward a local port to the device
    my $port = $adb->forward(usb => 1, local => 'tcp:0', remote => 'tcp:8080');

    # Device-bound wrapper
    my $device = $adb->device(serial => 'emulator-5554');

    say $device->info->{model};


=head1 DESCRIPTION

L<Net::ADB> is a pure-Perl client for the ADB (Android Debug Bridge) server.

The ADB server is the background process started by the C<adb> command line
tool (C<adb start-server>), listening by default on C<127.0.0.1:5037>. It keeps
track of the connected Android devices (USB, TCP/IP, emulators) and relays the
requests of its clients to the C<adbd> daemon running on each device.

L<Net::ADB> speaks the ADB server protocol directly over TCP, without running
the C<adb> executable, so the server must already be running. Each method
opens a new connection to the server.

For more information about the ADB server protocol and services follow the
online documentation:

L<https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/master/docs/dev/services.md>


=head1 CONSTRUCTOR

=head2 new

    # Default ADB host & port (127.0.0.1:5037)
    my $adb = Net::ADB->new;

    # Specify ADB host, port and timeout
    my $adb = Net::ADB->new(host => '127.0.0.1', port => 5037, timeout => 10);

Create a new L<Net::ADB> instance.

Allowed parameters:

=over

=item * C<host>, ADB server host (default: C<127.0.0.1>).

=item * C<port>, ADB server port (default: C<5037>).

=item * C<timeout>, timeout in seconds for connecting to the server and for
each read (default: C<10>).

=back


=head1 DEVICE SELECTION

Methods that act on a device accept at most one of these parameters:

=over

=item * C<serial>, the device with the given serial, as listed by
L</devices> (e.g. C<emulator-5554>, C<192.168.0.10:5555>). Same as C<adb -s>.

=item * C<usb>, the only device connected via USB. Same as C<adb -d>.

=item * C<tcp>, the only device connected via TCP/IP (C<adb connect>,
wireless debugging, emulators). Same as C<adb -e>.

=back

    $adb->state(serial => 'emulator-5554');
    $adb->state(usb => 1);
    $adb->state(tcp => 1);

Without any of them, the only connected device is used. If the selection
matches no device, or more than one, the method croaks with the server
message (e.g. C<more than one device/emulator>).

With several devices of the same kind (e.g. two phones via USB), C<usb> and
C<tcp> croak as well: use C<serial>. L</devices> lists the serials, and USB
devices have the C<usb> attribute:

    for my $d ($adb->devices) {
        next unless $d->{state} eq 'device';

        my $via = exists $d->{usb} ? 'USB' : 'TCP/IP';
        say "$d->{serial} ($via): ", $adb->device(serial => $d->{serial})->info->{model};
    }

The serial identifies a connection, not a phone: the same phone connected
both via USB and Wi-Fi is listed twice, with two different serials. To group
the connections by phone, compare a device property such as C<ro.serialno>
(see L<Net::ADB::Device/info>):

    my %phones;

    for my $d (grep { $_->{state} eq 'device' } $adb->devices) {
        my $id = $adb->device(serial => $d->{serial})->info->{serial};
        push @{$phones{$id}}, $d->{serial};
    }

    # { 'EX0123456789' => ['EX0123456789', '192.168.0.10:5555'] }


=head1 METHODS

=head2 Server

=head3 version

    my $version = $adb->version;    # 41

Return the version of the ADB server as an integer: C<41> for the server
reported by C<adb version> as "1.0.41".

Same as C<adb version>, C<host:version> service.

=head3 devices

    my @devices = $adb->devices;

    for my $device (@devices) {
        say "$device->{serial} $device->{state}";
    }

    my $devices = $adb->devices;    # array reference

Return the list of devices known to the server (an array reference in scalar
context), one hash reference per device.

Each device has C<serial> and C<state> (C<device>, C<offline>,
C<unauthorized>, ...) plus the attributes reported by the server, such as
C<product>, C<model>, C<device>, C<transport_id> and, for USB devices, C<usb>.

    {
        serial       => '192.168.0.10:5555',
        state        => 'device',
        product      => 'example',
        model        => 'Example_Phone',
        device       => 'example',
        transport_id => '3'
    }

Same as C<adb devices -l>, C<host:devices-l> service.

=head3 kill

    $adb->kill;

Stop the ADB server and return C<1>. This module does not restart it: the
next C<adb> command (or C<adb start-server>) does.

Same as C<adb kill-server>, C<host:kill> service.


=head2 Device

=head3 device

    my $device = $adb->device;
    my $device = $adb->device(serial => 'emulator-5554');

    say $device->serial;    # emulator-5554

Return a L<Net::ADB::Device> instance bound to the selected device.

The serial is resolved when the instance is created, so the instance keeps
talking to the same device even if other devices are connected later. If the
device goes away (e.g. a wireless debugging device reconnects with a new
port), its methods croak and a new instance is needed.

Accepts the L</DEVICE SELECTION> parameters.

=head3 features

    my @features = $adb->features;
    my $features = $adb->features(serial => 'emulator-5554');    # array reference

    if (grep { $_ eq 'shell_v2' } @features) { ... }

Return the list of features supported by the device (e.g. C<shell_v2>,
C<cmd>, C<stat_v2>), or an array reference in scalar context.

Accepts the L</DEVICE SELECTION> parameters.

Same as C<adb features>, C<host:features> service.

=head3 state

    my $state = $adb->state(usb => 1);    # device

Return the state of the device (C<device>, C<offline>, C<unauthorized>,
C<bootloader>, C<recovery>, ...).

Accepts the L</DEVICE SELECTION> parameters.

Same as C<adb get-state>, C<host:get-state> service.

=head3 serialno

    my $serial = $adb->serialno(usb => 1);

Return the serial of the device. Useful to resolve C<usb> or C<tcp> to a
serial.

Accepts the L</DEVICE SELECTION> parameters.

Same as C<adb get-serialno>, C<host:get-serialno> service.

=head3 devpath

    my $devpath = $adb->devpath(usb => 1);    # usb:1-1

Return the device path (the USB port for USB devices).

Accepts the L</DEVICE SELECTION> parameters.

Same as C<adb get-devpath>, C<host:get-devpath> service.


=head2 Port forwarding

=head3 forward

    # Forward local port 8080 to port 80 on the device
    $adb->forward(local => 'tcp:8080', remote => 'tcp:80');

    # Let the server choose a free local port
    my $port = $adb->forward(local => 'tcp:0', remote => 'tcp:80');

    # Fail if tcp:8080 is already forwarded
    $adb->forward(local => 'tcp:8080', remote => 'tcp:80', norebind => 1);

Forward connections from C<local> (on the host) to C<remote> (on the device).
When a new TCP forward is created, return the local port, which is useful
with C<tcp:0>. A forward with the same C<local> is replaced, unless
C<norebind> is set.

Allowed parameters:

=over

=item * C<local>, local socket specification, e.g. C<tcp:E<lt>portE<gt>>
(C<tcp:0> chooses a free port), C<localabstract:E<lt>nameE<gt>>,
C<localfilesystem:E<lt>pathE<gt>> (I<required>).

=item * C<remote>, remote socket specification, e.g. C<tcp:E<lt>portE<gt>>,
C<localabstract:E<lt>nameE<gt>>, C<jdwp:E<lt>pidE<gt>> (I<required>).

=item * C<norebind>, croak if C<local> is already forwarded (default: C<0>).

=back

Accepts the L</DEVICE SELECTION> parameters.

Same as C<adb forward>, C<host:forward> service.

=head3 killforward

    $adb->killforward(local => 'tcp:8080');

Remove the forward of C<local> (I<required>) and return C<1>. Croaks if
C<local> is not forwarded.

Accepts the L</DEVICE SELECTION> parameters.

Same as C<adb forward --remove>, C<host:killforward> service.

=head3 killforward_all

    $adb->killforward_all;

Remove all forwards and return C<1>.

Accepts the L</DEVICE SELECTION> parameters.

Same as C<adb forward --remove-all>, C<host:killforward-all> service.

=head3 list_forward

    for my $forward ($adb->list_forward) {
        say "$forward->{serial} $forward->{local} $forward->{remote}";
    }

Return the list of forwards (an array reference in scalar context), one hash
reference per forward with C<serial>, C<local> and C<remote>.

Accepts the L</DEVICE SELECTION> parameters.

Same as C<adb forward --list>, C<host:list-forward> service.


=head2 Network

=head3 connect

    $adb->connect(host => '192.168.0.10', port => 5555);
    $adb->connect(host => '192.168.0.10:5555');

Connect to a device over TCP/IP and return the server message
(e.g. C<connected to 192.168.0.10:5555>). Croaks if the connection fails.

The device must listen on TCP/IP: enable it with C<adb tcpip 5555> over USB,
or use the port shown by wireless debugging (Android 11+, see L</pair>).

Allowed parameters:

=over

=item * C<host>, host name or IP address (IPv6 addresses are allowed), or
C<host:port> (I<required>).

=item * C<port>, TCP port (default: C<5555>).

=back

Same as C<adb connect>, C<host:connect> service.

=head3 disconnect

    $adb->disconnect(host => '192.168.0.10', port => 5555);

    # Disconnect all TCP/IP devices
    $adb->disconnect;

Disconnect a TCP/IP device and return the server message
(e.g. C<disconnected 192.168.0.10:5555>). Without C<host>, disconnect all
TCP/IP devices. Croaks if the device is not connected.

Allowed parameters:

=over

=item * C<host>, host name or IP address, or C<host:port>.

=item * C<port>, TCP port (requires C<host>).

=back

Same as C<adb disconnect>, C<host:disconnect> service.

=head3 pair

    my $message = $adb->pair(host => '192.168.0.10', port => 37099, code => '123456');

    $adb->connect(host => '192.168.0.10', port => 41235);

Pair with a device using wireless debugging (Android 11+) and return the
server message (e.g. C<Successfully paired to 192.168.0.10:37099 [guid=...]>).
Croaks if the pairing fails.

The pairing port and code are shown by "Pair device with pairing code" in the
wireless debugging settings. They differ from the port used by L</connect>,
which is shown on the main wireless debugging screen.

Allowed parameters:

=over

=item * C<host>, host name or IP address, or C<host:port> (I<required>).

=item * C<port>, pairing port.

=item * C<code>, pairing code (I<required>).

=back

Same as C<adb pair>, C<host:pair> service.


=head2 Shell

=head3 shell_v2

    my $res = $adb->shell_v2(command => 'ls /sdcard', timeout => 30);

    if ($res->is_error) {
        die 'ls failed: ' . $res->stderr;
    }

    print $res->stdout;

Run C<command> on the device with the shell protocol v2 and return a
L<Net::ADB::Shell::Result> instance (output, error output, exit code and
duration).

The command is run by the device shell (C</system/bin/sh>), so it can contain
pipes and redirections, and quoting is up to the caller. The output is
returned as bytes, without any decoding.

Requires the C<shell_v2> feature (Android 7.0+, see L</features>).

Allowed parameters:

=over

=item * C<command>, command to run (I<required>).

=item * C<timeout>, timeout in seconds for this call (default: the
C<timeout> of L</new>).

=back

Accepts the L</DEVICE SELECTION> parameters.

Same as C<adb shell>, C<shell,v2:> service.


=head1 RETURN VALUES

L</devices>, L</features> and L</list_forward> return a list in list context
and an array reference in scalar context. Inside a hash constructor or an
argument list the context is list, so use C<scalar> to get the reference:

    my %report = (devices => scalar $adb->devices);


=head1 ERRORS

All methods croak on error, with the server message when available
(e.g. C<adb FAIL: device 'emulator-5554' not found>):

    my $state = eval { $adb->state(serial => $serial) } or warn "Device not available: $@";


=head1 LOGGING

L<Net::ADB> logs via L<Log::Any>. Messages are discarded unless the
application selects an adapter:

    use Log::Any::Adapter ('Stderr', log_level => 'debug');


=head1 SEE ALSO

=over

=item * L<Net::ADB::Device>

=item * L<Net::ADB::Shell::Result>

=item * L<https://developer.android.com/tools/adb>

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-ADB/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-ADB>

    git clone https://github.com/giterlizzi/perl-Net-ADB.git

=head1 AUTHOR

=over

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Giuseppe Di Terlizzi.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
