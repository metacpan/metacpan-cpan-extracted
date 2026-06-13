use warnings;
use strict;

use Test::More;
use File::Temp qw(tempdir);

use RPi::SysInfo qw(:all);

# These tests exercise the parsing/decode/selection logic directly, with the
# external command (_run) and file (_slurp) seams overridden. They need NO Pi
# hardware, so they run everywhere and give us Pi 3/4/5 coverage on any board.

no warnings 'redefine';

# ---------------------------------------------------------------------------
# _decode_revision()
# ---------------------------------------------------------------------------

{
    my %expect = (
        d04171 => {                                 # Pi 5 8GB
            name => 'Raspberry Pi 5 Model B', type => '5 Model B',
            soc  => 'BCM2712', mem => '8GB', rp1 => 1, new_style => 1,
            manufacturer => 'Sony UK', revision => 1,
        },
        c03112 => {                                 # Pi 4 4GB
            name => 'Raspberry Pi 4 Model B', type => '4 Model B',
            soc  => 'BCM2711', mem => '4GB', rp1 => 0, new_style => 1,
        },
        a02082 => {                                 # Pi 3B 1GB
            name => 'Raspberry Pi 3 Model B', type => '3 Model B',
            soc  => 'BCM2837', mem => '1GB', rp1 => 0, new_style => 1,
        },
        a020d3 => {                                 # Pi 3B+ 1GB
            name => 'Raspberry Pi 3 Model B+', soc => 'BCM2837', mem => '1GB',
        },
        '9000c1' => {                               # Zero W 512MB
            name => 'Raspberry Pi Zero W', soc => 'BCM2835', mem => '512MB',
            rp1  => 0,
        },
        c03130 => {                                 # Pi 400 4GB
            name => 'Raspberry Pi 400', type => '400', soc => 'BCM2711',
            mem  => '4GB',
        },
    );

    for my $rev (sort keys %expect){
        my $got = RPi::SysInfo::_decode_revision($rev);
        for my $k (sort keys %{$expect{$rev}}){
            is $got->{$k}, $expect{$rev}{$k}, "_decode_revision($rev) $k = $expect{$rev}{$k}";
        }
    }

    # New-style 8GB through to old 256MB memory decode.
    is RPi::SysInfo::_decode_revision('a22082')->{mem}, '1GB',  "mem bits decode (Embest Pi3)";

    # Whitespace and uppercase are tolerated.
    is RPi::SysInfo::_decode_revision("  a02082  ")->{name}, 'Raspberry Pi 3 Model B', "leading/trailing space tolerated";
    is RPi::SysInfo::_decode_revision('A02082')->{name},     'Raspberry Pi 3 Model B', "uppercase hex tolerated";

    # Old-style codes.
    my $oldbplus = RPi::SysInfo::_decode_revision('0010');
    is $oldbplus->{name},      'Raspberry Pi B+', "old-style 0x0010 name";
    is $oldbplus->{soc},       'BCM2835',         "old-style soc is BCM2835";
    is $oldbplus->{rp1},       0,                 "old-style is never RP1";
    is $oldbplus->{new_style}, 0,                 "old-style flagged new_style=0";

    # Old-style but unknown code: still BCM2835, no name.
    my $oldunknown = RPi::SysInfo::_decode_revision('0099');
    is $oldunknown->{new_style}, 0,       "unknown old-style new_style=0";
    is $oldunknown->{soc},      'BCM2835', "unknown old-style soc BCM2835";
    is $oldunknown->{name},      undef,    "unknown old-style has no name";

    # Unknown new-style type: soc/mem decode, but no marketing name.
    my $newunknown = RPi::SysInfo::_decode_revision('d0ff71');
    is $newunknown->{new_style}, 1,     "unknown new-style new_style=1";
    is $newunknown->{name},      undef, "unknown new-style type yields no name";

    # Garbage / undef inputs return an empty hashref.
    is_deeply RPi::SysInfo::_decode_revision(undef), {}, "undef revision => {}";
    is_deeply RPi::SysInfo::_decode_revision(''),    {}, "empty revision => {}";
    is_deeply RPi::SysInfo::_decode_revision('xyz'), {}, "non-hex revision => {}";
    is_deeply RPi::SysInfo::_decode_revision('  '),  {}, "whitespace-only revision => {}";
}

