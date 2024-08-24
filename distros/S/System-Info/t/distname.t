#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use System::Info;

my @etc = sort glob "t/etc/*/DISTNAME";

local $^O = "linux";

# https://www.cpantesters.org/cpan/report/a7bd7046-76cd-11ee-a6ec-3d5ceee57fba
# t/distname.t ....... ok
# Unexpected warning from system_profiler:
# 2023-10-30 02:39:39.876 system_profiler[19850:11194276] Timed out waiting for the Activation Lock Capable check
# Unexpected warning from system_profiler:
# 2023-10-30 02:39:50.616 system_profiler[19995:11195115] Timed out waiting for the Activation Lock Capable check
# Unexpected warning from system_profiler:
# 2023-10-30 02:40:01.283 system_profiler[20181:11196324] Timed out waiting for the Activation Lock Capable check
# Unexpected warning from system_profiler:
# 2023-10-30 02:40:11.959 system_profiler[20316:11197150] Timed out waiting for the Activation Lock Capable check
# 
# #   Failed test 'no (unexpected) warnings (via END block)'
# #   at /Users/cpantesting/cpantesting/perl-blead/lib/5.39.5/Test/Builder.pm line 193.
# # Looks like you failed 1 test of 70.
#
# uname='darwin harrow.local 22.3.0 darwin kernel version 22.3.0: mon jan 30 20:42:11 pst 2023; root:xnu-8792.81.3~2release_x86_64 x86_64 '

foreach my $dnf (@etc) {
    open my $dnh, "<", $dnf or die "$dnf: $!\n";
    chomp (my $dn = <$dnh>);
    close $dnh;

    (my $etc = $dnf) =~ s{/DISTNAME$}{};
    $ENV{SMOKE_USE_ETC} = $etc;

    my $si = System::Info->new;
    is ($si->_distro, $dn, "Distribution\t$dn");

    # Helper line :)
    $si->{__distro} eq $dn and next;

    #use DP;diag (DDumper ($si->{__X__}));
    #print "echo '$si->{__distro}' >$etc/DISTNAME\n";
    }

done_testing ();
