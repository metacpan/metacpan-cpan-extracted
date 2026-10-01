# ABSTRACT: GPU detection from sysfs, without lspci or pciutils

package Rex::GPU::Detect::Sysfs;
our $VERSION = '0.003';
use v5.14.4;
use warnings;

use Carp qw( croak );
use Rex::Commands::Run;
use Rex::Logger;

use parent 'Rex::GPU::Detect';

# karr #73 (kubernetes-ocp k196): the same result as Rex::GPU::Detect::detect,
# read from /sys/bus/pci/devices instead of lspci -- nothing is installed to
# detect. One read-only command, shell builtins only (no fork per file; an
# HGX host has hundreds of PCI functions), over the exec channel: these hosts
# have no SFTP, so no Rex file command. Per device one line: the directory
# name, then class, vendor, device, subsystem_vendor, subsystem_device as the
# kernel prints them (0x030000, 0x10de, ...), "-" for a file it could not
# read. A missing or unreadable directory exits 3; an empty one prints
# nothing and exits 0. A dangling entry (device removed meanwhile) is skipped.
my $SYSFS_READ = q{cd /sys/bus/pci/devices && test -r . || exit 3; }
  .q{for d in *; do test -e "$d" || continue; l=$d; }
  .q{for f in class vendor device subsystem_vendor subsystem_device; do }
  .q{v=; read -r v 2>/dev/null <"$d/$f"; l="$l ${v:--}"; done; }
  .q{printf '%s\n' "$l"; done};


