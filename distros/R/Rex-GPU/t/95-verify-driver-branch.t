#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Setup->verify_driver_branch (karr k100, k106): the branch that IS installed
# is checked against what the GPUs need, after verify_packages and before
# Fabric Manager, the nouveau blacklist, the initramfs and the reboot.
#
# On Debian the driver packages carry no branch in their name (nvidia-driver,
# nvidia-kernel-open-dkms) and on RHEL's cuda-open-dkms neither, so a held,
# pinned, locked or stream-kept older package passes the dpkg/rpm state check.
# The step runs only where the GPUs' requirement has a min_branch or
# max_branch AND the source names driver_version_from; it reads that package's
# installed upstream version (dpkg-query / rpm -q --qf) and asks
# Requirement->why_not with the source's kernel_module.
#
# CLAIMS (every "dies" claim: the driver packages WERE installed, and nothing
# of "followed" ran -- no blacklist-nouveau, no update-initramfs / dracut, no
# modprobe nvidia, no nvidia-fabricmanager install or enable; every "lives"
# claim has those lines, so the check on the dies is not vacuous):
#   1. Debian 12, Blackwell 2b85 (CUDA repo, nvidia-kernel-open-dkms, state
#      `hi`): installed 550.163.01-1 dies -- "nvidia-kernel-open-dkms is
#      550.163.01, branch 550 is older than 570", "stay installed"; 615.71.09-1
#      runs through;
#   2. Debian 12, Volta 1db4 (non-free nvidia-driver, max 580): 590.48.01-1
#      dies ("newer than 580"); held at 535.309.01-0+deb12u1 runs through;
#   3. edge versions on that Volta: `1:590.48.01-1` dies (the epoch is cut
#      off, not read as branch 1); empty output, or exit 1, dies with
#      "Cannot read ... (nothing)"; `580.1~rc1-1` runs through;
#   4. no bound, no read: an A100 20b0 (Turing/Ampere block, no bound) on
#      Debian 12/13 and Rocky 9, a host without GPU, and Ubuntu (Blackwell,
#      Volta: a bound, but its packages name the branch and carry no
#      driver_version_from) emit no `dpkg-query ... nvidia-` and no
#      `rpm -q --qf ... nvidia-driver` line;
#   5. RHEL (Rocky 9, cuda-open-dkms): Blackwell with requirement => {
#      min_branch => 580 }: nvidia-driver 575.57.08 dies (no dracut, no
#      blacklist), 580.95.05 runs through; Blackwell without the option: 565
#      dies, 575 runs through (the GPUs' floor is 570, not the source's
#      branch_at_least 580);
#   6. HGX B200 on Debian 12, nvidia-kernel-open-dkms 550: dies, the message
#      names Fabric Manager, the nouveau blacklist, the initramfs and the
#      reboot as not done, and there is no nvidia-fabricmanager install line;
#   7. a source of a subclass without driver_version_from reads nothing: a
#      Blackwell with a held 550 passes, and the blacklist follows;
#   8. the Fabric Manager path is as it was: installed_driver_version reads
#      fabric_manager_match when given no key (and not driver_version_from
#      next to it), and a source without it dies with "names no package to
#      read the driver version from (fabric_manager_match)".
#   9. (k107, the curator's cases) Debian 11 + Ada 27b0: no source fits (non-free
#      470 is older than Ada's floor 525): dies in plan with read-only
#      commands only (golden driver/debian-11--ada);
#  10. Debian 12 + RTX 4070 SUPER 2783 (first listed in 550, non-free 12 has
#      535): the CUDA repository with the open module, not non-free (golden
#      driver/debian-12--rtx4070s).
#
# NOT covered:
#   * the dpkg-query / rpm answers are hand-written (Test::RexGPU::Golden): the
#     version strings imitate bookworm's nvidia-driver, the CUDA repository's
#     615.71.09-1 and rpm's %{VERSION} -- NOT captures from a host; the 550 /
#     590 / 575 / 565 cases are invented hosts;
#   * that apt-mark hold, a pin, `dnf versionlock` or a module stream really
#     keeps those versions -- the test only says what the step does when the
#     version is what the host reports;
#   * the kernel_module half checks the source's DECLARATION, not the module
#     on the host (nvidia-driver can also be satisfied by an open kernel
#     package on Debian);
#   * Ubuntu and SUSE have no driver_version_from (the branch is in the Ubuntu
#     package name; SUSE removes all NVIDIA packages first) -- claim 4 says
#     only that nothing is read there;
#   * whether the die's advice ("remove the hold ...") fits a given host;
#   * a real reboot, a real DKMS build, a real GPU.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile gpu_fixture dpkg_l mutating_lines );
use Rex::GPU::NVIDIA;
use Rex::GPU::NVIDIA::Setup::Apt;
use Rex::GPU::NVIDIA::Setup::Debian;
use Rex::GPU::NVIDIA::Setup::RHEL;

