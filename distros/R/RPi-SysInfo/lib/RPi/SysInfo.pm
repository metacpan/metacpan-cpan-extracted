package RPi::SysInfo;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '1.02';

require XSLoader;
XSLoader::load('RPi::SysInfo', $VERSION);

use Exporter qw(import);

our @EXPORT_OK = qw(
    core_temp
    cpu_percent
    mem_percent
    gpio_info
    raspi_config
    network_info
    file_system
    pi_details
    pi_model
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

sub new {
    return bless {}, shift;
}
sub core_temp {
    shift if $_[0] && $_[0] =~ /RPi::/;

    my ($degree) = @_;

    $degree //= 'c';

    my $temp = _core_temp_c();

    return '' if ! defined $temp;

    if ($degree eq 'f' || $degree eq 'F'){
        $temp = ($temp * 1.8) + 32;
    }

    chomp $temp;
    return $temp;
}
sub cpu_percent {
    return _format(cpuPercent());
}
sub gpio_info {
    shift if $_[0] && $_[0] =~ /RPi::/;

    my ($pins) = @_;

    $pins = ! defined $pins
        ? ''
        : join ",", @$pins;

    # raspi-gpio was removed from current Raspberry Pi OS in favour of pinctrl,
    # and never existed for the Pi 5 / RP1. Prefer pinctrl, falling back to
    # raspi-gpio on older systems that still ship it. Both accept the same
    # "get [pin[,pin...]]" invocation.

    my $tool = _gpio_tool();

    return '' if ! defined $tool;

    my $info = _run("$tool get $pins");

    chomp $info;
    return $info;
}
sub file_system {
    my $fs_info = _run('df') . "\n";
    $fs_info .= _slurp('/proc/swaps') // '';
    return $fs_info;
}
sub mem_percent {
    return _format(memPercent());
}
sub network_info {

    # ifconfig (net-tools) is the legacy default, but modern Raspberry Pi OS
    # Lite ships without it, so fall back to `ip addr`, which is always present.
    # Both forms carry inet/inet6 lines.

    my $tool = _net_tool();

    return '' if ! defined $tool;

    my $netinfo = _run($tool);

    chomp $netinfo;
    return $netinfo;
}
sub pi_details {

    my $details;

    $details = "\n"
             . _run('cat /sys/firmware/devicetree/base/model')
             . "\n\n"
             . _run('cat /etc/os-release | head -4')
             . "\n"
             . _run('uname -a')
             . "\n"
             . _run('cat /proc/cpuinfo | tail -3')
             . "Board           : " . pi_model() . "\n"
             . "SoC / RAM       : " . _board_summary() . "\n"
             . "Throttled flag  : " . _run('vcgencmd get_throttled')
             . "Camera          : " . _camera_info() . "\n";

    return $details;
}
sub pi_model {
    shift if $_[0] && $_[0] =~ /RPi::/;

    # Normalized Raspberry Pi marketing name, e.g. "Raspberry Pi 5 Model B Rev
    # 1.1". The devicetree model is authoritative on the Pi 0-5, so prefer it,
    # falling back to a /proc/cpuinfo Revision-code decode, then to 'Unknown'.

    my $model = _slurp('/sys/firmware/devicetree/base/model');

    if (defined $model){
        $model =~ s/\0//g;              # Devicetree strings are NUL-terminated.
        $model =~ s/^\s+|\s+$//g;
        return $model if length $model;
    }

    my $info = _decode_revision(_cpuinfo_field('Revision'));

    return $info->{name} if defined $info->{name};

    return 'Unknown';
}
sub raspi_config {
    my $config = _run('vcgencmd get_config int');
    $config .= _run('vcgencmd get_config str');

    # config.txt moved from /boot to /boot/firmware on Bookworm and later (the
    # old path now holds only a "this file has moved" stub), so resolve the
    # real location before appending the user's non-comment directives.

    my $config_file = _config_file();

    if (defined $config_file){
        $config .= _run("grep -E -v '^\\s*(#|^\$)' $config_file");
    }

    chomp $config;
    return $config;
}

sub _board_summary {
    # Human-readable decode of the SoC, RAM and RP1 presence pulled from the
    # /proc/cpuinfo Revision code. Used to enrich pi_details(). Returns
    # 'unknown' when the revision can't be decoded.

    my $info = _decode_revision(_cpuinfo_field('Revision'));

    my @parts;

    push @parts, $info->{soc}          if defined $info->{soc};
    push @parts, $info->{mem}          if defined $info->{mem};
    push @parts, 'RP1'                 if $info->{rp1};
    push @parts, $info->{manufacturer} if defined $info->{manufacturer};

    return @parts ? join(', ', @parts) : 'unknown';
}
sub _camera_info {
    # Legacy firmware (Pi 0-4 on Bullseye and earlier) answered
    # `vcgencmd get_camera` with "supported=N detected=N". On Bookworm and the
    # Pi 5 that command was removed and camera support moved to libcamera, so
    # fall back to a libcamera probe. Returns a one-line string (no newline).

    local $SIG{__WARN__} = sub {
        my $warning = shift;
        warn $warning if $warning !~ /Can't exec "vcgencmd"/;
    };

    my $legacy = _run('vcgencmd get_camera');

    if ($legacy =~ /supported=/){
        $legacy =~ s/\s+$//;
        return $legacy;
    }

    my $tool = _camera_tool();

    if (defined $tool){
        my $list = _run("$tool --list-cameras 2>/dev/null");

        return 'detected (libcamera)' if $list =~ /Available cameras/i;
        return 'none detected (libcamera)';
    }

    return 'not detected';
}
sub _camera_tool {
    # libcamera's listing utility: rpicam-hello on Bookworm and later, renamed
    # from the Bullseye-era libcamera-hello.

    return _first_tool(qw(rpicam-hello libcamera-hello));
}
sub _config_file {
    # Locate the active config.txt. Bookworm and later moved it to
    # /boot/firmware/config.txt; older systems keep it at /boot/config.txt.

    for my $file ('/boot/firmware/config.txt', '/boot/config.txt'){
        return $file if -f $file;
    }

    return undef;
}
sub _core_temp_c {
    # Core temperature in Celsius as a number, or undef if unavailable. Prefers
    # vcgencmd (the value the Pi tooling reports), falling back to the kernel
    # thermal zone on systems without vcgencmd.

    local $SIG{__WARN__} = sub {
        my $warning = shift;
        warn $warning if $warning !~ /Can't exec "vcgencmd"/;
    };

    my $temp = _run('vcgencmd measure_temp');

    return $1 if $temp =~ /temp=([\d.]+)/;

    # /sys/class/thermal/thermal_zone0/temp reports millidegrees Celsius.

    my $milli = _slurp('/sys/class/thermal/thermal_zone0/temp');

    return $1 / 1000 if defined $milli && $milli =~ /^(\d+)/;

    return undef;
}
sub _cpuinfo_field {
    my ($field) = @_;

    croak "_cpuinfo_field() requires a field name\n" if ! defined $field;

    my $cpuinfo = _slurp('/proc/cpuinfo');

    return undef if ! defined $cpuinfo;

    for my $line (split /\n/, $cpuinfo){
        return $1 if $line =~ /^\Q$field\E\s*:\s*(.+?)\s*$/;
    }

    return undef;
}
sub _decode_revision {
    my ($rev) = @_;

    return {} if ! defined $rev;

    $rev =~ s/^\s+|\s+$//g;

    return {} if $rev !~ /^[0-9a-fA-F]+$/;

    $rev = hex($rev);

    my %info;

    if ($rev & 0x800000){
        # New-style revision code (Pi 2 and later, plus late Pi 1 boards).
        my $type  = ($rev >> 4)  & 0xff;
        my $proc  = ($rev >> 12) & 0x0f;
        my $mfr   = ($rev >> 16) & 0x0f;
        my $mem   = ($rev >> 20) & 0x07;
        my $minor = $rev & 0x0f;

        my %types = (
            0x00 => 'A',         0x01 => 'B',          0x02 => 'A+',
            0x03 => 'B+',        0x04 => '2 Model B',  0x06 => 'Compute Module 1',
            0x08 => '3 Model B', 0x09 => 'Zero',       0x0a => 'Compute Module 3',
            0x0c => 'Zero W',    0x0d => '3 Model B+', 0x0e => '3 Model A+',
            0x10 => 'Compute Module 3+', 0x11 => '4 Model B',
            0x12 => 'Zero 2 W',  0x13 => '400',        0x14 => 'Compute Module 4',
            0x15 => 'Compute Module 4S', 0x17 => '5 Model B',
            0x18 => 'Compute Module 5',  0x19 => '500',
        );
        my %procs = (
            0 => 'BCM2835', 1 => 'BCM2836', 2 => 'BCM2837',
            3 => 'BCM2711', 4 => 'BCM2712',
        );
        my %mfrs = (
            0 => 'Sony UK', 1 => 'Egoman', 2 => 'Embest',
            3 => 'Sony Japan', 4 => 'Embest', 5 => 'Stadium',
        );

        $info{new_style}    = 1;
        $info{type}         = $types{$type};
        $info{soc}          = $procs{$proc};
        $info{manufacturer} = $mfrs{$mfr};
        $info{revision}     = $minor;
        $info{mem}          = _mem_human(256 << $mem);
        $info{rp1}          = $proc == 4 ? 1 : 0;
        $info{name}         = defined $types{$type}
            ? "Raspberry Pi $types{$type}"
            : undef;
    }
    else {
        # Old-style revision code (original Pi 1 / early boards). A small
        # lookup of the common ones; everything else is left to the devicetree
        # model. All old-style boards are BCM2835, pre-RP1.
        my %old = (
            0x0002 => ['B',  '256MB'], 0x0003 => ['B',  '256MB'],
            0x0004 => ['B',  '256MB'], 0x0005 => ['B',  '256MB'],
            0x0006 => ['B',  '256MB'], 0x0007 => ['A',  '256MB'],
            0x0008 => ['A',  '256MB'], 0x0009 => ['A',  '256MB'],
            0x000d => ['B',  '512MB'], 0x000e => ['B',  '512MB'],
            0x000f => ['B',  '512MB'], 0x0010 => ['B+', '512MB'],
            0x0011 => ['Compute Module 1', '512MB'],
            0x0012 => ['A+', '256MB'], 0x0013 => ['B+', '512MB'],
            0x0014 => ['Compute Module 1', '512MB'],
            0x0015 => ['A+', '256MB'],
        );

        $info{new_style} = 0;
        $info{soc}       = 'BCM2835';
        $info{rp1}       = 0;

        if (my $entry = $old{$rev}){
            $info{type} = $entry->[0];
            $info{mem}  = $entry->[1];
            $info{name} = "Raspberry Pi $entry->[0]";
        }
    }

    return \%info;
}
sub _first_tool {
    # Returns the first of the given executable names found on PATH, else undef.

    for my $tool (@_){
        for my $dir (split /:/, $ENV{PATH} // ''){
            return $tool if -x "$dir/$tool";
        }
    }

    return undef;
}
sub _format {
    croak "_format() requires a float/double sent in\n" if ! defined $_[0];
    return sprintf("%.2f", $_[0]);
}
sub _gpio_tool {
    # Locate a GPIO query tool on PATH. pinctrl is the current Raspberry Pi OS
    # utility; raspi-gpio is the legacy one kept here as a fallback.

    return _first_tool(qw(pinctrl raspi-gpio));
}
sub _mem_human {
    my ($mb) = @_;

    return undef if ! defined $mb;

    return $mb % 1024 == 0
        ? ($mb / 1024) . 'GB'
        : $mb . 'MB';
}
sub _net_tool {
    # Locate a network-interface query command. ifconfig (net-tools) is the
    # legacy default; fall back to `ip addr` on systems without it.

    return 'ifconfig' if defined _first_tool('ifconfig');
    return 'ip addr'  if defined _first_tool('ip');

    return undef;
}
sub _run {
    my ($cmd) = @_;

    croak "_run() requires a command string\n" if ! defined $cmd;

    my $out = `$cmd`;

    return defined $out ? $out : '';
}
sub _slurp {
    my ($file) = @_;

    croak "_slurp() requires a file path\n" if ! defined $file;

    open my $fh, '<', $file or return undef;
    local $/;
    my $data = <$fh>;
    close $fh;

    return $data;
}

1;
__END__

=head1 NAME

RPi::SysInfo - Retrieve hardware system information from a Raspberry Pi

=head1 DESCRIPTION

Fetch live-time and other system information from a Raspberry Pi.

Verified across the Raspberry Pi 3, 4 and 5 (the latter driven by the RP1 I/O
controller), and across the Raspberry Pi OS releases from Buster through
Bookworm/Trixie. Where tools or file locations changed between generations
(C<raspi-gpio> to C<pinctrl>, C</boot/config.txt> to C</boot/firmware/config.txt>,
the legacy C<vcgencmd get_camera> to libcamera, C<ifconfig> to C<ip>), the
relevant function selects whatever is present, preferring the modern tool and
falling back to the legacy one.

Most functions will work equally as well on Unix/Linux systems.

=head1 SYNOPSIS

    # Object Oriented

    use RPi::SysInfo;

    my $sys = RPi::SysInfo->new;
    say $sys->cpu_percent;
    say $sys->mem_percent;
    say $sys->core_temp;

    # Functional

    use RPi::SysInfo qw(:all);

    say cpu_percent();
    say mem_percent();
    say core_temp();

=head1 EXPORT_OK

Functions are not exported by default. You can load them each by name:

    cpu_percent
    mem_percent
    core_temp
    gpio_info
    raspi_config
    network_info
    file_system
    pi_details
    pi_model

...or use the C<:all> tag to bring them all in at once.

=head1 FUNCTIONS/METHODS

=head2 new

Instantiates and returns a new L<RPi::SysInfo> object.

Takes no parameters.

=head2 cpu_percent

Returns the percentage of current CPU usage.

Takes no parameters.

Return: Two decimal floating point number.

=head2 mem_percent

Returns the percentage of physical RAM currently in use.

Takes no parameters.

Return: Two decimal floating point number.

=head2 core_temp($scale)

Returns the core CPU temperature of the system.

The value comes from C<vcgencmd measure_temp> where available, falling back to
the kernel thermal zone (C</sys/class/thermal/thermal_zone0/temp>) on systems
without C<vcgencmd>. Returns an empty string if neither source is readable.

Parameters:

    $scale

Optional, String: By default we return the temperature in Celcius. Simply send
in the letter C<f> to get the result returned in Fahrenheit.

Return: Two decimal place floating point number.

=head2 gpio_info([$pins])

Fetches the current configuration and status of one or many GPIO pins.

Parameters:

    $pins

Optional, Aref of Integers: By default, we'll return the information for all
GPIO pins on the system. Send in an aref of pin numbers and well fetch the data
for only those pins (eg: C<gpio_info[1]> or C<gpio_info([2, 4, 6, 8])>).

The data is collected with C<pinctrl> (the current Raspberry Pi OS GPIO tool,
and the only one available on the Pi 5 / RP1), falling back to the legacy
C<raspi-gpio> on older systems that still ship it. If neither tool is present,
an empty string is returned.

Return: Single string containing all of the data requested.

=head2 raspi_config

Feteches the directive names and values the Pi is configured with. This includes
the live C<vcgencmd get_config> values plus the non-comment directives from the
active C<config.txt> (C</boot/firmware/config.txt> on Bookworm and later,
falling back to C</boot/config.txt>).

Takes no parameters.

Return: String, the contents of the current configuration.

=head2 file_system

Fetches and returns various file system information as a string.

=head2 network_info

Fetches and returns the Pi's network configuration details as a string.

The data comes from C<ifconfig> where the C<net-tools> package is installed,
falling back to C<ip addr> (always present on current Raspberry Pi OS) when it
is not. Returns an empty string if neither is available.

=head2 pi_details

Fetches and returns various information about the Pi, including the OS info,
along with several hardware platform details as a string.

Includes the devicetree model, the C<os-release> banner, C<uname>, the tail of
C</proc/cpuinfo>, a decoded board summary (see L</pi_model> and the SoC/RAM/RP1
decode), the throttled flag, and camera status. Camera status uses the legacy
C<vcgencmd get_camera> on older firmware, falling back to a libcamera probe
(C<rpicam-hello>/C<libcamera-hello>) on Bookworm and the Pi 5 where the legacy
command was removed.

=head2 pi_model

Returns the normalized Raspberry Pi marketing name as a string, eg.
C<Raspberry Pi 5 Model B Rev 1.1>.

Takes no parameters.

The name is read from the devicetree model (authoritative on the Pi 0-5),
falling back to a decode of the C</proc/cpuinfo> C<Revision> code, and finally
to C<Unknown> if the board can't be identified.

Return: String.

=head1 PRIVATE FUNCTIONS/METHODS

=head2 _board_summary

Returns a human-readable C<SoC, RAM, RP1, manufacturer> summary decoded from the
C</proc/cpuinfo> C<Revision> code, or C<unknown> if it can't be decoded. Used to
enrich L</pi_details>.

=head2 _camera_info

Returns a one-line camera status string. Tries the legacy C<vcgencmd get_camera>
first (older firmware), then a libcamera probe via L</_camera_tool>, then
C<not detected>.

=head2 _camera_tool

Returns the name of the libcamera listing utility found on C<PATH>:
C<rpicam-hello> (Bookworm and later) or C<libcamera-hello> (Bullseye), else
C<undef>.

=head2 _config_file

Returns the path to the active C<config.txt>, preferring the Bookworm-and-later
C</boot/firmware/config.txt> and falling back to the legacy C</boot/config.txt>.
Returns C<undef> if neither exists.

=head2 _core_temp_c

Returns the core temperature in Celsius as a number, or C<undef> if unavailable.
Prefers C<vcgencmd measure_temp>, falling back to the kernel thermal zone.

=head2 _cpuinfo_field($field)

Returns the value of the named field from C</proc/cpuinfo> (eg. C<Revision>,
C<Serial>, C<Model>), or C<undef> if the field or the file is absent.

Parameters:

    $field

Mandatory, String: The C</proc/cpuinfo> field name to look up.

=head2 _decode_revision($revision)

Decodes a C</proc/cpuinfo> C<Revision> code (hex string) into a hashref of board
attributes (C<name>, C<type>, C<soc>, C<mem>, C<manufacturer>, C<revision>,
C<rp1>, C<new_style>). Handles both the new-style (Pi 2+) and old-style (early
Pi 1) encodings. Returns an empty hashref for an undefined or non-hex value.

Parameters:

    $revision

Mandatory, String: The hex revision code.

=head2 _first_tool(@names)

Returns the first of the given executable names found on the C<PATH>, or
C<undef> if none are present.

=head2 _format($float)

Formats a float/double value to two decimal places.

Parameters:

    $float

Mandatory, Float/Double: The number to format.

=head2 _gpio_tool

Returns the name of the GPIO query tool found on C<PATH>: C<pinctrl> by
preference, else the legacy C<raspi-gpio>. Returns C<undef> if neither is
installed.

=head2 _mem_human($megabytes)

Formats a memory size in megabytes as a human string (eg. C<512MB>, C<8GB>).
Returns C<undef> for an undefined input.

Parameters:

    $megabytes

Mandatory, Integer: The memory size in megabytes.

=head2 _net_tool

Returns the network-interface query command found on C<PATH>: C<ifconfig> by
preference, else C<ip addr>. Returns C<undef> if neither is installed.

=head2 _run($cmd)

Runs a shell command and returns its output as a string (empty string if the
command produced none or failed to execute). The single seam through which all
external commands are executed, so tests can override it.

Parameters:

    $cmd

Mandatory, String: The command to run.

=head2 _slurp($file)

Reads and returns the entire contents of a file, or C<undef> if it can't be
opened. The single seam through which all direct file reads happen, so tests
can override it.

Parameters:

    $file

Mandatory, String: The path to read.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019-2026 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