# ---------------------------------------------------------------------------
# _mem_human()
# ---------------------------------------------------------------------------

{
    my %m = (
        256 => '256MB', 512 => '512MB', 1024 => '1GB', 2048 => '2GB',
        4096 => '4GB', 8192 => '8GB', 1536 => '1536MB',
    );
    is RPi::SysInfo::_mem_human($_), $m{$_}, "_mem_human($_) = $m{$_}" for sort { $a <=> $b } keys %m;
    is RPi::SysInfo::_mem_human(undef), undef, "_mem_human(undef) = undef";
}

# ---------------------------------------------------------------------------
# _cpuinfo_field()
# ---------------------------------------------------------------------------

{
    my $cpuinfo = "processor\t: 0\n\nHardware\t: BCM2835\nRevision\t: a02082\n"
                . "Serial\t\t: 00000000abcdef01\nModel\t\t: Raspberry Pi 3 Model B Rev 1.2\n";

    local *RPi::SysInfo::_slurp = sub { $cpuinfo };

    is RPi::SysInfo::_cpuinfo_field('Revision'), 'a02082', "_cpuinfo_field(Revision)";
    is RPi::SysInfo::_cpuinfo_field('Serial'),   '00000000abcdef01', "_cpuinfo_field(Serial)";
    is RPi::SysInfo::_cpuinfo_field('Model'),     'Raspberry Pi 3 Model B Rev 1.2', "_cpuinfo_field(Model)";
    is RPi::SysInfo::_cpuinfo_field('Hardware'),  'BCM2835', "_cpuinfo_field(Hardware)";
    is RPi::SysInfo::_cpuinfo_field('Nope'),       undef, "_cpuinfo_field(missing) = undef";

    local *RPi::SysInfo::_slurp = sub { undef };
    is RPi::SysInfo::_cpuinfo_field('Revision'), undef, "_cpuinfo_field with no /proc/cpuinfo = undef";

    eval { RPi::SysInfo::_cpuinfo_field(undef) };
    like $@, qr/requires a field name/, "_cpuinfo_field(undef) croaks";
}

# ---------------------------------------------------------------------------
# _format()
# ---------------------------------------------------------------------------

is RPi::SysInfo::_format(12.345),  '12.35',  "_format rounds 12.345 -> 12.35";
is RPi::SysInfo::_format(99.999),  '100.00', "_format rounds 99.999 -> 100.00";
is RPi::SysInfo::_format(0),       '0.00',   "_format 0 -> 0.00";
is RPi::SysInfo::_format(-1.5),    '-1.50',  "_format negative";
eval { RPi::SysInfo::_format(undef) };
like $@, qr/requires a float/, "_format(undef) croaks";

# ---------------------------------------------------------------------------
# _mem_human edge already covered; _first_tool() with a real temp executable
# ---------------------------------------------------------------------------

{
    my $dir = tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/faketool" or die $!;
    print $fh "#!/bin/sh\n";
    close $fh;
    chmod 0755, "$dir/faketool";

    local $ENV{PATH} = $dir;
    is RPi::SysInfo::_first_tool('faketool'),          'faketool', "_first_tool finds an executable";
    is RPi::SysInfo::_first_tool('nope', 'faketool'),  'faketool', "_first_tool prefers earlier, falls through";
    is RPi::SysInfo::_first_tool('nope'),               undef,     "_first_tool returns undef when absent";

    local $ENV{PATH} = '';
    is RPi::SysInfo::_first_tool('faketool'), undef, "_first_tool with empty PATH = undef";
}

# ---------------------------------------------------------------------------
# Tool selectors: _gpio_tool / _net_tool / _camera_tool precedence
# ---------------------------------------------------------------------------

