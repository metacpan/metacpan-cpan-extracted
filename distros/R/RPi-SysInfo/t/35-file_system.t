use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{RPI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

# file_system() returns `df` output followed by /proc/swaps. We assert on the
# stable, layout-independent structure rather than on specific device names
# (the root device is /dev/mmcblk0p2 on SD, /dev/sda2 on USB, /dev/nvme0n1p2
# on NVMe, etc., and swap may be a zram device or a swapfile).

my $sys = RPi::SysInfo->new;

for my $case (['method', $sys->file_system], ['function', file_system()]){
    my ($form, $fs) = @$case;

    ok length $fs, "file_system() $form returns data";

    like $fs, qr/Filesystem .* Mounted on/, "file_system() $form has the df header";

    like
        $fs,
        qr{^\S+ \s+ \d+ \s+ \d+ \s+ \d+ \s+ \d+% \s+ /\s*$}xm,
        "file_system() $form includes the root (/) mount";

    like $fs, qr/Filename\s+Type\s+Size/, "file_system() $form has the /proc/swaps header";
}

done_testing();