my $DKMS_Q = q{dpkg-query -W -f='${Version}' nvidia-kernel-open-dkms 2>/dev/null};
my $DRV_Q  = q{dpkg-query -W -f='${Version}' nvidia-driver 2>/dev/null};
my $RPM_Q  = q{rpm -q --qf '%{VERSION}' nvidia-driver 2>&1};

sub driver_on {
  my ( $host, %args ) = @_;
  return record_host(host => $host, code => sub { Rex::GPU::NVIDIA::install_driver(%args) });
}

# what follows the driver install; empty for a run that died before it
sub followed {
  my ( $rec ) = @_;
  return grep { /blacklist-nouveau|update-initramfs|dracut|modprobe nvidia|install -y nvidia-fabricmanager|systemctl enable nvidia-fabricmanager/ }
    @{ $rec->{lines} };
}
sub installed_the_driver { my ( $rec, $re ) = @_; return scalar grep { /install -y .*$re/ } @{ $rec->{lines} } }
sub reads { my ( $rec ) = @_; return grep { /dpkg-query .*nvidia-|rpm -q --qf .*nvidia-driver/ } @{ $rec->{lines} } }

my $UNDONE = qr/The driver packages stay installed; the nouveau blacklist, the initramfs and the reboot were not done/;

sub dies_unfit {
  my ( $rec, $label, $re, $installed ) = @_;
  like($rec->{error} // '', $re, "$label: dies, the message names the version and the branch");
  like($rec->{error} // '', $UNDONE, "$label: ... and says the packages stay installed, the rest not done");
  ok(installed_the_driver($rec, $installed), "$label: the driver packages were installed (the die comes after them)");
  is_deeply([ followed($rec) ], [], "$label: nothing of the blacklist, initramfs, modprobe, Fabric Manager followed");
  ok(!$rec->{trapped}, "$label: no unmocked Rex function reached");
}
sub runs_through {
  my ( $rec, $label ) = @_;
  is($rec->{error}, undef, "$label: lives");
  ok(( grep { /blacklist-nouveau/ } followed($rec) ) && ( grep { /update-initramfs|dracut/ } followed($rec) ),
    "$label: the blacklist and the initramfs follow");
  ok(!$rec->{trapped}, "$label: no unmocked Rex function reached");
}

#### 1. Debian 12, Blackwell, nvidia-kernel-open-dkms

subtest 'claim 1: Debian 12 Blackwell: a held 550 dies, 615 runs through' => sub {
  my $held = driver_on(host_profile('debian-12', responses => [
    dpkg_l('nvidia-kernel-open-dkms' => 'hi'), [ $DKMS_Q => '550.163.01-1', 0 ] ]), gpu => gpu_fixture('blackwell'));
  dies_unfit($held, '550', qr/nvidia-kernel-open-dkms is 550\.163\.01, branch 550 is older than 570/, 'nvidia-kernel-open-dkms');
  is(scalar(reads($held)), 1, '... read once: one dpkg-query for the open module');
  is($held->{lines}[-1], "run: $DKMS_Q", '... and that is the last command');

  runs_through(driver_on(host_profile('debian-12', responses => [ [ $DKMS_Q => '615.71.09-1', 0 ] ]),
    gpu => gpu_fixture('blackwell')), '615');
};

#### 2. Debian 12, Volta, nvidia-driver

subtest 'claim 2: Debian 12 Volta: 590 dies, a held 535 runs through' => sub {
  my $rec = driver_on(host_profile('debian-12', responses => [ [ $DRV_Q => '590.48.01-1', 0 ] ]), gpu => gpu_fixture('volta'));
  dies_unfit($rec, '590', qr/nvidia-driver is 590\.48\.01, branch 590 is newer than 580/, 'nvidia-driver');
  runs_through(driver_on(host_profile('debian-12', responses => [
    dpkg_l('nvidia-driver' => 'hi'), [ $DRV_Q => '535.309.01-0+deb12u1', 0 ] ]), gpu => gpu_fixture('volta')), 'held 535');
};

#### 3. edge versions

subtest 'claim 3: epoch, no answer, a pre-release' => sub {
  my $rec = driver_on(host_profile('debian-12', responses => [ [ $DRV_Q => '1:590.48.01-1', 0 ] ]), gpu => gpu_fixture('volta'));
  dies_unfit($rec, 'epoch 1:590.48.01-1', qr/nvidia-driver is 590\.48\.01, branch 590 is newer than 580/, 'nvidia-driver');
  unlike($rec->{error} // '', qr/branch 1\b/, '... the epoch is not taken for the branch');

  for my $case ([ 'empty output, exit 0' => [ '', 0 ] ], [ 'empty output, exit 1' => [ '', 1 ] ]) {
    my ( $label, $answer ) = @$case;
    $rec = driver_on(host_profile('debian-12', responses => [ [ $DRV_Q => @$answer ] ]), gpu => gpu_fixture('volta'));
    dies_unfit($rec, $label, qr/Cannot read the installed NVIDIA driver version from nvidia-driver \(nothing\)/, 'nvidia-driver');
  }

  runs_through(driver_on(host_profile('debian-12', responses => [ [ $DRV_Q => '580.1~rc1-1', 0 ] ]),
    gpu => gpu_fixture('volta')), '580.1~rc1-1');
};

#### 4. no bound, nothing read

subtest 'claim 4: without a bound, or without driver_version_from, nothing is read' => sub {
  my $a100 = { %{ gpu_fixture('ada') }, device_id => '20b0', name => 'GA100 [A100 SXM4 40GB]' };
  for my $os (qw( debian-12 debian-13 rocky-9 )) {
    my $rec = driver_on(host_profile($os), gpu => $a100);
    is($rec->{error}, undef, "$os + A100 (no bound): lives");
    ok(( grep { /blacklist-nouveau/ } @{ $rec->{lines} } ), '... the install ran to the blacklist');
    is_deeply([ reads($rec) ], [], '... no dpkg-query / rpm -q --qf of a driver package');
  }
  for my $os (qw( debian-12 rocky-9 )) {
    my $rec = driver_on(host_profile($os));
    is_deeply([ reads($rec) ], [], "$os, no GPU: nothing read");
  }
  # control: the same hosts with a GPU that has a bound (Ada, floor 525) do read
  for my $os (qw( debian-12 debian-13 rocky-9 )) {
    my $rec = driver_on(host_profile($os), gpu => gpu_fixture('ada'));
    is(scalar(reads($rec)), 1, "control, $os + Ada (floor 525): exactly one read");
  }
  for my $os (qw( ubuntu-24.04 ubuntu-22.04 )) {
    for my $g (qw( blackwell volta )) {
      my $rec = driver_on(host_profile($os), gpu => gpu_fixture($g));
      is_deeply([ reads($rec) ], [], "$os + $g (a bound, but no driver_version_from): nothing read");
    }
  }
};

#### 5. RHEL

subtest 'claim 5: Rocky 9 cuda-open-dkms checks the installed branch against the GPUs, not the source' => sub {
  my $rec = driver_on(host_profile('rocky-9', responses => [ [ $RPM_Q => '575.57.08', 0 ] ]),
    gpu => gpu_fixture('blackwell'), requirement => { min_branch => 580 });
  dies_unfit($rec, 'min_branch 580, 575.57.08', qr/nvidia-driver is 575\.57\.08, branch 575 is older than 580/, 'nvidia-open');
  is($rec->{lines}[-1], "run: $RPM_Q", '... the read is the last command');
  runs_through(driver_on(host_profile('rocky-9', responses => [ [ $RPM_Q => '580.95.05', 0 ] ]),
    gpu => gpu_fixture('blackwell'), requirement => { min_branch => 580 }), 'min_branch 580, 580.95.05');

  $rec = driver_on(host_profile('rocky-9', responses => [ [ $RPM_Q => '565.57.01', 0 ] ]), gpu => gpu_fixture('blackwell'));
  dies_unfit($rec, 'Blackwell, 565', qr/nvidia-driver is 565\.57\.01, branch 565 is older than 570/, 'nvidia-open');
  runs_through(driver_on(host_profile('rocky-9', responses => [ [ $RPM_Q => '575.57.08', 0 ] ]), gpu => gpu_fixture('blackwell')),
    'Blackwell, 575 (the source says branch_at_least 580; the GPU needs 570)');
};

#### 6. HGX B200, Debian 12

subtest 'claim 6: HGX B200 on Debian 12 with 550: dies before Fabric Manager' => sub {
  my @fm = (
    [ $DKMS_Q => '550.163.01-1', 0 ],
    [ 'LC_ALL=C apt-cache policy nvidia-fabricmanager 2>/dev/null' => "nvidia-fabricmanager:\n  Installed: (none)\n  Candidate: 615.71.09-1\n", 0 ],
    [ 'apt-cache madison nvidia-fabricmanager 2>/dev/null' =>
        " nvidia-fabricmanager | 615.71.09-1 | https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64  Packages", 0 ],
  );
  my $rec = driver_on(host_profile('debian-12', responses => \@fm), gpus => [ ( gpu_fixture('b200') ) x 8 ]);
  like($rec->{error} // '', qr/nvidia-kernel-open-dkms is 550\.163\.01, branch 550 is older than 570/, 'dies, naming the version');
  like($rec->{error} // '', qr/The driver packages stay installed; Fabric Manager, the nouveau blacklist, the initramfs and the reboot were not done/,
    '... Fabric Manager, the blacklist, the initramfs and the reboot not done');
  ok(installed_the_driver($rec, 'nvidia-kernel-open-dkms'), '... the driver was installed');
  is_deeply([ followed($rec) ], [], '... no Fabric Manager install or enable, no blacklist, no initramfs');
  is(scalar(grep { /nvidia-fabricmanager/ && !/apt-cache/ } @{ $rec->{lines} }), 0, '... no other command names nvidia-fabricmanager');
};

#### 7. a source without driver_version_from

{
  package Test::NoBranchCheck;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Debian';
  # the stock sources, minus the key: a subclass's own source that does not name one
  sub sources {
    my ( $self, @args ) = @_;
    return map { my %s = %$_; delete $s{driver_version_from}; \%s } $self->SUPER::sources(@args);
  }
}

subtest 'claim 7: a source without driver_version_from reads nothing' => sub {
  my $rec = driver_on(host_profile('debian-12', responses => [ dpkg_l('nvidia-kernel-open-dkms' => 'hi'), [ $DKMS_Q => '550.163.01-1', 0 ] ]),
    gpu => gpu_fixture('blackwell'), setup => 'Test::NoBranchCheck');
  runs_through($rec, 'held 550, own source');
  is_deeply([ reads($rec) ], [], '... no dpkg-query of a driver package');

  # control: the stock source on the same host does read, and dies
  $rec = driver_on(host_profile('debian-12', responses => [ dpkg_l('nvidia-kernel-open-dkms' => 'hi'), [ $DKMS_Q => '550.163.01-1', 0 ] ]),
    gpu => gpu_fixture('blackwell'));
  like($rec->{error} // '', qr/branch 550 is older than 570/, 'control: the stock source dies on the same host');
};

#### 8. the Fabric Manager path

subtest 'claim 8: installed_driver_version without a key is the Fabric Manager read, as before' => sub {
  my $source = { fabric_manager_match => 'nvidia-kernel-open-dkms', driver_version_from => 'nvidia-driver' };
  my $rec = record_host(host => host_profile('debian-12', responses => [ [ $DKMS_Q => '615.71.09-1', 0 ], [ $DRV_Q => '535.309.01-0+deb12u1', 0 ] ]),
    code => sub { Rex::GPU::NVIDIA::Setup::Debian->new->installed_driver_version($source) });
  is_deeply($rec->{lines}, [ "run: $DKMS_Q" ], 'Debian: the fabric_manager_match package is read, not driver_version_from');

  $rec = record_host(host => host_profile('rocky-9'),
    code => sub { Rex::GPU::NVIDIA::Setup::RHEL->new->installed_driver_version({ driver_version_from => 'nvidia-driver' }) });
  is($rec->{error}, 'The driver source names no package to read the driver version from (fabric_manager_match); '
    .'the driver is installed, Fabric Manager is not', 'RHEL: a source with only driver_version_from: the old message, naming fabric_manager_match');
  is_deeply($rec->{lines}, [], '... before any host interaction');
};

#### 9 and 10: the k107 floors on Debian

subtest 'claim 9: Debian 11 + Ada: no source fits, only read-only commands' => sub {
  my $rec = driver_on(host_profile('debian-12', release => '11.11'), gpu => gpu_fixture('ada'));
  like($rec->{error} // '', qr/debian-nonfree: branch 470 is older than 525/, 'dies, naming non-free 470 against the floor 525');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... only read-only commands ran');
  ok(!$rec->{trapped}, '... no unmocked Rex function reached');
  golden_is($rec, 'driver/debian-11--ada');
};

subtest 'claim 10: Debian 12 + RTX 4070 SUPER takes the CUDA repository with the open module' => sub {
  my $gpu = { name => 'AD104 [GeForce RTX 4070 SUPER]', vendor => 'nvidia', pci_class => '0300', compute => 1, device_id => '2783' };
  my $rec = driver_on(host_profile('debian-12'), gpu => $gpu);
  is($rec->{error}, undef, 'lives');
  ok(( grep { /cuda-keyring/ } @{ $rec->{lines} } ), '... the CUDA repository is set up');
  ok(( grep { /install -y .*nvidia-kernel-open-dkms/ } @{ $rec->{lines} } ), '... the open module is installed');
  ok(!( grep { /install -y .*nvidia-driver nvidia-smi libcuda1/ } @{ $rec->{lines} } ), '... not non-free');
  is(scalar(reads($rec)), 1, '... and its branch is read once (a bound: 550, installed 615.71.09-1 passes)');
  golden_is($rec, 'driver/debian-12--rtx4070s');
};

done_testing;