{
    my %present;
    local *RPi::SysInfo::_first_tool = sub {
        for my $t (@_){ return $t if $present{$t} }
        return undef;
    };

    # gpio: pinctrl preferred over raspi-gpio
    %present = (pinctrl => 1, 'raspi-gpio' => 1);
    is RPi::SysInfo::_gpio_tool(), 'pinctrl', "_gpio_tool prefers pinctrl";
    %present = ('raspi-gpio' => 1);
    is RPi::SysInfo::_gpio_tool(), 'raspi-gpio', "_gpio_tool falls back to raspi-gpio";
    %present = ();
    is RPi::SysInfo::_gpio_tool(), undef, "_gpio_tool undef when neither present";

    # net: ifconfig preferred, else 'ip addr'
    %present = (ifconfig => 1, ip => 1);
    is RPi::SysInfo::_net_tool(), 'ifconfig', "_net_tool prefers ifconfig";
    %present = (ip => 1);
    is RPi::SysInfo::_net_tool(), 'ip addr', "_net_tool falls back to ip addr";
    %present = ();
    is RPi::SysInfo::_net_tool(), undef, "_net_tool undef when neither present";

    # camera: rpicam-hello preferred over libcamera-hello
    %present = ('rpicam-hello' => 1, 'libcamera-hello' => 1);
    is RPi::SysInfo::_camera_tool(), 'rpicam-hello', "_camera_tool prefers rpicam-hello";
    %present = ('libcamera-hello' => 1);
    is RPi::SysInfo::_camera_tool(), 'libcamera-hello', "_camera_tool falls back to libcamera-hello";
    %present = ();
    is RPi::SysInfo::_camera_tool(), undef, "_camera_tool undef when neither present";
}

# ---------------------------------------------------------------------------
# _core_temp_c() + core_temp(): vcgencmd, thermal fallback, F/C conversion
# ---------------------------------------------------------------------------

{
    # vcgencmd path
    local *RPi::SysInfo::_run   = sub { "temp=49.9'C\n" };
    local *RPi::SysInfo::_slurp = sub { die "should not reach thermal" };
    is RPi::SysInfo::_core_temp_c(), '49.9', "_core_temp_c via vcgencmd";
    is core_temp(),     '49.9',  "core_temp() Celsius via vcgencmd";
    is core_temp('f'),  '121.82', "core_temp('f') Fahrenheit conversion";
    is core_temp('F'),  '121.82', "core_temp('F') accepts uppercase";
}
{
    # thermal fallback when vcgencmd produces no temp= line
    local *RPi::SysInfo::_run   = sub { 'error=1 error_msg="Command not registered"' };
    local *RPi::SysInfo::_slurp = sub { "47950\n" };
    is RPi::SysInfo::_core_temp_c(), 47.95, "_core_temp_c thermal fallback (millidegrees)";
    like core_temp(), qr/^\d+\.\d+$/, "core_temp() formats thermal fallback";
}
{
    # F/C exact relationship on a controlled value
    local *RPi::SysInfo::_run   = sub { "temp=20.0'C\n" };
    local *RPi::SysInfo::_slurp = sub { undef };
    my $c = core_temp();
    my $f = core_temp('f');
    is $c, '20.0', "controlled Celsius (vcgencmd precision preserved)";
    is $f, 68,     "controlled Fahrenheit = C*1.8+32";
    cmp_ok $f, '>', $c, "Fahrenheit exceeds Celsius";
}
{
    # neither source available
    local *RPi::SysInfo::_run   = sub { '' };
    local *RPi::SysInfo::_slurp = sub { undef };
    is RPi::SysInfo::_core_temp_c(), undef, "_core_temp_c undef when no source";
    is core_temp(), '', "core_temp() returns '' when temp unavailable";
}

# ---------------------------------------------------------------------------
# _camera_info(): legacy, libcamera-present, libcamera-empty, none
# ---------------------------------------------------------------------------

