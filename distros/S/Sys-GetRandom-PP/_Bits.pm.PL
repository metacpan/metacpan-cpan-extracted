use strict;
use warnings;

my $version = '0.01';

my $target = $ARGV[0] or die "Usage: $0 OUTFILE\n";

{
    package #
        Sys_Macro;
    require 'syscall.ph';
    require 'sys/random.ph';
}

my %vars = (
    gen           => "$0 v$version",
    GRND_RANDOM   => scalar Sys_Macro::GRND_RANDOM(),
    GRND_NONBLOCK => scalar Sys_Macro::GRND_NONBLOCK(),
    SYS_getrandom => scalar Sys_Macro::SYS_getrandom(),
);

my $out_tmp = "$target._tmp";
open my $out_fh, '>', $out_tmp or die "$0: $out_tmp: $!\n";

while (my $line = readline DATA) {
    $line =~ s{%\[\[(\w+)\]\]}{
        defined $vars{$1}
            ? $vars{$1}
            : die "Unknown template variable: '$1'"
    }eg;
    print $out_fh $line
        or die "Can't write to $out_tmp: $!";
}

close $out_fh
    or die "Can't write to $out_tmp: $!";

rename $out_tmp, $target
    or die "Can't rename $out_tmp to $target: $!";

__DATA__
# This file was generated automatically by %[[gen]].
#
package Sys::GetRandom::PP::_Bits;
use strict;
use warnings;

our $VERSION = '0.01';

use constant {
    GRND_RANDOM    => %[[GRND_RANDOM]],
    GRND_NONBLOCK  => %[[GRND_NONBLOCK]],
    _SYS_getrandom => %[[SYS_getrandom]],
};

1
