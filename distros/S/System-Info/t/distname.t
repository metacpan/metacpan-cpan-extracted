#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use System::Info;

my @etc = sort glob "t/etc/*/DISTNAME";

local $^O = "linux";

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
