# ABSTRACT: Base class of the AMD driver setups: preflight, install flow, signing keys, repository files (experimental)

package Rex::GPU::AMD::Setup;
our $VERSION = '0.006';
use Moo;
use Rex::Logger ();
use namespace::autoclean;


has amd        => ( is => 'ro', required => 1 );
has gpus       => ( is => 'ro', default => sub { [] } );
has state      => ( is => 'ro' );
has os_release => ( is => 'lazy' );
has kernel     => ( is => 'lazy' );
has arch       => ( is => 'lazy' );

sub _build_os_release { $_[0]->amd->read_os_release }
sub _build_kernel     { _trim($_[0]->run_cmd('uname -r')) }
sub _build_arch       { _trim($_[0]->run_cmd('uname -m')) }


sub run_cmd {
  my ( $self, $command, %opt ) = @_;
  return $self->amd->host_run($command, %opt);
}

sub os_version { $_[0]->os_release->{VERSION_ID} // '' }

sub os_label {
  my ( $self ) = @_;
  my $os = $self->os_release;
  return $os->{PRETTY_NAME} // join(' ', grep { defined } $os->{ID}, $os->{VERSION_ID}) || 'unknown OS';
}

#### The flow #################################################################


sub install {
  my ( $self, $method ) = @_;
  my $plan = $method eq 'dkms' ? $self->plan_dkms : $self->plan_inbox;
  return 0 unless $plan->{needed};
  $self->prepare_host($plan);
  $self->prepare_source($plan);
  $self->resolve_plan($plan);
  $self->install_packages($plan);
  $self->verify_packages($plan);
  $self->post_install($plan);
  return 1;
}


sub plan_inbox {
  my ( $self ) = @_;
  if (my $why = $self->host_unsupported) {
    die 'install_driver: '.$why.". Nothing was changed on the host\n";
  }
  $self->preflight;
  $self->check_radeon;
  my @only = grep { ( $_->{driver} // '' ) eq 'inbox' } @{ $self->gpus };
  if (@only and my $why = $self->inbox_only_unsupported) {
    die 'install_driver: '.$self->_labels(@only).': '.$why.". Nothing was changed on the host\n";
  }
  if (my $why = $self->inbox_unsupported) {
    die 'install_driver: '.$why.". Nothing was changed on the host\n";
  }
  my $plan = { method => 'inbox', packages => [], optional => [] };
  unless (defined $self->amd->module_source(kernel => $self->kernel)) {
    my @packages = $self->inbox_module_packages;
    die 'install_driver: kernel '.$self->kernel.' has no amdgpu module, and no package for it '
      .'is known on '.$self->os_label.". Nothing was changed on the host\n"
      unless @packages;
    $plan->{required} = \@packages;
  }
  my @firmware = $self->firmware_packages;
  $plan->{firmware} = \@firmware
    if @firmware && !grep { $self->package_installed($_) } @firmware;
  $plan->{needed} = $plan->{required} || $plan->{firmware} ? 1 : 0;
  return $plan;
}

sub plan_dkms {
  my ( $self ) = @_;
  if (my $why = $self->host_unsupported) {
    die 'install_driver: '.$why.". Nothing was changed on the host\n";
  }
  $self->preflight;
  $self->check_radeon;
  die 'install_driver: amdgpu-dkms is built for '.$self->supported_arch.' only; this host is '
    .$self->arch.". Nothing was changed on the host\n"
    unless $self->arch eq $self->supported_arch;
  if (my $why = $self->dkms_unsupported) {
    die 'install_driver: '.$why.". Nothing was changed on the host\n";
  }
  die "install_driver: Secure Boot is enabled -- the amdgpu-dkms module would be signed with a "
    ."machine owner key (MOK) that has to be enrolled at the console before it loads. Disable "
    ."Secure Boot or use the inbox driver. Nothing was changed on the host\n"
    if $self->secure_boot_enabled;
  my $repo = $self->dkms_repo;
  my $current = $self->file_content($repo->{file});
  if (length $current) {
    die 'install_driver: '.$repo->{file}.' exists with other content than amdgpu '.$self->amdgpu_release
      .' needs; install_driver does not replace a repository it did not write. Nothing was changed '
      ."on the host\n"
      unless _trim($current) eq _trim($repo->{content});
    $repo->{present} = 1;
  }
  my @headers = $self->kernel_header_packages;
  return {
    method   => 'dkms',
    needed   => $self->dkms_built ? 0 : 1,
    packages => [],
    required => [ @headers, 'amdgpu-dkms' ],
    headers  => \@headers,
    optional => [ $self->optional_packages ],
    repo     => $repo,
  };
}


sub preflight {
  my ( $self ) = @_;
  my $cmdline = $self->run_cmd('cat /proc/cmdline 2>/dev/null') // '';
  for my $word (split ' ', $cmdline) {
    my $blocks = $word eq 'nomodeset' || $word eq 'amdgpu.modeset=0'
      || ( $word =~ /\A(?:modprobe\.blacklist|module_blacklist)=(.*)\z/
           && grep { $_ eq 'amdgpu' } split /,/, $1 );
    die "install_driver: the kernel command line has $word, which keeps amdgpu from loading; "
      ."remove it from the boot loader configuration first. Nothing was changed on the host\n"
      if $blocks;
  }
  my $blacklist = $self->run_cmd(q{grep -rsHE --include='*.conf' }
    .q{'^[[:space:]]*(blacklist[[:space:]]+amdgpu|install[[:space:]]+amdgpu[[:space:]]+(/usr)?/bin/(false|true))([[:space:]]|$)' }
    .q{/etc/modprobe.d /run/modprobe.d /usr/lib/modprobe.d /lib/modprobe.d 2>/dev/null}) // '';
  my @lines = grep { /\S/ } split /\r?\n/, $blacklist;
  die 'install_driver: amdgpu is blacklisted ('.join('; ', @lines).'); remove that first. '
    ."Nothing was changed on the host\n"
    if @lines;
  for my $gpu (grep { defined $_->{bound_driver} && $_->{bound_driver} ne 'amdgpu' } @{ $self->gpus }) {
    die 'install_driver: '.$self->amd->gpu_label($gpu).' is bound to '.$gpu->{bound_driver}
      ."; install_driver does not unbind it. Nothing was changed on the host\n";
  }
  return;
}


sub check_radeon {
  my ( $self ) = @_;
  my @radeon = grep { ( $_->{matrix} // '' ) eq 'radeon' } @{ $self->gpus };
  if (@radeon and my $why = $self->radeon_unsupported) {
    die 'install_driver: '.$self->_labels(@radeon).': '.$why.". Nothing was changed on the host\n";
  }
  return;
}


# k91: AMD's matrix binds ROCm as it binds the driver (k82), in the order of
# plan_inbox and plan_dkms: the Radeon check first, then the Ryzen APUs'.
sub check_rocm_matrix {
  my ( $self, $targets ) = @_;
  my $hardware = $self->amd->hardware_class;
  my %table;
  for my $gfx (@$targets) {
    my $row = $hardware->target($gfx) or next;
    push @{ $table{ $row->{matrix} } }, $gfx if defined $row->{matrix};
  }
  for my $check ([ radeon => 'radeon_unsupported' ], [ ryzen => 'inbox_only_unsupported' ]) {
    my ( $matrix, $unsupported ) = @$check;
    my $gfx = $table{$matrix} or next;
    my $why = $self->$unsupported // next;
    die "install_rocm: AMD's ROCm compatibility matrix does not list ".join(', ', @$gfx)
      .' for this OS and kernel: '.$why.". Nothing was changed on the host\n";
  }
  return;
}


sub fallback_method {
  my ( $self ) = @_;
  return 'inbox' if defined $self->amd->module_source(kernel => $self->kernel);
  return 'inbox' if grep { $self->has_candidate($_) } $self->inbox_module_packages;
  return 'dkms';
}


sub prepare_host { }

sub prepare_source {
  my ( $self, $plan ) = @_;
  if (my $repo = $plan->{repo}) {
    $self->install_helpers;
    $self->install_key(%{ $repo->{key} });
    $self->write_file($repo->{file}, $repo->{content}) unless $repo->{present};
  }
  $self->refresh_index;
  return;
}

sub resolve_plan {
  my ( $self, $plan ) = @_;
  my %header = map { $_ => 1 } @{ $plan->{headers} || [] };
  for my $package (@{ $plan->{required} || [] }) {
    unless ($self->has_candidate($package)) {
      die 'install_driver: '.$package.', a header package of the running kernel '.$self->kernel
        ." that amdgpu-dkms is built against, cannot be installed from the host's package sources "
        ."(no candidate): they do not (or no longer) carry this kernel's headers, usually because "
        .'they have moved on to a newer kernel the host was not upgraded to or rebooted into. '
        .'Upgrade the kernel, reboot into it and run install_driver again. '
        .$self->_unresolved_note($plan)."\n"
        if $header{$package};
      die "install_driver: $package cannot be installed from the host's package sources (no "
        .'candidate). '.$self->_unresolved_note($plan)."\n";
    }
    push @{ $plan->{packages} }, $package;
  }
  push @{ $plan->{packages} }, grep { $self->has_candidate($_) } @{ $plan->{optional} || [] };
  if (my $firmware = $plan->{firmware}) {
    my ( $package ) = grep { $self->has_candidate($_) } @$firmware;
    die 'install_driver: none of the amdgpu firmware packages ('.join(', ', @$firmware)
      .") can be installed from the host's package sources. ".$self->_unresolved_note($plan)."\n"
      unless defined $package;
    push @{ $plan->{packages} }, $package;
  }
  return;
}

# What resolve_plan leaves behind when it dies: prepare_source has already
# written the repository file and the key (dkms), but no package went in.
sub _unresolved_note {
  my ( $self, $plan ) = @_;
  my $repo = $plan->{repo} or return 'Nothing was installed';
  return 'No driver package was installed; the amdgpu repository '.$repo->{file}
    .' and its signing key '.$repo->{key}{path}.' are in place, and a re-run accepts them';
}


sub post_install {
  my ( $self, $plan ) = @_;
  my $kernel = $self->kernel;
  my $source = $self->amd->module_source(kernel => $kernel) // '';
  if ($plan->{method} eq 'dkms') {
    unless ($self->dkms_built) {
      # k95: the package manager leaves a held amdgpu-dkms as it is (apt:
      # or aborts the whole install), so the hold goes first in the message
      my $hold = $self->hold_note($plan);
      die "install_driver: amdgpu-dkms is installed, but dkms reports no amdgpu module built and "
        ."installed for kernel $kernel; ".( length $hold ? "$hold; if the module is still missing then, " : '' )
        ."see /var/lib/dkms/amdgpu/*/build/make.log\n";
    }
    die "install_driver: amdgpu-dkms is built for kernel $kernel, but modinfo still resolves "
      ."amdgpu to ".( length $source ? "the $source module" : 'no module' )."\n"
      unless $source eq 'dkms';
  }
  else {
    die "install_driver: no amdgpu module for kernel $kernel after installing "
      .join(', ', @{ $plan->{packages} })."\n"
      unless length $source;
  }
  return;
}

#### Host facts and helpers ###################################################


sub dkms_built {
  my ( $self ) = @_;
  my $kernel = $self->kernel;
  my $out = $self->run_cmd("dkms status -m amdgpu -k $kernel 2>&1") // '';
  return ( grep { /\Q$kernel\E/ && /:\s*installed\b/ } split /\r?\n/, $out ) ? 1 : 0;
}

sub secure_boot_enabled {
  my ( $self ) = @_;
  my $out = $self->run_cmd('od -An -tu1 -j4 -N1 '
    .'/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>/dev/null') // '';
  return $out =~ /\A\s*1\s*\z/ ? 1 : 0;
}

sub file_content {
  my ( $self, $path ) = @_;
  return $self->run_cmd("cat $path 2>/dev/null") // '';
}

sub write_file {
  my ( $self, $path, $content ) = @_;
  ( my $quoted = $content ) =~ s/'/'\\''/g;
  $self->run_cmd("printf '%s' '$quoted' > $path.tmp && chmod 0644 $path.tmp && mv -f $path.tmp $path");
  if ($? != 0) {
    $self->run_cmd("rm -f $path.tmp");
    die "Could not write $path on the host\n";
  }
  return;
}

sub install_key {
  my ( $self, %key ) = @_;
  my ( $url, $fingerprint, $path ) = @key{qw( url fingerprint path )};
  my $dir = "$path.tmp.d";
  ( my $parent = $path ) =~ s{/[^/]+\z}{};
  $self->run_cmd("mkdir -p -m 0755 $parent && rm -rf $dir && mkdir -m 0700 $dir "
    ."&& curl -fsSL --proto =https $url -o $dir/key.asc");
  if ($? != 0) {
    $self->run_cmd("rm -rf $dir");
    die "Could not download the AMD signing key ($url); $path was not changed\n";
  }
  my $listing = $self->run_cmd("GNUPGHOME=$dir gpg --batch --with-colons --show-keys $dir/key.asc 2>/dev/null");
  my @primary = $self->_primary_fingerprints($listing);
  unless (@primary == 1 && $primary[0] eq uc $fingerprint) {
    $self->run_cmd("rm -rf $dir");
    die "The key from $url is not the AMD signing key expected (fingerprint $fingerprint; got "
      .( join(', ', @primary) || 'none' )."); $path was not changed\n";
  }
  my $ok = $self->place_key($dir, $path);
  $self->run_cmd("rm -rf $dir");
  die "Could not install the AMD signing key into $path\n" unless $ok;
  $self->run_cmd("test -s $path");
  die "AMD signing key $path is missing or empty\n" if $? != 0;
  return;
}

sub place_key { die ref($_[0])." has no place_key\n" }

# gpg --with-colons: the fpr record that follows each pub record.
sub _primary_fingerprints {
  my ( $self, $listing ) = @_;
  my ( @fingerprints, $after_pub );
  for my $line (split /\r?\n/, $listing // '') {
    my @field = split /:/, $line;
    next unless @field;
    if ($field[0] eq 'pub') { $after_pub = 1; next }
    if ($field[0] eq 'fpr' && $after_pub) { push @fingerprints, uc( $field[9] // '' ); $after_pub = 0 }
  }
  return @fingerprints;
}

#### Packaging layer (Apt, RHEL) ##############################################


sub supported_arch   { 'x86_64' }
sub refresh_index    { }
sub has_candidate    { 1 }
sub package_installed { 0 }
sub package_held     { 0 }
sub install_helpers  { }
sub install_packages { die ref($_[0])." has no install_packages\n" }
sub verify_packages  { die ref($_[0])." has no verify_packages\n" }

# k108: amdgpu-dkms 31.60 Depends (noble Packages) and Requires (el9
# primary.xml) amdgpu-dkms-firmware, without a version; read 2026-11-26.
sub dkms_dependencies { qw( amdgpu-dkms-firmware ) }

sub blocking_holds {
  my ( $self, $plan ) = @_;
  return grep { $self->package_held($_) } $self->_hold_packages($plan);
}

# k108: one wording for post_install and every verify_packages; only a dkms
# plan is asked (amdgpu-dkms in it), as since k95/k101.
sub hold_note {
  my ( $self, $plan ) = @_;
  return '' unless ( $plan->{method} // '' ) eq 'dkms';
  my @held = $self->blocking_holds($plan) or return '';
  return $self->hold_advice(@held);
}

sub hold_advice {
  my ( $self, @held ) = @_;
  return $self->_and_list(@held).( @held > 1 ? ' are' : ' is' ).' on hold, and the package manager '
    .'does not change a held package. Release the hold and run install_driver again';
}

# The plan's packages, then the dkms_dependencies it does not list itself.
sub _hold_packages {
  my ( $self, $plan ) = @_;
  my %seen;
  return grep { !$seen{$_}++ } @{ $plan->{packages} || [] }, $self->dkms_dependencies;
}

sub _and_list {
  my ( $self, @items ) = @_;
  return @items > 1 ? join(', ', @items[0 .. $#items - 1]).' and '.$items[-1] : $items[0];
}

#### Per-OS data ##############################################################


sub amdgpu_release { '31.60' }
sub amdgpu_key_path { '/etc/apt/keyrings/rocm.gpg' }

sub amdgpu_key {
  my ( $self ) = @_;
  return {
    url         => 'https://repo.radeon.com/rocm/rocm.gpg.key',
    fingerprint => 'CA8BB4727A47B4D09B4EE8969386B48A1A693C5C',
    path        => $self->amdgpu_key_path,
  };
}

sub dkms_repo { die ref($_[0])." has no dkms_repo\n" }

sub host_unsupported { return }

sub dkms_unsupported {
  my ( $self ) = @_;
  return 'amdgpu-dkms is not supported on '.$self->os_label;
}

sub inbox_unsupported { return }

sub inbox_only_supported {
  'Ubuntu 26.04 (GA kernel 7.0) and Ubuntu 24.04 (HWE kernel 7.0), per the ROCm 10.1 compatibility matrix'
}

sub inbox_only_unsupported {
  my ( $self ) = @_;
  return 'AMD supports them with the inbox driver only on '.$self->inbox_only_supported
    .'; this host runs '.$self->os_label.' with kernel '.$self->kernel;
}

sub radeon_supported {
  'Ubuntu 26.04 (GA kernel 7.0), Ubuntu 24.04 (HWE kernel 7.0), Ubuntu 22.04 (HWE kernel 6.8), '
    .'RHEL 10.2 (kernel 6.12.0-211) and RHEL 9.8 (kernel 5.14.0-687), per the ROCm 10.1 '
    .'compatibility matrix'
}

sub radeon_unsupported {
  my ( $self ) = @_;
  return 'AMD supports Radeon GPUs only on '.$self->radeon_supported
    .'; this host runs '.$self->os_label.' with kernel '.$self->kernel;
}

sub kernel_header_packages { () }
sub optional_packages      { () }
sub firmware_packages      { () }
sub inbox_module_packages  { () }
sub rocm_repo_dir          { return }

sub install_rocm {
  my ( $self ) = @_;
  die 'install_rocm: supported on apt hosts only (Ubuntu 22.04, 24.04, 26.04; Debian 12, 13), not '
    .$self->os_label.". Nothing was changed on the host\n";
}

sub _labels {
  my ( $self, @gpus ) = @_;
  return join ', ', map { $self->amd->gpu_label($_) } @gpus;
}

sub _trim {
  my ( $text ) = @_;
  $text //= '';
  $text =~ s/\A\s+|\s+\z//g;
  return $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::AMD::Setup - Base class of the AMD driver setups: preflight, install flow, signing keys, repository files (experimental)

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  # lib/My/AMD/Setup.pm, next to the Rexfile: a site mirror for amdgpu-dkms
  package My::AMD::Setup;
  use Moo;
  extends 'Rex::GPU::AMD::Setup::Ubuntu';
  around dkms_repo => sub {
    my ( $orig, $self ) = @_;
    my $repo = $self->$orig;
    $repo->{content} =~ s{https://repo\.radeon\.com}{https://mirror.example.com};
    return $repo;
  };
  1;

  # lib/My/GPU/AMD.pm
  package My::GPU::AMD;
  use parent 'Rex::GPU::AMD';
  sub setup_class_for_os {
    my ( $class, $os ) = @_;
    return 'My::AMD::Setup' if ( $os->{ID} // '' ) eq 'ubuntu';
    return $class->SUPER::setup_class_for_os($os);
  }
  1;

  # Rexfile
  set gpu_amd_class => 'My::GPU::AMD';

=head1 DESCRIPTION

B<Experimental.> The base class of the setups L<Rex::GPU::AMD/install_driver>
runs, one per OS family: L<Rex::GPU::AMD::Setup::Ubuntu> and
L<Rex::GPU::AMD::Setup::Debian> on the apt layer
L<Rex::GPU::AMD::Setup::Apt>, and L<Rex::GPU::AMD::Setup::RHEL>. Which one:
L<Rex::GPU::AMD/setup_class_for_os>.

This class holds the flow (L</install>), the checks every OS shares
(L</preflight>, the DKMS checks, L</post_install>), the signing-key and
file helpers, and the per-OS data methods a subclass fills. Driver packages
are installed directly through the packaging layer and verified
afterwards, never through L<Rex::Commands::Pkg>: a DKMS post-install that
exits non-zero makes C<pkg> report a failure on a host where the driver
works, or the other way round.

=head2 amd

The L<Rex::GPU::AMD> class (or subclass) the setup works for, required.
Every host command goes through its L<Rex::GPU::AMD/host_run>.

=head2 gpus

The GPUs to install for, as L<Rex::GPU::AMD/install_driver> resolved them
(C<slot>, C<device_id>, C<gfx_target>, C<driver>, C<matrix>,
C<integrated>, C<bound_driver>, ...). Default C<[]>.

=head2 state

The L<Rex::GPU::AMD/read_state> the install started from, or C<undef>.

=head2 os_release

L<Rex::GPU::AMD/read_os_release>, read when first needed.

=head2 kernel

The running kernel, C<uname -r>, read when first needed.

=head2 arch

The architecture as the packaging names it: C<uname -m> here, C<dpkg
--print-architecture> in L<Rex::GPU::AMD::Setup::Apt>.

=head2 run_cmd

  my $out = $setup->run_cmd($command, %run_options);

L<Rex::GPU::AMD/host_run> of L</amd>: C<auto_die =E<gt> 0>, C<$?> as C<run>
left it.

=head2 os_version

C<VERSION_ID> of L</os_release> (C<24.04>, C<13>, C<9.6>), C<''> without.

=head2 os_label

The OS for messages: C<PRETTY_NAME>, else C<ID VERSION_ID>.

=head2 install

  my $installed = $setup->install($method);   # 'inbox' or 'dkms'

The fixed sequence, each step a method a subclass can override:

  plan_inbox / plan_dkms -> host-read-only; dies before any change
  -- returns 0 here when the plan needs nothing --
  prepare_host($plan)
  prepare_source($plan)   -> signing key and repository file (dkms), index refresh
  resolve_plan($plan)     -> packages that need a candidate (dkms: the kernel
                             headers, amdgpu-dkms); dies before any install
  install_packages($plan)
  verify_packages($plan)
  post_install($plan)     -> the module must be there (dkms: built for the kernel)

Returns C<1> after an install, C<0> if nothing was missing. Loading the
module or rebooting is L<Rex::GPU::AMD/install_driver>'s, after this.

=head2 plan_inbox

Host-read-only. Dies for a L</host_unsupported> reason first, then
L</preflight>, then L</check_radeon>; for GPUs whose hardware row says
C<driver =E<gt> 'inbox'> (AMD supports them with the inbox driver only)
dies unless L</inbox_only_unsupported> is empty, then for any GPU unless
L</inbox_unsupported> is; then what is missing: the
L</inbox_module_packages> when the running kernel has no C<amdgpu.ko>
(dies if there are none), the first of L</firmware_packages> when none of
them is installed. C<needed> is C<0> when nothing is.

=head2 plan_dkms

Host-read-only. Dies for a L</host_unsupported> reason first, then
L</preflight>, then L</check_radeon>, then dies for an architecture other
than L</supported_arch>, a L</dkms_unsupported> reason, Secure Boot
(L</secure_boot_enabled>) and an existing L</dkms_repo> file of other
content. C<needed> is C<0> when C<dkms status> already shows C<amdgpu>
installed for the running kernel; else the plan requires
L</kernel_header_packages> (also listed under C<headers>, for
L</resolve_plan>'s message) and C<amdgpu-dkms> -- neither is looked up
yet: AMD's repository and a fresh index exist only after
L</prepare_source> -- plus those of L</optional_packages> that have a
candidate.

=head2 preflight

Host-read-only; dies before any change when C<amdgpu> could not work after
the install either: C</proc/cmdline> with C<nomodeset>,
C<amdgpu.modeset=0> or a C<modprobe.blacklist=>/C<module_blacklist=>
naming C<amdgpu>; a C<blacklist amdgpu> or C<install amdgpu /bin/false>
line in a C<*.conf> under C</etc/modprobe.d>, C</run/modprobe.d>,
C</usr/lib/modprobe.d> or C</lib/modprobe.d>; a GPU bound to a driver
other than C<amdgpu> (C<vfio-pci>, C<radeon>, ...: it is not unbound).

=head2 check_radeon

Host-read-only: dies, naming them, for the GPUs of L</gpus>
whose hardware row says C<matrix =E<gt> 'radeon'> (the Radeon table of
AMD's ROCm compatibility matrix) unless L</radeon_unsupported> is empty --
whatever the method, since the matrix lists operating systems and kernels
per GPU table, not per driver. A GPU without C<matrix> -- no row, a
C<compute =E<gt> 0> target, a row of your own written without the field --
is not checked: it is not guessed from C<family>. Asked by L</plan_inbox>
and L</plan_dkms> after L</preflight>, and by
L<Rex::GPU::AMD/install_driver> before it names a way out for GPUs whose
hardware rows disagree.

=head2 check_rocm_matrix

  $setup->check_rocm_matrix(\@targets);   # gfx target names, lowercase

Host-read-only: dies, naming them, for the gfx targets whose
L<Rex::GPU::AMD/hardware_class> row says C<matrix =E<gt> 'radeon'> unless
L</radeon_unsupported> is empty, then for those whose row says
C<matrix =E<gt> 'ryzen'> (the Ryzen APUs) unless
L</inbox_only_unsupported> is -- the releases and kernels
L<Rex::GPU::AMD/install_driver> binds these GPUs to. A C<matrix =E<gt>
'instinct'> target and a target without C<matrix> -- no row, a
C<compute =E<gt> 0> target, a row of your own written without the field
-- are not checked. The running kernel is read only for a C<radeon> or
C<ryzen> target. Asked by L<Rex::GPU::AMD::Setup::Apt/install_rocm> after
its C<present> check, before any change.

=head2 fallback_method

For GPUs without a hardware row (L<Rex::GPU::AMD/install_driver> with
C<method =E<gt> 'auto'>): C<inbox> if the running kernel has an
C<amdgpu.ko> or one of L</inbox_module_packages> has a candidate, else
C<dkms>. Host-read-only.

=head2 prepare_host

Nothing here; L<Rex::GPU::AMD::Setup::Apt> stops the apt timers.

=head2 prepare_source

With a repository in the plan (C<dkms>): L</install_helpers>, the signing
key (L</install_key>) and the repository file (L</write_file>, unless it is
already there as needed); then L</refresh_index>.

=head2 resolve_plan

Adds to the plan's packages the required ones (dies, before any install,
for one without a candidate), the optional ones that have a candidate, and
the first firmware package with a candidate (dies if none has).

A required package of the plan's C<headers> without a candidate dies with
its own message: the package sources do not (or no longer) carry the
running kernel's headers -- usually they have moved on to a newer kernel
the host was not upgraded to or rebooted into (Ubuntu after a kernel update
without a reboot, Debian after an ABI bump, a RHEL-family mirror past the
running build): upgrade the kernel, reboot into it, run again. With a
repository in the plan (C<dkms>) every one of these messages says that no
driver package was installed and that the repository file and its signing
key are in place (a re-run accepts them); else C<Nothing was installed>.
L<Rex::GPU/gpu_setup> adds C<for the AMD GPU> to either.
L</has_candidate> may die by itself before that
(L<Rex::GPU::AMD::Setup::RHEL/has_candidate>: dnf could not run).

=head2 post_install

C<inbox>: C<modinfo -n amdgpu> must now find a module for the running
kernel. C<dkms>: C<dkms status> must show C<amdgpu> installed for the
running kernel B<and> C<modinfo -n amdgpu> resolve the DKMS module -- an
RPM whose C<%post> build failed is still installed for C<rpm -q>, so the
package check alone proves nothing. Dies otherwise. When no module is built
and L</hold_note> finds a hold in the way of the install (apt: C<apt-mark
hold>, RHEL: C<dnf versionlock>), the message names it and the way out
before the build log; asked only then, so a host where the module is there
runs no extra command.

=head2 dkms_built

True if C<dkms status -m amdgpu -k KERNEL> lists C<amdgpu> as installed
for the running kernel. Read-only.

=head2 secure_boot_enabled

True if the C<SecureBoot> EFI variable's value byte is C<1> (C<od> of
C</sys/firmware/efi/efivars/SecureBoot-8be4df61-...>); false on a BIOS
host or when it cannot be read. Read-only.

=head2 file_content

  my $text = $setup->file_content($path);   # '' if missing

C<cat PATH> over the exec channel. Read-only.

=head2 write_file

  $setup->write_file($path, $content);

Writes C<$content> (mode 0644) through C<printf> into C<PATH.tmp> and
C<mv -f> over C<PATH>, over the exec channel -- no SFTP. Dies if that
fails.

=head2 install_key

  $setup->install_key(url => $url, fingerprint => $fpr, path => $path);

Downloads an armored OpenPGP key (C<curl -fsSL --proto =https>) into a
temporary directory next to C<path>, reads it with C<gpg --show-keys> into
a throwaway C<GNUPGHOME> and requires exactly one primary key whose
fingerprint is C<fingerprint>; only then L</place_key> puts it at C<path>.
The temporary directory is removed in every case. Dies, leaving C<path> as
it was, when the download fails or the key is not the pinned one -- an
expired or rotated AMD key stops here, loudly.

=head2 place_key

  my $ok = $setup->place_key($tmpdir, $path);

Moves the checked C<$tmpdir/key.asc> into place: dearmored for apt in
L<Rex::GPU::AMD::Setup::Apt>, armored and C<rpm --import>ed in
L<Rex::GPU::AMD::Setup::RHEL>. Returns true on success.

=head2 supported_arch

The architecture amdgpu-dkms is built for, as L</arch> names it:
C<x86_64> (C<amd64> in L<Rex::GPU::AMD::Setup::Apt>).

=head2 refresh_index

Refreshes the package index, so that L</has_candidate> sees what the
package sources carry now; L</prepare_source> ends with it. Nothing here,
and so in L<Rex::GPU::AMD::Setup::RHEL> (dnf fetches the metadata it lacks
itself); L<Rex::GPU::AMD::Setup::Apt/refresh_index>: C<apt-get update -q>.

=head2 has_candidate

  $setup->has_candidate($package);

True if C<$package> has an installation candidate -- already installed, or
installable from the host's package sources. Here: always true, without a
host command; L<Rex::GPU::AMD::Setup::Apt/has_candidate> and
L<Rex::GPU::AMD::Setup::RHEL/has_candidate> ask the package manager.

=head2 package_installed

  $setup->package_installed($package);

True if C<$package> is installed. Here: always false, without a host
command; L<Rex::GPU::AMD::Setup::Apt/package_installed> (C<dpkg -l>) and
L<Rex::GPU::AMD::Setup::RHEL/package_installed> (C<rpm -q>) ask the
package database.

=head2 package_held

  $setup->package_held($package);

True if C<$package> is on hold, so that the package manager does not
change it (apt: C<apt-mark hold>, RHEL: C<dnf versionlock>). Here: always
false, without a host command; L<Rex::GPU::AMD::Setup::Apt/package_held>
reads dpkg's selection, L<Rex::GPU::AMD::Setup::RHEL/package_held> dnf's
lock list. Asked by L</blocking_holds> here; the packaging layers answer
that one themselves, with one command for all packages.

=head2 dkms_dependencies

Packages C<amdgpu-dkms> depends on without a version, whose hold
L</blocking_holds> asks next to the plan's packages: C<amdgpu-dkms-firmware>
(a dependency of C<amdgpu-dkms> 31.60 in AMD's Ubuntu 24.04 and RHEL 9
repositories). A hold on one of them is in the way only while it is not
installed: any installed version satisfies the dependency.

=head2 blocking_holds

  my @held = $setup->blocking_holds($plan);

The packages of the plan -- its C<packages>, then the
L</dkms_dependencies> it does not list -- that are on hold in a way that
stops the install, by name. Here: those L</package_held> says are held, one
question per package (none: no host command).
L<Rex::GPU::AMD::Setup::Apt/blocking_holds> and
L<Rex::GPU::AMD::Setup::RHEL/blocking_holds> leave out a hold the install
did not have to get past.

=head2 hold_note

  my $note = $setup->hold_note($plan);   # '' when no hold is in the way

For a C<dkms> plan with L</blocking_holds>: L</hold_advice> for them, the
words L</post_install> and the packaging layers' C<verify_packages> put
into their message. C<''> for any other plan (C<inbox>, ROCm, the helpers),
without a host command. Asked only on those failure paths, once the module
or a package is missing.

=head2 hold_advice

  my $text = $setup->hold_advice(@held);

The sentence that names the held packages, what the package manager does
with them and the way out, ending in C<... and install_driver again>
without a full stop. Here a generic one;
L<Rex::GPU::AMD::Setup::Apt/hold_advice> (C<apt-mark unhold>) and
L<Rex::GPU::AMD::Setup::RHEL/hold_advice> (C<dnf versionlock delete>) name
their package manager's.

=head2 install_helpers

Installs C<curl> and C<gpg> when they are missing -- L</install_key> needs
both; L</prepare_source> runs it before the signing key of a repository.
Nothing here; L<Rex::GPU::AMD::Setup::Apt/install_helpers> and
L<Rex::GPU::AMD::Setup::RHEL/install_helpers> install them.

=head2 install_packages

  $setup->install_packages($plan);

Installs the plan's C<packages> directly, never through
L<Rex::Commands::Pkg>; whether they went in is for L</verify_packages>,
which L</install> runs next. Dies here: the base class has no packaging
layer (L<Rex::GPU::AMD::Setup::Apt/install_packages>: C<apt-get install>,
L<Rex::GPU::AMD::Setup::RHEL/install_packages>: C<dnf install>).

=head2 verify_packages

  $setup->verify_packages($plan);

Dies unless every one of the plan's C<packages> is installed, as the
package database reports it -- not the installer's exit status. Dies here,
whatever the plan: the base class has no packaging layer
(L<Rex::GPU::AMD::Setup::Apt/verify_packages>: C<dpkg -l>,
L<Rex::GPU::AMD::Setup::RHEL/verify_packages>: C<rpm -q>).

=head2 amdgpu_release

The amdgpu driver release of the C<amdgpu-dkms> repository: C<31.60>.

=head2 amdgpu_key

  { url => 'https://repo.radeon.com/rocm/rocm.gpg.key',
    fingerprint => 'CA8BB4727A47B4D09B4EE8969386B48A1A693C5C', path => ... }

The signing key of C<repo.radeon.com> (primary key valid until 2028-08-21),
with C<path> from L</amdgpu_key_path>.

=head2 amdgpu_key_path

Where L</install_key> puts L</amdgpu_key> and the L</dkms_repo> file points
to it. Per OS class: C</etc/apt/keyrings/rocm.gpg> here, and so for
L<Rex::GPU::AMD::Setup::Ubuntu> and L<Rex::GPU::AMD::Setup::Debian>;
C</etc/pki/rpm-gpg/RPM-GPG-KEY-rocm> in L<Rex::GPU::AMD::Setup::RHEL>.

=head2 dkms_repo

  { file => ..., content => ..., key => amdgpu_key }

The C<amdgpu-dkms> repository for this OS. Per OS class.

=head2 host_unsupported

Why no AMD driver may be installed on this host at all, whatever the
method, or C<undef>: L</plan_inbox> and L</plan_dkms> ask it before any
other check, L<Rex::GPU::AMD/install_driver> before it names a way out for
GPUs whose hardware rows disagree; L</install_rocm> does not. Here:
C<undef>, without a host command; L<Rex::GPU::AMD::Setup::Debian> refuses
a Proxmox VE host. Host-read-only.

=head2 dkms_unsupported

Why C<amdgpu-dkms> is not supported on this OS release and kernel, or
C<undef> when it is. Here: always a reason.

=head2 inbox_unsupported

Why the inbox driver is not supported on this OS release and kernel, or
C<undef> when it is -- for every GPU, asked by L</plan_inbox> after
L</inbox_only_unsupported>, and so by L<Rex::GPU::AMD/install_driver>
before it names C<method =E<gt> 'inbox'> as the way out for GPUs whose
hardware rows disagree. Host-read-only. Here: C<undef>, nothing checked;
L<Rex::GPU::AMD::Setup::Debian> binds it to Debian 12 and 13 with Debian's
own C<amd64> kernel.

=head2 inbox_only_unsupported

Why a GPU AMD supports only with the inbox driver (the Ryzen APUs) is not
supported on this OS release and kernel, or C<undef>. Asked by
L</plan_inbox>, by L<Rex::GPU::AMD/install_driver> for GPUs whose
hardware rows disagree and by L</check_rocm_matrix> for their gfx targets;
host-read-only. Here: always a reason -- AMD supports them only on Ubuntu
(L</inbox_only_supported>).

=head2 inbox_only_supported

Where AMD supports the inbox-only GPUs, for messages: Ubuntu 26.04 with the
GA kernel 7.0 and Ubuntu 24.04 with the HWE kernel 7.0 (ROCm 10.1
compatibility matrix).

=head2 radeon_unsupported

Why a GPU of the Radeon table of AMD's ROCm compatibility matrix
(C<matrix =E<gt> 'radeon'>) is not supported on this OS release and
kernel, or C<undef> when it is -- for C<inbox> and C<amdgpu-dkms> alike.
Asked by L</check_radeon> and, for their gfx targets, by
L</check_rocm_matrix>; host-read-only. Here: always a reason -- AMD
lists the Radeon GPUs only on Ubuntu and RHEL (L</radeon_supported>);
L<Rex::GPU::AMD::Setup::Debian> inherits it (no Radeon on Debian),
L<Rex::GPU::AMD::Setup::Ubuntu> and L<Rex::GPU::AMD::Setup::RHEL> bind it
to the releases and kernels the matrix lists for them.

=head2 radeon_supported

Where AMD supports the Radeon GPUs, for messages: Ubuntu 26.04 (GA kernel
7.0), Ubuntu 24.04 (HWE kernel 7.0), Ubuntu 22.04 (HWE kernel 6.8), RHEL
10.2 (kernel 6.12.0-211) and RHEL 9.8 (kernel 5.14.0-687), per the ROCm
10.1 compatibility matrix.

=head2 kernel_header_packages

The running kernel's header packages, which C<amdgpu-dkms> is built
against: L</plan_dkms> requires them. None here; C<linux-headers-KERNEL>
in L<Rex::GPU::AMD::Setup::Ubuntu> and L<Rex::GPU::AMD::Setup::Debian>,
C<kernel-headers-KERNEL>, C<kernel-devel-KERNEL> and (9, 10)
C<kernel-devel-matched-KERNEL> in L<Rex::GPU::AMD::Setup::RHEL>.

=head2 optional_packages

Packages installed with C<amdgpu-dkms> only if they have a candidate:
L</plan_dkms> lists them, L</resolve_plan> keeps those that have one. None
here, and so in L<Rex::GPU::AMD::Setup::Debian> and
L<Rex::GPU::AMD::Setup::RHEL>; C<linux-modules-extra-KERNEL> on Ubuntu
24.04 and 22.04.

=head2 firmware_packages

The amdgpu firmware packages for the inbox driver, alternatives: none is
needed if one of them is installed (L</plan_inbox>), else the first with a
candidate is installed (L</resolve_plan>; it dies if none has one). None
here, so no firmware package is checked or installed;
L<Rex::GPU::AMD::Setup::Ubuntu>, L<Rex::GPU::AMD::Setup::Debian> and
L<Rex::GPU::AMD::Setup::RHEL> name theirs in their DESCRIPTION.

=head2 inbox_module_packages

The packages that bring C<amdgpu.ko> to a running kernel without it:
L</plan_inbox> requires them then (and dies if there are none),
L</fallback_method> picks C<inbox> when one of them has a candidate. None
here, and so in L<Rex::GPU::AMD::Setup::Debian> and
L<Rex::GPU::AMD::Setup::RHEL>; in L<Rex::GPU::AMD::Setup::Ubuntu> its
L</optional_packages> (C<linux-modules-extra-KERNEL> on 24.04 and 22.04).

=head2 rocm_repo_dir

The directory of AMD's ROCm repository for this OS release
(C<ubuntu2404>, C<debian13>, ...), for L<Rex::GPU::AMD/install_rocm>:
L<Rex::GPU::AMD::Setup::Apt/install_rocm> builds the repository's C<URIs>
from it and dies without one. C<undef> where there is none: here, and so
in L<Rex::GPU::AMD::Setup::RHEL>; L<Rex::GPU::AMD::Setup::Ubuntu> and
L<Rex::GPU::AMD::Setup::Debian> take it from their C<release_data>.

=head2 install_rocm

  my $how = $setup->install_rocm($rocm, \@targets);   # 'present' or 'installed'

L<Rex::GPU::AMD/install_rocm>'s host part; dies here (apt only, see
L<Rex::GPU::AMD::Setup::Apt/install_rocm>).

=head1 SEE ALSO

L<Rex::GPU::AMD>, L<Rex::GPU::AMD::Setup::Apt>, L<Rex::GPU::AMD::Setup::RHEL>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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
