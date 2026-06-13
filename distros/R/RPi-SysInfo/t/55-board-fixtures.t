use warnings;
use strict;

use Test::More;
use FindBin;

use RPi::SysInfo qw(:all);

# Replays real (and realistic) per-board command/file outputs captured under
# t/data/<board>/ through the actual public functions, with the _run/_slurp
# seams (and the tool selectors) overridden to feed those fixtures. This proves
# the full pipeline composes correctly on Pi 3, Pi 4 and Pi 5 inputs without any
# of those boards being present. Needs no Pi hardware, so it runs everywhere.
#
# Replace the hand-authored pi3/pi4 fixtures with ground truth via
# t/capture-fixtures.sh on a real board.

no warnings 'redefine';

my $DATA = "$FindBin::Bin/data";

my %BOARDS = (
    pi3 => {
        # Bullseye era: raspi-gpio, net-tools present, legacy camera firmware
        gpio_tool   => 'raspi-gpio',
        net_tool    => 'ifconfig',
        camera_tool => undef,
        model       => 'Raspberry Pi 3 Model B Rev 1.2',
        soc         => 'BCM2837',
        mem         => '1GB',
        rp1         => 0,
        camera_re   => qr/supported=0 detected=0/,
        gpio_re     => qr/GPIO 2:/,            # raspi-gpio output format
    },
    pi4 => {
        # Bookworm Lite: pinctrl, no net-tools (ip addr), libcamera with a camera
        gpio_tool   => 'pinctrl',
        net_tool    => 'ip addr',
        camera_tool => 'rpicam-hello',
        model       => 'Raspberry Pi 4 Model B Rev 1.4',
        soc         => 'BCM2711',
        mem         => '4GB',
        rp1         => 0,
        camera_re   => qr/detected \(libcamera\)/,
        gpio_re     => qr/GPIO2 = /,           # pinctrl output format
    },
    pi5 => {
        # Trixie: pinctrl, net-tools present, libcamera, RP1
        gpio_tool   => 'pinctrl',
        net_tool    => 'ifconfig',
        camera_tool => 'rpicam-hello',
        model       => 'Raspberry Pi 5 Model B Rev 1.1',
        soc         => 'BCM2712',
        mem         => '8GB',
        rp1         => 1,
        camera_re   => qr/none detected \(libcamera\)/,
        gpio_re     => qr/GPIO2 = /,
    },
);

