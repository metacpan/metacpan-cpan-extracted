use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# CHARACTERIZATION ("golden") tests for Rex::GPU::Detect::detect's pciutils
# bootstrap (karr #46).
#
# CLAIM: detect() hands Rex exactly the host interactions recorded in
# t/golden/detect/<case>.txt, in order:
#   * lspci on the PATH (`command -v lspci` exits 0) => nothing is installed,
#     on every OS -- only the probe and the lspci -nn read;
#   * lspci missing on an OS Rex::Pkg handles (Debian, Redhat, SuSE) =>
#     is_installed + pkg pciutils, the same two calls detect() always made;
#   * lspci missing on Rocky/AlmaLinux under their lsb_release names (Rex::Pkg
#     dies "OS/Provider not supported" there) => dnf install -y pciutils,
#     verified with rpm -q, no pkg/is_installed;
#   * the rpm -q check failing, or lspci still missing after the install =>
#     die, before lspci -nn runs.
#
# NOT covered -- a green prove is NOT evidence that this works on a host:
#   * what the remote shell's PATH is (command -v lspci is recorded, never
#     run; lspci is /usr/sbin/lspci on EL, /usr/bin/lspci on Debian);
#   * whether dnf can reach a repo on a fresh host, or what Rex::Pkg's
#     is_installed/pkg run underneath (the harness records the calls only);
#   * the canned outputs are hand-written stand-ins, not host captures.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile );
use Rex::GPU::Detect;

my $LSPCI_READ = q{lspci -nn 2>&1 | grep -E '\[03(00|02)\]'};
my $ADA_LINE   = '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation '
  .'AD104GL [RTX 4000 SFF Ada Generation] [10de:27b0] (rev a1)';

# lspci answers: 'present', 'missing' (never appears), or 'installed' (missing
# until the first probe after an install attempt, i.e. the second probe).
sub lspci_probe {
  my ( $state ) = @_;
  my $calls = 0;
  return [ 'command -v lspci >/dev/null 2>&1' => sub {
    $calls++;
    my $found = $state eq 'present' ? 1
      : $state eq 'installed' ? ( $calls > 1 ? 1 : 0 )
      : 0;
    return ( '', $found ? 0 : 1 );
  } ];
}

sub detect_on {
  my ( $os, $lspci, %override ) = @_;
  my $extra = delete $override{responses} // [];
  my $result;
  my $rec = record_host(
    host => host_profile($os,
      %override,
      responses => [
        lspci_probe($lspci),
        [ $LSPCI_READ => $ADA_LINE, 0 ],
        @$extra
      ]),
    code => sub { $result = Rex::GPU::Detect::detect() }
  );
  # croak names the caller's line (this file) -- keep it out of the goldens
  $rec->{error} =~ s/ at \S+ line \d+\.?$// if defined $rec->{error};
  return ( $rec, $result );
}

#### lspci present: install nothing, on every family

for my $os (qw( debian-12 rocky-9 rocky-9-lsb leap-15.6 )) {
  my ( $rec, $result ) = detect_on($os, 'present');
  golden_is($rec, "detect/$os--lspci-present");
  is(scalar @{ $result->{nvidia} }, 1, "$os: the card is still detected");
  ok(!grep({ /^(?:pkg|is_installed):|install -y/ } @{ $rec->{lines} }),
    "$os: nothing installed when lspci is there");
}

#### lspci missing: pkg where Rex::Pkg works, dnf + rpm -q where it cannot

for my $os (qw( debian-12 ubuntu-24.04 rocky-9 leap-15.6 rocky-9-lsb alma-9-lsb )) {
  my ( $rec, $result ) = detect_on($os, 'installed');
  golden_is($rec, "detect/$os--lspci-missing");
  is(scalar @{ $result->{nvidia} }, 1, "$os: detected after the install");
}

#### failures die before lspci -nn runs

{
  my ( $rec ) = detect_on('rocky-9-lsb', 'missing',
    responses => [ [ 'rpm -q pciutils 2>&1' => 'package pciutils is not installed', 1 ] ]);
  golden_is($rec, 'detect/rocky-9-lsb--dnf-failed');
  like($rec->{error}, qr/pciutils not installed after dnf install/, 'rpm -q miss dies');
}

{
  my ( $rec ) = detect_on('debian-12', 'missing', installed => { pciutils => 1 });
  golden_is($rec, 'detect/debian-12--pciutils-without-lspci');
  like($rec->{error}, qr/lspci not found on the host after installing pciutils/,
    'pciutils installed but no lspci on the PATH dies instead of "no GPU"');
}

{
  my ( $rec ) = detect_on('rocky-9-lsb', 'missing');
  like($rec->{error}, qr/lspci not found on the host/,
    'dnf + rpm -q fine but still no lspci dies');
  ok(!grep({ /\Q$LSPCI_READ\E$/ } @{ $rec->{lines} }),
    'lspci -nn never runs after a failed bootstrap');
}

done_testing;
