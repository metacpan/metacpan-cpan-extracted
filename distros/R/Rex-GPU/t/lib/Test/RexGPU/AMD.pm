package Test::RexGPU::AMD;

use strict;
use warnings;

# -----------------------------------------------------------------------------
# Scripted AMD hosts for Rex::GPU::AMD (karr k1), on top of Test::RexGPU::Golden.
#
# amd_state() renders the output of Rex::GPU::AMD->state_script the way a host
# would print it; amd_host() is a Golden host_profile plus the answers the AMD
# setup classes ask for: /etc/os-release, the kernel, modinfo, /proc/cmdline,
# the modprobe.d grep, the gpg listing of the signing key, dkms status, the
# Secure Boot variable.
#
# EVERYTHING HERE IS A HAND-WRITTEN STAND-IN, not a capture:
#   * synapse (the Ryzen AI Max+ PRO 495 test host of k1): the state lines
#     imitate what the maintainer read there on 2026-10-31 (Ubuntu 24.04.5,
#     HWE kernel 7.0.0-42-generic, 1002:1586, KFD node 1 gfx_target_version
#     110501, location_id 0x9500, 128 GiB VRAM). The string guessed at: the
#     exact `dkms status` and `gpg --with-colons` lines, /proc/cmdline, and
#     every kernel release other than 7.0.0-42 (6.8.0-85-generic,
#     5.15.0-151-generic, 7.0.0-12-generic, 6.1.0-37-amd64, 6.12.48+deb13-amd64,
#     5.14.0-570.12.1.el9_6.x86_64, 6.12.0-55.12.1.el10_0.x86_64 are the kernel
#     strings of the existing NVIDIA profiles or invented in their shape).
#   * the MI300X state (1002:74a1, class 1200, KFD 90402) imitates an Instinct
#     node; no such host was read.
#   * a sequence() answer imitates a host that CHANGES while the install runs
#     (dkms not built before the install, built after; amdgpu not loaded
#     before `modprobe amdgpu`, loaded after). Which call sees which answer is
#     the order the code issues them in -- the golden records that order.
# -----------------------------------------------------------------------------

use Carp qw( croak );
use Exporter qw( import );
use Test::RexGPU::Golden qw( host_profile dpkg_l );

our @EXPORT_OK = qw(
  amd_host
  amd_state
  module_path
  os_kernel
  sequence
  dpkg_l
  gpu_synapse
  gpu_mi300x
  gpu_navi31
  gpu_unknown
  ubuntu_amd_host
);

# Hand-written AMD GPU hashes, as Rex::GPU::Detect hands them over (what
# install_driver(gpus => ...) takes). slot/device_id are what matter.
sub gpu_synapse {
  return { name => 'AMD GPU [1002:1586]', vendor => 'amd', pci_class => '0380',
           slot => '0000:95:00.0', device_id => '1586', gfx_target => 'gfx1151',
           compute => 1, integrated => 1 };
}
sub gpu_mi300x {
  return { name => 'Aqua Vanjaram [Instinct MI300X]', vendor => 'amd', pci_class => '1200',
           slot => '0000:c1:00.0', device_id => '74a1', gfx_target => 'gfx942',
           compute => 1, integrated => 0 };
}
sub gpu_navi31 {
  return { name => 'Navi 31 [Radeon RX 7900 XTX]', vendor => 'amd', pci_class => '0300',
           slot => '0000:0a:00.0', device_id => '744c', gfx_target => 'gfx1100',
           compute => 1, integrated => 0 };
}
# a device without a hardware row (the Raphael iGPU 1002:164e is "known"
# only as gfx1036 via KFD; 1902 is invented and has none)
sub gpu_unknown {
  return { name => 'AMD GPU [1002:1902]', vendor => 'amd', pci_class => '0300',
           slot => '0000:03:00.0', device_id => '1902', gfx_target => undef,
           compute => undef, integrated => undef };
}