{
    # legacy firmware answers get_camera
    local *RPi::SysInfo::_run = sub { "supported=1 detected=1\n" };
    is RPi::SysInfo::_camera_info(), 'supported=1 detected=1', "_camera_info legacy get_camera passthrough";
}
{
    # get_camera dead, libcamera lists a camera
    local *RPi::SysInfo::_camera_tool = sub { 'rpicam-hello' };
    local *RPi::SysInfo::_run = sub {
        my ($cmd) = @_;
        return 'error=1 error_msg="Command not registered"' if $cmd =~ /get_camera/;
        return "Available cameras\n-----------------\n0 : imx708\n"  if $cmd =~ /--list-cameras/;
        return '';
    };
    is RPi::SysInfo::_camera_info(), 'detected (libcamera)', "_camera_info detects via libcamera";
}
{
    # get_camera dead, libcamera present but no cameras
    local *RPi::SysInfo::_camera_tool = sub { 'rpicam-hello' };
    local *RPi::SysInfo::_run = sub {
        my ($cmd) = @_;
        return 'error=1' if $cmd =~ /get_camera/;
        return "No cameras available!\n" if $cmd =~ /--list-cameras/;
        return '';
    };
    is RPi::SysInfo::_camera_info(), 'none detected (libcamera)', "_camera_info reports no libcamera camera";
}
{
    # get_camera dead and no libcamera tool
    local *RPi::SysInfo::_camera_tool = sub { undef };
    local *RPi::SysInfo::_run = sub { 'error=1' };
    is RPi::SysInfo::_camera_info(), 'not detected', "_camera_info not detected when nothing available";
}

# ---------------------------------------------------------------------------
# _run() / _slurp() seams themselves
# ---------------------------------------------------------------------------

is RPi::SysInfo::_run('echo hi'),       "hi\n", "_run captures stdout";
is RPi::SysInfo::_run('true'),          '',     "_run empty output => ''";
is RPi::SysInfo::_run('exit 3; echo x'),'',     "_run failing command => '' (defined)";
eval { RPi::SysInfo::_run(undef) };
like $@, qr/requires a command/, "_run(undef) croaks";

{
    my $dir = tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/f" or die $!;
    print $fh "line1\nline2\n";
    close $fh;
    is RPi::SysInfo::_slurp("$dir/f"), "line1\nline2\n", "_slurp reads whole file";
    is RPi::SysInfo::_slurp("$dir/nope"), undef, "_slurp missing file => undef";
    eval { RPi::SysInfo::_slurp(undef) };
    like $@, qr/requires a file path/, "_slurp(undef) croaks";
}

# ---------------------------------------------------------------------------
# gpio_info(): command construction + empty handling (no real tool needed)
# ---------------------------------------------------------------------------

{
    local *RPi::SysInfo::_gpio_tool = sub { 'pinctrl' };
    my $seen;
    local *RPi::SysInfo::_run = sub { $seen = $_[0]; "pinctrl-output\n" };

    is gpio_info([2, 4, 6, 8]), 'pinctrl-output', "gpio_info returns (chomped) tool output";
    is $seen, 'pinctrl get 2,4,6,8', "gpio_info joins pins with commas";

    gpio_info();
    is $seen, 'pinctrl get ', "gpio_info with no pins requests all";

    gpio_info([]);
    is $seen, 'pinctrl get ', "gpio_info with empty aref requests all";

    gpio_info([7]);
    is $seen, 'pinctrl get 7', "gpio_info single pin";
}
{
    local *RPi::SysInfo::_gpio_tool = sub { undef };
    is gpio_info([2]), '', "gpio_info returns '' when no gpio tool present";
}

# ---------------------------------------------------------------------------
# network_info(): empty when no tool
# ---------------------------------------------------------------------------

{
    local *RPi::SysInfo::_net_tool = sub { undef };
    is network_info(), '', "network_info returns '' when no net tool present";
}

# ---------------------------------------------------------------------------
# pi_model(): devicetree preferred, revision fallback, Unknown
# ---------------------------------------------------------------------------

{
    local *RPi::SysInfo::_slurp = sub { "Raspberry Pi 5 Model B Rev 1.1\0" };
    is pi_model(), 'Raspberry Pi 5 Model B Rev 1.1', "pi_model strips NUL/whitespace from devicetree";
}
{
    # no devicetree -> fall back to revision decode
    local *RPi::SysInfo::_slurp = sub {
        my ($f) = @_;
        return undef if $f =~ m{devicetree};
        return "Revision\t: a02082\n" if $f =~ m{cpuinfo};
        return undef;
    };
    is pi_model(), 'Raspberry Pi 3 Model B', "pi_model falls back to revision decode";
}
{
    # nothing available
    local *RPi::SysInfo::_slurp = sub { undef };
    is pi_model(), 'Unknown', "pi_model returns Unknown when nothing identifies the board";
}

done_testing();