for my $board (sort keys %BOARDS){
    my $cfg = $BOARDS{$board};
    my $dir = "$DATA/$board";

    my $fixture = sub {
        my ($name) = @_;
        open my $fh, '<', "$dir/$name" or die "missing fixture $board/$name: $!";
        local $/;
        my $data = <$fh>;
        close $fh;
        return $data;
    };

    # --- command seam --------------------------------------------------------

    local *RPi::SysInfo::_run = sub {
        my ($cmd) = @_;

        return $fixture->('measure_temp')               if $cmd eq 'vcgencmd measure_temp';
        return $fixture->('throttled')                  if $cmd eq 'vcgencmd get_throttled';
        return $fixture->('get_camera')                 if $cmd eq 'vcgencmd get_camera';
        return $fixture->('list-cameras')               if $cmd =~ /--list-cameras/;
        return $fixture->('config-int')                 if $cmd eq 'vcgencmd get_config int';
        return $fixture->('config-str')                 if $cmd eq 'vcgencmd get_config str';
        return $fixture->('config-txt')                 if $cmd =~ /config\.txt/;
        return $fixture->('model')                      if $cmd =~ m{cat /sys/firmware/devicetree/base/model};
        return $fixture->('os-release')                 if $cmd =~ m{os-release};
        return $fixture->('uname')                      if $cmd eq 'uname -a';
        return $fixture->('cpuinfo-tail')               if $cmd =~ m{cpuinfo \| tail};
        return $fixture->('df-out')                     if $cmd eq 'df';
        return $fixture->($cfg->{net_tool} eq 'ifconfig' ? 'ifconfig' : 'ip-addr')
            if $cmd eq $cfg->{net_tool};

        if ($cmd =~ /^(pinctrl|raspi-gpio) get (.*)$/){
            my ($base, $pins) = ($1, $2);
            my $kind = $pins eq '2,4,6,8' ? 'multi' : $pins eq '2' ? 'pin2' : 'all';
            return $fixture->("$base-$kind");
        }

        die "unmapped _run command for $board: [$cmd]";
    };

    # --- file seam -----------------------------------------------------------

    local *RPi::SysInfo::_slurp = sub {
        my ($file) = @_;
        return $fixture->('cpuinfo') if $file =~ m{/proc/cpuinfo};
        return $fixture->('model')   if $file =~ m{devicetree/base/model};
        return $fixture->('swaps')   if $file =~ m{/proc/swaps};
        return $fixture->('thermal') if $file =~ m{thermal_zone0/temp};
        die "unmapped _slurp file for $board: [$file]";
    };

    # --- pin the tool selections for this board ------------------------------

    local *RPi::SysInfo::_gpio_tool   = sub { $cfg->{gpio_tool} };
    local *RPi::SysInfo::_net_tool    = sub { $cfg->{net_tool} };
    local *RPi::SysInfo::_camera_tool = sub { $cfg->{camera_tool} };
    local *RPi::SysInfo::_config_file = sub { '/boot/firmware/config.txt' };

    # --- pi_model / board decode ---------------------------------------------

    is pi_model(), $cfg->{model}, "[$board] pi_model() = $cfg->{model}";

    my $summary = RPi::SysInfo::_board_summary();
    like $summary, qr/\Q$cfg->{soc}\E/, "[$board] board summary names the SoC ($cfg->{soc})";
    like $summary, qr/\Q$cfg->{mem}\E/, "[$board] board summary names the RAM ($cfg->{mem})";

    if ($cfg->{rp1}){
        like   $summary, qr/RP1/, "[$board] board summary flags RP1";
    }
    else {
        unlike $summary, qr/RP1/, "[$board] board summary does not flag RP1";
    }

    # --- pi_details ----------------------------------------------------------

    my $details = pi_details();
    like $details, qr/\QRaspberry Pi\E/,          "[$board] pi_details has the model name";
    like $details, qr/Throttled flag\s*:/,        "[$board] pi_details has the throttled flag";
    like $details, qr/Board\s*:\s*\Q$cfg->{model}\E/, "[$board] pi_details Board line = pi_model";
    like $details, qr/\Q$cfg->{soc}\E/,           "[$board] pi_details includes decoded SoC";
    like $details, $cfg->{camera_re},             "[$board] pi_details camera status ($cfg->{camera_re})";

    # --- raspi_config --------------------------------------------------------

    my $config = raspi_config();
    like   $config, qr/arm_freq/,            "[$board] raspi_config has vcgencmd config";
    like   $config, qr/^dt(?:param|overlay)=/m, "[$board] raspi_config appends config.txt directives";
    unlike $config, qr/^\s*#/m,              "[$board] raspi_config strips comment lines";

    # --- network_info --------------------------------------------------------

    like network_info(), qr/inet\b/, "[$board] network_info has inet data (via $cfg->{net_tool})";

    # --- file_system ---------------------------------------------------------

    my $fs = file_system();
    like $fs, qr/Filesystem .* Mounted on/, "[$board] file_system has df header";
    like $fs, qr{^\S+ \s+ \d+ \s+ \d+ \s+ \d+ \s+ \d+% \s+ /\s*$}xm, "[$board] file_system has root mount";
    like $fs, qr/Filename\s+Type\s+Size/,    "[$board] file_system has swaps header";

    # --- core_temp -----------------------------------------------------------

    like core_temp(),    qr/^\d+\.\d+$/, "[$board] core_temp Celsius";
    like core_temp('f'), qr/^\d+\.\d+$/, "[$board] core_temp Fahrenheit";
    cmp_ok core_temp('f'), '>', core_temp(), "[$board] Fahrenheit > Celsius";

    # --- gpio_info (format differs by tool) ----------------------------------

    my $multi = gpio_info([2, 4, 6, 8]);
    like $multi, $cfg->{gpio_re}, "[$board] gpio_info multi matches $cfg->{gpio_tool} format";
    is scalar(split /\n/, $multi), 4, "[$board] gpio_info multi returns four lines";

    my @single = split /\n/, gpio_info([2]);
    is scalar(@single), 1, "[$board] gpio_info single pin returns one line";
}

done_testing();
