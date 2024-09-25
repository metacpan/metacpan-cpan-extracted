use strict;
use warnings;
use File::Temp qw(tempdir);
use Config qw(%Config);

my $version = '0.06';

my $target = $ARGV[0] or die "Usage: $0 OUTFILE\n";

my $phdir = tempdir(CLEANUP => 1);

{
    my $h2ph = 'h2ph';
    for my $key (qw(installscript scriptdirexp)) {
        my $candidate = "$Config{$key}/h2ph";
        if (-x $candidate) {
            $h2ph = $candidate;
            last;
        }
    }
    my $cmd = "cd /usr/include && \Q$h2ph\E -eal -d \Q$phdir\E sys/syscall.h sys/random.h";
    print $cmd, "\n";
    system $cmd;
}
unshift @INC, $phdir;

{
    package #
        Sys_Macro;
    {
        # Hack. Shouldn't be necessary, but apparently _h2ph_pre.ph is missing
        # some important bits on FreeBSD.
        require '_h2ph_pre.ph';
        my $default_to = sub {
            my ($symref, $value) = @_;
            unless (defined *$symref{CODE}) {
                *$symref = sub () { $value };
            }
        };
        $default_to->(\*__SIZEOF_LONG__, $::Config{longsize});
        $default_to->(\*__ORDER_BIG_ENDIAN__, 4321);
        $default_to->(\*__ORDER_LITTLE_ENDIAN__, 1234);
        $default_to->(\*__BYTE_ORDER__, $::Config{byteorder} =~ /^1/ ? __ORDER_LITTLE_ENDIAN__() : __ORDER_BIG_ENDIAN__());
        $default_to->(\*__SIZEOF_POINTER__, $::Config{ptrsize});
        # These two are technically wrong, but I don't know how to get the correct sizes from Perl.
        $default_to->(\*__SIZEOF_SIZE_T__, $::Config{ptrsize});
        $default_to->(\*__SIZEOF_PTRDIFF_T__, $::Config{ptrsize});
    }
    require 'sys/syscall.ph';
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

our $VERSION = '0.05';

use constant {
    GRND_RANDOM    => %[[GRND_RANDOM]],
    GRND_NONBLOCK  => %[[GRND_NONBLOCK]],
    _SYS_getrandom => %[[SYS_getrandom]],
};

1