# amd_state(
#   amdgpu => 1, kfd => 1,                      # default 1, 1
#   gpus   => [ { slot => '0000:95:00.0', class => '0380', device_id => '1586',
#                 driver => 'amdgpu'|undef,     # the bound driver; default amdgpu
#                 vram => 137438953472, gtt => 33535848448,
#                 render => 128,                # renderD128 of vendor 0x1002; default 128+i
#                 kfd => 110501 } ],            # gfx_target_version of its KFD node; undef: no node
#   nodes  => [ { id => 0, gfx => 0 } ],        # extra topology nodes (a CPU node: 0)
#   end    => 1,                                # 0: the read did not finish
# ) => the text of Rex::GPU::AMD->state_script's output
sub amd_state {
  my ( %arg ) = @_;
  my @out;
  push @out, 'amdgpu '.( $arg{amdgpu} // 1 ), 'kfd '.( $arg{kfd} // 1 );
  my @gpus = @{ $arg{gpus} // [] };
  my $n = 0;
  for my $g (@gpus) {
    my $driver = exists $g->{driver} ? $g->{driver} : 'amdgpu';
    push @out, sprintf 'pci %s 0x%s00 0x%s %s', $g->{slot}, $g->{class}, $g->{device_id}, $driver // '-';
    push @out, 'vram '.$g->{slot}.' '.$g->{vram} if defined $g->{vram};
    push @out, 'gtt '.$g->{slot}.' '.$g->{gtt} if defined $g->{gtt};
  }
  for my $g (@gpus) {
    next if exists $g->{render} && !defined $g->{render};
    push @out, 'render renderD'.( $g->{render} // 128 + $n ).' 0x1002 '.$g->{slot};
    $n++;
  }
  my @nodes = @{ $arg{nodes} // [] };
  my $id = 1;
  for my $g (@gpus) {
    next unless defined $g->{kfd};
    my ( $dom, $bus, $dev, $fn ) = $g->{slot} =~ /\A([0-9a-f]+):([0-9a-f]{2}):([0-9a-f]{2})\.([0-7])\z/
      or croak 'amd_state: bad slot '.$g->{slot};
    push @nodes, { id => $g->{node} // $id++, gfx => $g->{kfd}, vendor_id => 4098,
                   device_id => hex $g->{device_id},
                   location_id => ( hex($bus) << 8 ) | ( hex($dev) << 3 ) | $fn,
                   domain => hex $dom, render => $g->{render} // 128 };
  }
  for my $node (sort { $a->{id} <=> $b->{id} } @nodes) {
    push @out, 'node '.$node->{id}, 'prop gfx_target_version '.$node->{gfx};
    push @out, map { 'prop '.$_.' '.$node->{$_} }
      grep { defined $node->{$_} } qw( vendor_id device_id location_id domain );
    push @out, 'prop drm_render_minor '.$node->{render} if defined $node->{render};
  }
  push @out, 'end' unless defined $arg{end} && !$arg{end};
  return join "\n", @out;
}

sub module_path {
  my ( $kernel, $kind ) = @_;
  return '/lib/modules/'.$kernel.'/kernel/drivers/gpu/drm/amd/amdgpu/amdgpu.ko.zst' if $kind eq 'inbox';
  return '/lib/modules/'.$kernel.'/updates/dkms/amdgpu.ko.zst' if $kind eq 'dkms';
  croak 'module_path: unknown kind '.$kind;
}

# sequence([out, exit], [out, exit], ...) => a Golden response output: each
# call answers the next item, the last one repeating.
sub sequence {
  my ( @items ) = @_;
  my $i = 0;
  return sub {
    my $item = $items[ $i < $#items ? $i++ : $#items ];
    return @$item;
  };
}

# dpkg_l lives in Test::RexGPU::Golden since k94 (the NVIDIA apt layer counts
# a held package too); it is re-exported from here for the AMD tests.

my %OS = (
  'ubuntu-24.04' => {
    base => 'ubuntu-24.04', kernel => '6.8.0-85-generic',
    os_release => join("\n", 'PRETTY_NAME="Ubuntu 24.04.5 LTS"', 'NAME="Ubuntu"', 'VERSION_ID="24.04"',
      'VERSION="24.04.5 LTS (Noble Numbat)"', 'ID=ubuntu', 'ID_LIKE=debian'),
  },
  'ubuntu-22.04' => {
    base => 'ubuntu-24.04', kernel => '5.15.0-151-generic',
    os_release => join("\n", 'PRETTY_NAME="Ubuntu 22.04.5 LTS"', 'NAME="Ubuntu"', 'VERSION_ID="22.04"',
      'VERSION="22.04.5 LTS (Jammy Jellyfish)"', 'ID=ubuntu', 'ID_LIKE=debian'),
  },
  'ubuntu-26.04' => {
    base => 'ubuntu-24.04', kernel => '7.0.0-12-generic',
    os_release => join("\n", 'PRETTY_NAME="Ubuntu 26.04 LTS"', 'NAME="Ubuntu"', 'VERSION_ID="26.04"',
      'VERSION="26.04 LTS (Resolute Raccoon)"', 'ID=ubuntu', 'ID_LIKE=debian'),
  },
  'debian-12' => {
    base => 'ubuntu-24.04', kernel => '6.1.0-37-amd64',
    os_release => join("\n", 'PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"', 'NAME="Debian GNU/Linux"',
      'VERSION_ID="12"', 'VERSION="12 (bookworm)"', 'ID=debian'),
  },
  'debian-13' => {
    base => 'ubuntu-24.04', kernel => '6.12.48+deb13-amd64',
    os_release => join("\n", 'PRETTY_NAME="Debian GNU/Linux 13 (trixie)"', 'NAME="Debian GNU/Linux"',
      'VERSION_ID="13"', 'VERSION="13 (trixie)"', 'ID=debian'),
  },
  'rhel-9' => {
    base => 'rhel-9', kernel => '5.14.0-570.12.1.el9_6.x86_64',
    os_release => join("\n", 'NAME="Red Hat Enterprise Linux"', 'VERSION="9.6 (Plow)"', 'ID="rhel"',
      'ID_LIKE="fedora"', 'VERSION_ID="9.6"', 'PRETTY_NAME="Red Hat Enterprise Linux 9.6 (Plow)"'),
  },
  'rocky-10' => {
    base => 'rocky-10', kernel => '6.12.0-55.12.1.el10_0.x86_64',
    os_release => join("\n", 'NAME="Rocky Linux"', 'VERSION="10.0 (Red Quartz)"', 'ID="rocky"',
      'ID_LIKE="rhel centos fedora"', 'VERSION_ID="10.0"', 'PRETTY_NAME="Rocky Linux 10.0 (Red Quartz)"'),
  },
);

sub os_kernel { my ( $os ) = @_; return $OS{$os}{kernel} // croak 'os_kernel: unknown OS '.$os }

my $KEY_FPR = 'CA8BB4727A47B4D09B4EE8969386B48A1A693C5C';   # repo.radeon.com, as pinned in the code

# amd_host($os, %opt) => a Golden host profile.
#   kernel      uname -r (default per OS)
#   state       text of the state read, or an ARRAY of texts: each state read
#               answers the next, the last repeating
#   module      'inbox' | 'dkms' | 'none' | ARRAY of those (a sequence of
#               modinfo answers); default inbox
#   cmdline     /proc/cmdline
#   arch        dpkg --print-architecture / uname -m (default amd64 / x86_64)
#   secure_boot 0|1 (the SecureBoot variable's value byte; default 0)
#   key         the fingerprint gpg lists for a downloaded key (default: the
#               pinned repo.radeon.com one)
#   responses   [ ... ] consulted first
sub amd_host {
  my ( $os, %opt ) = @_;
  my $def = $OS{$os} or croak 'amd_host: unknown OS '.$os;
  my $kernel = $opt{kernel} // $def->{kernel};

  my $modules = $opt{module} // 'inbox';
  my @modules = ref $modules ? @$modules : ( $modules );
  my $modinfo = sequence(map { [ $_ eq 'none' ? '' : module_path($kernel, $_), $_ eq 'none' ? 1 : 0 ] } @modules);

  my $states = ref $opt{state} eq 'ARRAY' ? $opt{state} : [ $opt{state} // amd_state() ];
  my $state = sequence(map { [ $_, 0 ] } @$states);

  my @responses = (
    @{ $opt{responses} // [] },
    [ Rex::GPU::AMD->state_script => $state, 0 ],
    [ 'cat /etc/os-release 2>/dev/null' => $def->{os_release}, 0 ],
    [ 'uname -r' => $kernel, 0 ],
    [ 'modinfo -n amdgpu 2>/dev/null' => $modinfo, 0 ],
    [ 'cat /proc/cmdline 2>/dev/null' => $opt{cmdline} // 'BOOT_IMAGE=/vmlinuz-'.$kernel.' root=/dev/nvme0n1p2 ro quiet', 0 ],
    # grep finds no blacklist: exit 1, nothing printed
    [ qr{^grep -rsHE --include='\*\.conf' } => '', 1 ],
    [ qr{^od -An -tu1 -j4 -N1 /sys/firmware/efi/efivars/} => ( $opt{secure_boot} ? '   1' : '   0' ), 0 ],
    # `gpg --with-colons --show-keys` of the downloaded key: the fingerprint
    # record follows the pub record (field 10)
    [ qr{^GNUPGHOME=\S+ gpg --batch --with-colons --show-keys } =>
        "pub:-:4096:1:9386B48A1A693C5C:1503000000:1818000000::-:::scESC::::::23::0:\n"
      ."fpr:::::::::".( $opt{key} // $KEY_FPR ).":\n"
      ."uid:-::::1503000000::0000000000000000000000000000000000000000::ROCm Release Engineering::::::::::0:", 0 ],
    ( defined $opt{arch} ? (
      [ 'dpkg --print-architecture' => $opt{arch}, 0 ],
      [ 'uname -m' => $opt{arch} eq 'arm64' ? 'aarch64' : $opt{arch}, 0 ],
    ) : () ),
  );
  return host_profile($def->{base}, responses => \@responses);
}

# The Ubuntu 24.04 synapse host: kernel 7.0.0-42-generic, the inbox driver.
sub ubuntu_amd_host {
  my ( %opt ) = @_;
  return amd_host('ubuntu-24.04', kernel => '7.0.0-42-generic', %opt);
}

1;