sub detect {
  my $class = Rex::GPU::Detect::_invocant(@_) // __PACKAGE__;
  my $devices = $class->_read_pci_devices;

  my $result = { nvidia => [], amd => [], nvswitch => [] };
  my %virtual = map { lc($_) => 1 } $class->virtual_display_vendor_ids;
  my $virtual = 0;
  for my $dev (@$devices) {
    next unless $dev->{class} eq '0300' || $dev->{class} eq '0302';
    if ($dev->{vendor} eq '10de') {
      push @{$result->{nvidia}}, $class->_nvidia_gpu_from_sysfs($dev);
    }
    elsif ($dev->{vendor} eq '1002') {
      push @{$result->{amd}}, $class->_amd_gpu_from_sysfs($dev);
    }
    elsif ($virtual{ $dev->{vendor} }) {
      $virtual++;
      Rex::Logger::info('  [skip] virtual display: '.$dev->{vendor}.':'
        .( $dev->{device} // '????' ).' at '.$dev->{slot});
    }
  }

  Rex::Logger::info('Virtual GPU detected (virtio/QEMU/VMware/VBox) -- skipping')
    if $virtual && !@{$result->{nvidia}} && !@{$result->{amd}};

  # As with lspci: NVSwitches only where there is an NVIDIA GPU.
  $result->{nvswitch} = $class->_nvswitches_from_sysfs($devices) if @{$result->{nvidia}};

  return $result;
}

sub _read_pci_devices {
  my ( $class ) = @_;
  my $out = run $SYSFS_READ, auto_die => 0;
  croak 'GPU detection from sysfs: could not read /sys/bus/pci/devices on the host (exit '
    .( $? >> 8 ).') -- no GPU list is reported for a host that could not be looked at. '
    .'Nothing was changed on the host'
    if $? != 0;
  my $devices = $class->_parse_sysfs_pci($out);
  Rex::Logger::info('  [info] no PCI device listed under /sys/bus/pci/devices') unless @$devices;
  return $devices;
}

# The lines of $SYSFS_READ => [ { slot, class, vendor, device,
# subsystem_vendor, subsystem_device } ] sorted by slot; class the four hex
# digits of base class and subclass ("0300"), the IDs four lowercase hex
# digits or undef. Dies for a line it cannot use and for an unreadable class
# or vendor: that device could be the GPU.
sub _parse_sysfs_pci {
  my ( $class, $out ) = @_;
  my @devices;
  for my $line (split /\n/, $out // '') {
    next unless $line =~ /\S/;
    my @field = split ' ', $line;
    croak 'GPU detection from sysfs: unexpected line from /sys/bus/pci/devices: \''.$line
      .'\' -- no GPU list is reported. Nothing was changed on the host'
      unless @field == 6;
    my ( $slot, $pci_class, $vendor, $device, $sub_vendor, $sub_device ) = @field;
    my ( $class_code ) = $pci_class =~ /\A0x([0-9a-f]{4})[0-9a-f]{2}\z/i;
    my $vendor_id = $class->_sysfs_id($vendor);
    croak 'GPU detection from sysfs: PCI device '.$slot.' has an unreadable class or vendor '
      .'(class '.$pci_class.', vendor '.$vendor.'), so whether it is a GPU is unknown -- '
      .'no GPU list is reported; run again if the device was being removed. Nothing '
      .'was changed on the host'
      unless defined $class_code && defined $vendor_id;
    push @devices, {
      slot             => $slot,
      class            => lc $class_code,
      vendor           => $vendor_id,
      device           => $class->_sysfs_id($device),
      subsystem_vendor => $class->_sysfs_id($sub_vendor),
      subsystem_device => $class->_sysfs_id($sub_device)
    };
  }
  return [ sort { $a->{slot} cmp $b->{slot} } @devices ];
}

# "0x10de" => "10de"; "-" (unreadable) or anything malformed => undef. Always
# one value, also in the list of a hash constructor.
sub _sysfs_id {
  my ( $class, $value ) = @_;
  return defined $value && $value =~ /\A0x([0-9a-f]{4})\z/i ? lc $1 : undef;
}

sub _nvidia_gpu_from_sysfs {
  my ( $class, $dev ) = @_;
  my $device_id = $dev->{device};
  my $name = 'NVIDIA GPU [10de:'.( $device_id // '????' ).']';
  my $compute = $class->_is_nvidia_compute($dev->{class}, $name, $device_id);
  my $status = !defined $compute ? 'undecided' : $compute ? 'ok' : 'skip';
  Rex::Logger::info('  ['.$status.'] NVIDIA: '.$name.' (PCI class '.$dev->{class}.', '
    .$dev->{slot}.')');
  my $gpu = {
    name                => $name,
    vendor              => 'nvidia',
    pci_class           => $dev->{class},
    compute             => $compute,
    device_id           => $device_id,
    subsystem_vendor_id => $dev->{subsystem_vendor},
    subsystem_id        => $dev->{subsystem_device}
  };
  $class->_mark_vgpu($gpu);
  return $gpu;
}

# The lspci path's name rules need a name; sysfs has none. Where the
# generation row and the PCI class left compute open, it stays open: undef,
# never a guess (the safe default: gpu_setup installs nothing for it).
sub _nvidia_compute_by_name {
  my ( $class, $pci_class, $name, $device_id ) = @_;
  Rex::Logger::info('    '.$name.': no generation row for its device ID and no name in '
    .'sysfs to judge it by -- compute left undecided (undef)', 'warn');
  return;
}

sub _amd_gpu_from_sysfs {
  my ( $class, $dev ) = @_;
  my $name = 'AMD GPU [1002:'.( $dev->{device} // '????' ).']';
  Rex::Logger::info('  [info] AMD: '.$name.' (PCI class '.$dev->{class}.', '.$dev->{slot}.')');
  return {
    name      => $name,
    vendor    => 'amd',
    pci_class => $dev->{class},
    compute   => 0   # AMD compute support not yet implemented
  };
}

sub _nvswitches_from_sysfs {
  my ( $class, $devices ) = @_;
  my %known = map { lc($_) => 1 } $class->nvswitch_device_ids;
  my @switches;
  for my $dev (@$devices) {
    next unless $dev->{vendor} eq '10de' && $dev->{class} eq '0680';
    my $id = $dev->{device};
    unless (defined $id && $known{$id}) {
      Rex::Logger::info('  [skip] NVIDIA bridge device not known as an NVSwitch: 10de:'
        .( $id // '????' ).' at '.$dev->{slot}.' (sysfs has no name; only a known '
        .'NVSwitch device ID counts)');
      next;
    }
    push @switches, {
      name      => 'NVIDIA NVSwitch [10de:'.$id.']',
      vendor    => 'nvidia',
      pci_class => '0680',
      device_id => $id
    };
  }
  Rex::Logger::info('  [ok] NVSwitch: '.scalar(@switches).' ('.$switches[0]{name}.')')
    if @switches;
  return \@switches;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::Detect::Sysfs - GPU detection from sysfs, without lspci or pciutils

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Rex -feature => ['1.4'];
  use Rex::GPU;
  use Rex::GPU::NVIDIA;

  # Rexfile-wide: gpu_detect, gpu_setup, detect() and Rex::Rancher's gpu => 1
  set gpu_detect_class => 'Rex::GPU::Detect::Sysfs';

  task 'setup', sub {
    gpu_setup(containerd_config => 'rke2');   # detects from sysfs
  };

  task 'driver', sub {
    my $gpus = gpu_detect();   # or gpu_detect(detect => 'Rex::GPU::Detect::Sysfs')
    # Your call, not gpu_setup's: drop what is known not to be compute
    # (Kepler and older), keep the undecided ones (compute undef)
    my @gpus = grep { !defined $_->{compute} || $_->{compute} } @{ $gpus->{nvidia} };
    return unless @gpus;   # gpus => [] still installs a driver (GPU-agnostic)
    install_driver(gpus => \@gpus,
      ( @{ $gpus->{nvswitch} } ? ( nvswitches => $gpus->{nvswitch} ) : () ));
  };

=head1 DESCRIPTION

B<Experimental.> A subclass of L<Rex::GPU::Detect> that detects GPUs from
the kernel's view of the PCI bus, C</sys/bus/pci/devices>, instead of
C<lspci -nn>. For callers that must not install a package just to detect
(no C<pciutils>), or whose hosts' C<pci.ids> is too old to name the newest
cards anyway -- vendor, device and class come from the hardware, not from a
name database.

What it B<does not> give: product names (sysfs has none, see
L</detect>), and therefore no C<compute> decision from a name -- an NVIDIA
display-class device whose ID the generation table does not cover is
C<compute =E<gt> undef>, not C<0> -- and no NVSwitch recognised by name
alone.

What it shares with the C<lspci> detection, as one source: the generation
table (L<Rex::GPU::NVIDIA::Requirement>, through
L<Rex::GPU::Detect/requirement_class>), the vGPU table
(L<Rex::GPU::Detect/vgpu_class>), the NVSwitch device IDs
(L<Rex::GPU::Detect/nvswitch_device_ids>) and the virtual display vendors
(L<Rex::GPU::Detect/virtual_display_vendor_ids>). A subclass overrides
those, or any helper, as for L<Rex::GPU::Detect> (see
L<Rex::GPU/CLASSES OF YOUR OWN>).

Like C<lspci>, sysfs lists every PCI device whatever driver it is bound
to: a GPU bound to C<vfio-pci> for passthrough to a VM is reported like any
other. In a container, C</sys> shows the host's PCI devices, so the result
is the host's.

=head2 detect

  my $gpus = Rex::GPU::Detect::Sysfs->detect;

B<Experimental.> Detect GPU hardware on the remote host from
C</sys/bus/pci/devices>: one read-only command reads C<class>, C<vendor>,
C<device>, C<subsystem_vendor> and C<subsystem_device> of every PCI device,
and the rest is decided here. It never runs C<lspci> and never installs
anything (no C<pciutils>), and it needs no SFTP. Returns the same hashref as
L<Rex::GPU::Detect/detect> -- C<nvidia>, C<amd> and C<nvswitch>, always all
three array refs -- with the differences below; everything not named there
is as documented for L<Rex::GPU::Detect/detect>.

  {
    nvidia => [
      {
        name      => "NVIDIA GPU [10de:2204]",  # sysfs has no names
        vendor    => "nvidia",
        pci_class => "0300",      # "0300" or "0302"
        compute   => 1,           # 1, 0 or undef, see below
        device_id => "2204",      # four lowercase hex digits; undef if unreadable
        subsystem_vendor_id => "1043",  # likewise, no 0x
        subsystem_id        => "87b5",  # likewise
        vgpu      => 0,           # 1 for an NVIDIA vGPU guest device
        # vgpu_type => "NVIDIA A10-2Q",  # only when vgpu is 1
      }
    ],
    amd => [
      { name => "AMD GPU [1002:744c]", vendor => "amd",
        pci_class => "0300", compute => 0 }
    ],
    nvswitch => [
      { name => "NVIDIA NVSwitch [10de:22a3]", vendor => "nvidia",
        pci_class => "0680", device_id => "22a3" }
    ],
  }

=over

=item * B<Names.> sysfs knows no product names, so C<name> is
C<NVIDIA GPU [10de:XXXX]> (C<????> for a device ID it could not read),
C<AMD GPU [1002:XXXX]> or C<NVIDIA NVSwitch [10de:XXXX]>. It is only for
messages; nothing is decided by it.

=item * B<C<compute>> is what L<Rex::GPU::Detect/NVIDIA compute
classification> gives wherever the device ID's generation row or the PCI
class decides: C<0> with the Kepler warning for Kepler or older at any
class, C<1> for class C<0302>, C<1> for a generation row that is compute.
Where the C<lspci> path would fall back to the B<name rules> -- a class
C<0300> device whose ID no generation row covers (C<3000> and up, bar
Blackwell Ultra), or whose ID was unreadable -- there is no name to judge,
and C<compute> is B<C<undef>> ("undecided"), with a warning. The C<lspci>
path says C<0> there. L<Rex::GPU/gpu_setup> installs a driver only for a
true C<compute>, so an undecided GPU gets none, as an unknown one does with
C<lspci>; a caller that wants to try the driver for it passes it to
L<Rex::GPU::NVIDIA/install_driver> itself.

=item * B<IDs> -- C<device_id>, C<subsystem_vendor_id>, C<subsystem_id> --
are four lowercase hex digits without C<0x> (sysfs reads C<0x10de>), the
form the C<lspci> path gives and L<Rex::GPU::NVIDIA/install_driver>
requires; C<undef> where sysfs could not be read. A device without
subsystem IDs reads C<0000>, which is kept.

=item * B<Subsystem IDs and vGPU.> C<subsystem_vendor_id> and
C<subsystem_id> come from sysfs C<subsystem_vendor> / C<subsystem_device>,
for every NVIDIA GPU, so no PCI slot has to be matched. C<vgpu> and C<vgpu_type> are decided from them by the same vGPU
table as with C<lspci> (see L<Rex::GPU::Detect/NVIDIA vGPU guests>).

=item * B<NVSwitch.> Only an NVIDIA device of PCI class C<0680> whose
device ID is in L<Rex::GPU::Detect/nvswitch_device_ids> counts; with no
name there is no acceptance by name. Another NVIDIA C<0680> device is
logged and skipped. As with C<lspci>, C<nvswitch> is C<[]> when no NVIDIA
GPU was found.

=item * B<Virtual displays> (L<Rex::GPU::Detect/virtual_display_vendor_ids>)
are skipped per device, never hiding a real card next to them, as with
C<lspci>. Only class C<0300> and C<0302> devices are display devices here
too.

=item * B<Order.> Devices are reported in the order of their PCI address.

=back

B<Dies> -- before anything is installed or changed, and instead of
reporting "no GPU" for a host it could not look at -- when
C</sys/bus/pci/devices> is missing or unreadable, when the read exits
non-zero, when a line of it is not six fields, and when the C<class> or
C<vendor> of B<any> PCI device is unreadable or malformed: such a device
could be the GPU, so it is not skipped. A device removed while it is read
can cause this; run again. A readable but empty C</sys/bus/pci/devices> (no
PCI device at all) returns empty arrays.

Selection is explicit; C<Rex::GPU::Detect> (C<lspci>) stays the default,
also where sysfs exists -- which is every Linux host, so "sysfs if present"
would switch every caller, L<Rex::Rancher>'s C<gpu =E<gt> 1> included, to
other names and another C<compute> for unknown IDs. Choose it any of these
ways:

  use Rex::GPU::Detect::Sysfs;   # for the direct call only; the rest load it
  my $gpus = Rex::GPU::Detect::Sysfs->detect;

  my $gpus = gpu_detect(detect => 'Rex::GPU::Detect::Sysfs');
  gpu_setup(detect => 'Rex::GPU::Detect::Sysfs', containerd_config => 'rke2');
  set gpu_detect_class => 'Rex::GPU::Detect::Sysfs';   # Rexfile-wide, detect() too

=head1 SEE ALSO

L<Rex::GPU::Detect>, L<Rex::GPU>, L<Rex::GPU::NVIDIA/install_driver>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-gpu/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
