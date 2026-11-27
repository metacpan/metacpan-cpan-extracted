#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# NVIDIA install_driver on a Proxmox VE host (karr k88).
#
# A Proxmox host here is the Debian 13 profile with the kernel string
# 7.0.14-20-pve (read on a live PVE 9.2 by k81) and pve-firmware installed
# (t/17's pve_status shape). The Hub decided: NO Proxmox refusal for the
# NVIDIA Debian path; the behavior stays as it is and only the boundary is
# pinned. These tests record EXISTING behavior (green against the code before
# k88 too).
#
# CLAIMS:
#   * Ada (Debian non-free path) and Blackwell (NVIDIA CUDA repo path) on that
#     host live and do not refuse the host: the transcripts equal
#     t/golden/driver/debian-13--{ada,blackwell}.txt in every line but the
#     kernel string, so the one driver `apt-get install` names
#     linux-headers-7.0.14-20-pve (goldens driver/debian-13--ada--proxmox and
#     driver/debian-13--blackwell--proxmox);
#   * the install adds no firmware-* package, no pve-* package and never asks
#     for pve-firmware; the kernel package is named from `uname -r`.
#
# NOT covered -- scripted host, hand-written output, a green run proves nothing
# on Proxmox:
#   * that apt resolves linux-headers-7.0.14-20-pve: no such package exists,
#     proxmox-headers-7.0.14-20-pve `Provides` it and apt picks it itself --
#     a live apt-get -s finding of the Hub, not checked here;
#   * that nvidia-kernel-open-dkms / nvidia-driver DKMS-build against the -pve
#     kernel and the module binds (open);
#   * that firmware-nvidia-gsp does not collide with pve-firmware (live
#     finding, 0 Remv), or what the remote shell does with any command string;
#   * the Proxmox answers (kernel, pve-firmware status) are hand-written, not
#     captured; the Debian 13 profile underneath imitates a trixie install.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile gpu_fixture );
use Rex::GPU::NVIDIA;

my $PVE_KERNEL = '7.0.14-20-pve';

sub proxmox {
  return host_profile('debian-13', responses => [
    [ 'uname -r' => $PVE_KERNEL, 0 ],
    [ qr{^dpkg-query -W -f='\$\{Status\}\\n' pve-firmware 2>/dev/null$} => 'install ok installed', 0 ],
  ]);
}

sub driver_on {
  my ( $host, $gpu ) = @_;
  return record_host(host => $host, code => sub { Rex::GPU::NVIDIA::install_driver(gpu => $gpu) });
}

for my $g (qw( ada blackwell )) {
  subtest "$g on Proxmox VE: not refused, names the -pve headers (golden)" => sub {
    my $rec   = driver_on(proxmox(), gpu_fixture($g));
    my $plain = driver_on(host_profile('debian-13'), gpu_fixture($g));
    is($rec->{error}, undef, 'lives (no Proxmox refusal)');
    ok(!$rec->{trapped}, '... no unmocked Rex function reached');
    my @install = grep { /apt-get .* install -y linux-headers-/ } @{ $rec->{lines} };
    is(scalar @install, 1, '... one driver apt-get install');
    like($install[0], qr/ install -y linux-headers-\Q$PVE_KERNEL\E /, '... with linux-headers-<uname -r> as the kernel package');
    ok(!( grep { /firmware-|pve-/ } @{ $rec->{lines} } ), '... no firmware-* / pve-* package, pve-firmware not asked');
    # Rex::Pkg is for inert helpers only: the CUDA-repo path ensures curl, nothing else
    is_deeply([ grep { /^pkg:/ } @{ $rec->{lines} } ], $g eq 'blackwell' ? [ 'pkg: curl ensure=present' ] : [],
      '... no driver package through Rex::Pkg (only the curl helper on the CUDA-repo path)');
    # the only difference to the plain Debian 13 transcript is the kernel string
    my @swapped = map { s/6\.12\.48\+deb13-amd64/$PVE_KERNEL/gr } @{ $plain->{lines} };
    is_deeply($rec->{lines}, \@swapped, '... otherwise the Debian 13 transcript');
    golden_is($rec, "driver/debian-13--$g--proxmox");
  };
}

done_testing;
