# ABSTRACT: NVIDIA GPU driver and container toolkit management

package Rex::GPU::NVIDIA;
our $VERSION = '0.002';
use v5.14.4;
use warnings;

use Rex::Commands::File;
use Rex::Commands::Gather;
use Rex::Commands::Pkg;
use Rex::Commands::Run;
use Rex::Config ();
use Rex::Logger;

use Carp qw( croak );
use Module::Runtime qw( is_module_name module_notional_filename use_module );
use Scalar::Util qw( blessed );

use Rex::GPU::NVIDIA::Setup;
use Rex::GPU::NVIDIA::Setup::Apt;
use Rex::GPU::NVIDIA::Setup::Debian;
use Rex::GPU::NVIDIA::Setup::RHEL;
use Rex::GPU::NVIDIA::Setup::SUSE;
use Rex::GPU::NVIDIA::Setup::Ubuntu;

require Rex::Exporter;
use base qw(Rex::Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(
  install_driver
  install_container_toolkit
  configure_containerd
  verify_nvidia
  generate_cdi_specs
);


sub install_driver {
  my (%opts) = @_;

  die "install_driver: pass gpu or gpus, not both\n"
    if defined $opts{gpu} && defined $opts{gpus};
  my $gpus = $opts{gpus} // [ defined $opts{gpu} ? $opts{gpu} : () ];
  die "install_driver: gpus must be an arrayref of GPU hashrefs\n"
    unless ref $gpus eq 'ARRAY';
  die "install_driver: nvswitches must be an arrayref\n"
    if defined $opts{nvswitches} && ref $opts{nvswitches} ne 'ARRAY';
  my @nvswitches = defined $opts{nvswitches} ? ( nvswitches => $opts{nvswitches} ) : ();

  # Every supported OS runs through a Setup class (epic karr #25, T2/T3): the
  # already-installed short-circuit, the Kepler rejection, the multi-GPU
  # requirement, package selection, install, verification and the nouveau
  # blacklist are its steps. Which class: setup =>, set gpu_nvidia_setup, or
  # the OS (karr #34) -- resolved before anything touches the host.
  my @extra = defined $opts{requirement} ? ( extra_requirement => $opts{requirement} ) : ();
  my $setup = Rex::GPU::NVIDIA->setup_for(gpus => $gpus, setup => $opts{setup}, @extra, @nvswitches);
  unless ($setup) {
    # No class for this OS. Same order as before the move: a working driver
    # still short-circuits and a Kepler or a GPU conflict still gets its own
    # message (both via the base class, read-only), then the OS is refused.
    my $probe = Rex::GPU::NVIDIA::Setup->new(gpus => $gpus, @extra);
    return if $probe->already_installed;
    $probe->plan;
    die "Unsupported OS for NVIDIA driver installation: ".$probe->os."\n";
  }
  unless ($setup->install) {
    # Already installed (karr #50): Fabric Manager only if the host's own
    # package sources offer it at the loaded driver's exact version -- no
    # source is added, the driver is not touched; otherwise it only warns.
    # The driver runs, so a Fabric Manager installed now can start now.
    if ($setup->fabric_manager_needed) {
      my $fm = $setup->retrofit_fabric_manager;
      # HGX B200/B300 (karr #56): nvlsm & co. from the host's own sources
      my $fabric = $setup->nvlink_fabric_needed ? $setup->retrofit_nvlink_fabric : 0;
      run "systemctl start ".$setup->fabric_manager_service, auto_die => 0
        if $fm || $fabric;
      my $active = _check_fabric_manager($setup);
      $setup->check_nvlink_fabric($active) if $setup->nvlink_fabric_needed;
    }
    _note_nvlink_platforms($setup);
    return;
  }

  if ($opts{reboot}) {
    _reboot_and_wait();
  }
  else {
    run "modprobe nvidia", auto_die => 0;
    # Enabled by the setup, not started (karr #23): only now can the module
    # be loaded. Fails harmlessly while nouveau still holds the GPUs.
    run "systemctl start ".$setup->fabric_manager_service, auto_die => 0
      if $setup->fabric_manager_needed;
  }
  my $fm_active = $setup->fabric_manager_needed ? _check_fabric_manager($setup) : 0;

  # Driver only (karr #42): the toolkit comes after this step in gpu_setup,
  # so verify_nvidia's nvidia-ctk check could only warn here.
  verify_nvidia_driver();
  # HGX B200/B300 (karr #56): Fabric State of every GPU; warns, never dies
  $setup->check_nvlink_fabric($fm_active) if $setup->nvlink_fabric_needed;
  _note_nvlink_platforms($setup);

  Rex::Logger::info("NVIDIA driver installation complete");
}


# Ubuntu is recognised by its OS name exactly as the old $os eq 'Ubuntu'
# branch of install_driver did; every other is_debian host (Debian,
# derivatives) gets the Debian class. is_debian, is_redhat, is_suse are asked
# in the order the old install_driver branches asked them (epic karr #25;
# user selection is T5).
sub setup_class_for_os {
  my ( $class ) = @_;
  if (is_debian()) {
    return operating_system() eq 'Ubuntu'
      ? 'Rex::GPU::NVIDIA::Setup::Ubuntu'
      : 'Rex::GPU::NVIDIA::Setup::Debian';
  }
  return 'Rex::GPU::NVIDIA::Setup::RHEL' if is_redhat();
  return 'Rex::GPU::NVIDIA::Setup::SUSE' if is_suse();
  return 'Rex::GPU::NVIDIA::Setup::RHEL' if _rhel_family_name(operating_system());
  return;
}

# karr #39: with lsb_release installed, Rex 1.16 names the OS by
# `lsb_release -s -i`, and its is_redhat list misses the RHEL rebuilds'
# distributor IDs. Checked against the lsb_release scripts themselves
# (2026-09-24): redhat-lsb-core 4.1 (EL8, EL9 devel repos) prints Rocky,
# AlmaLinux, CentOSStream, RedHatEnterprise; EPEL 9's lsb_release 3.2 (reads
# /etc/os-release) prints RockyLinux, AlmaLinux, CentOS, RedHatEnterprise.
# Without lsb_release Rex reports Redhat (RHEL, Rocky, Alma) or CentOS, which
# is_redhat knows, as it knows RedHatEnterprise. Only the missing ones are
# listed, as exact names: an OS we cannot name is still refused, and nothing
# is read from the host to decide (the class is chosen before any probe).
sub _rhel_family_name {
  my ($os) = @_;
  return ($os // '') =~ /^(?:Rocky|RockyLinux|AlmaLinux|CentOSStream)$/ ? 1 : 0;
}


sub setup_for {
  my ( $class, %opt ) = @_;
  my $gpus  = $opt{gpus} // [];
  my @extra = defined $opt{extra_requirement}
    ? ( extra_requirement => $opt{extra_requirement} ) : ();
  push @extra, ( nvswitches => $opt{nvswitches} ) if defined $opt{nvswitches};
  my $chosen = $class->custom_setup($opt{setup});
  Rex::Logger::info('NVIDIA driver setup: '.( ref $chosen ? ref($chosen).' object' : $chosen ))
    if $chosen;
  return $chosen->adopt(gpus => $gpus, @extra) if blessed $chosen;
  my $setup_class = $chosen // $class->setup_class_for_os // return;
  return $setup_class->new(gpus => $gpus, @extra);
}

sub custom_setup {
  my ( $class, $setup ) = @_;
  my $origin = 'setup =>';
  unless ($class->_setup_given($setup)) {
    $setup  = Rex::Config->get('gpu_nvidia_setup');
    $origin = 'set gpu_nvidia_setup';
    return unless $class->_setup_given($setup);
  }
  my $base = 'Rex::GPU::NVIDIA::Setup';
  # The setting is shared by every host of the Rexfile; an object caches one
  # host's facts (os, kernel, GPUs), so only a class name is taken there.
  croak 'set gpu_nvidia_setup takes a class name, not '.$setup.': the setting '
    .'is shared by every host, and a setup object holds the facts of one. Pass '
    .'the object per call as setup => instead. Nothing was changed on the host'
    if ref $setup && $origin ne 'setup =>';
  if (ref $setup) {
    croak 'NVIDIA driver setup from '.$origin.' must be a class name or a '.$base
      .' object, not '.$setup.'. Nothing was changed on the host'
      unless blessed($setup) && $setup->isa($base);
    return $setup;
  }
  croak "NVIDIA driver setup from $origin: '$setup' is not a Perl package name. "
    .'Nothing was changed on the host'
    unless is_module_name($setup);
  $class->_load_setup_class($setup, $origin) unless $class->_package_defined($setup);
  croak 'NVIDIA driver setup from '.$origin.': '.$setup.' is not a subclass of '.$base
    .' (extends it, or one of the ::Setup::* classes). Nothing was changed on the host'
    unless $setup->isa($base);
  return $setup;
}

sub _setup_given {
  my ( $class, $setup ) = @_;
  return ref $setup || ( defined $setup && $setup ne '' ) ? 1 : 0;
}

# Is the package there already -- written into the Rexfile, or loaded? Then
# it is not looked up as a file (the Rexfile's own package has none).
sub _package_defined {
  my ( $class, $package ) = @_;
  return 1 if $INC{ module_notional_filename($package) };
  no strict 'refs';
  return 0 unless %{ $package.'::' };
  return 1 if @{ $package.'::ISA' };
  return ( grep { !/::\z/ && defined &{ $package.'::'.$_ } } keys %{ $package.'::' } ) ? 1 : 0;
}

sub _load_setup_class {
  my ( $class, $package, $origin ) = @_;
  return if eval { use_module($package); 1 };
  my $error = $@;
  my $file  = module_notional_filename($package);
  croak 'NVIDIA driver setup from '.$origin.': '.$package.' not found -- no '.$file
    .' in @INC. Put it at lib/'.$file.' next to your Rexfile (Rex adds that lib/ to '
    .'@INC) or define the package in the Rexfile. Nothing was changed on the host'
    if $error =~ /^Can't locate \Q$file\E in \@INC/;
  $error =~ s/\s+\z//;
  croak 'NVIDIA driver setup from '.$origin.': loading '.$package.' failed: '.$error
    .' -- Nothing was changed on the host';
}

# The helpers below moved into the Setup classes (karr #31, #32). The old
# private names stay as thin wrappers: t/ calls them.

sub _nvidia_driver_present {
  Rex::GPU::NVIDIA::Setup->_driver_present(@_);
}

sub _reject_unsupported_legacy_gpu {
  Rex::GPU::NVIDIA::Setup->_reject_unsupported_gpu(@_);
}

sub _apt_candidate_present {
  Rex::GPU::NVIDIA::Setup::Apt->_apt_candidate_present(@_);
}

sub _rpm_version_in_branch {
  Rex::GPU::NVIDIA::Setup::Rpm->_rpm_version_in_branch(@_);
}


sub install_container_toolkit {
  my $os = operating_system();

  my $family = is_debian() ? 'debian'
    : is_redhat() ? 'redhat'
    : is_suse() ? 'suse'
    : _rhel_family_name($os) ? 'redhat'
    : undef;
  die "Unsupported OS for NVIDIA Container Toolkit: $os\n" unless $family;

  return if _toolkit_present($family);

  Rex::Logger::info("Installing NVIDIA Container Toolkit");

  if ($family eq 'debian') {
    _install_toolkit_debian();
  }
  elsif ($family eq 'redhat') {
    _install_toolkit_redhat();
  }
  else {
    _install_toolkit_suse();
  }

  Rex::Logger::info("NVIDIA Container Toolkit installed");
}


# The runtime names configure_containerd knows; gpu_setup also takes 'none'
# (karr #66).
our @CONTAINERD_RUNTIMES = qw( rke2 k3s containerd );

sub _check_containerd_runtime {
  my ($runtime, @also) = @_;
  my @valid = (@CONTAINERD_RUNTIMES, @also);
  return if grep { $_ eq $runtime } @valid;
  die "Unknown containerd runtime: $runtime (valid: " . join(', ', @valid) . ")\n";
}

sub configure_containerd {
  my ($runtime) = @_;
  $runtime //= 'rke2';

  # The name first (karr #66): without the runtime binary a typo would
  # otherwise return quietly below.
  _check_containerd_runtime($runtime);

  return unless can_run("nvidia-container-runtime");

  Rex::Logger::info("Configuring containerd for NVIDIA GPU (runtime: $runtime)");

  if ($runtime eq 'rke2' || $runtime eq 'k3s') {
    _configure_containerd_rke2($runtime);
  }
  else {
    _configure_containerd_standalone();
  }

  Rex::Logger::info("Containerd configured with NVIDIA runtime");
}


sub verify_nvidia {
  Rex::Logger::info("Verifying NVIDIA installation...");
  my $ok = _verify_module_and_smi();

  if (can_run("nvidia-ctk")) {
    Rex::Logger::info("  [ok] nvidia-container-toolkit installed");
  }
  else {
    Rex::Logger::info("nvidia-container-toolkit not found", "warn");
    $ok = 0;
  }

  unless ($ok) {
    Rex::Logger::info("GPU verification incomplete — some features may not work until reboot", "warn");
  }

  return $ok;
}


sub verify_nvidia_driver {
  Rex::Logger::info("Verifying NVIDIA driver...");
  my $ok = _verify_module_and_smi();

  run(Rex::GPU::NVIDIA::Setup->libcuda_command, auto_die => 0);
  if ($? == 0) {
    Rex::Logger::info("  [ok] libcuda.so.1 in the linker cache");
  }
  else {
    Rex::Logger::info("libcuda.so.1 not in the linker cache (ldconfig -p) — CUDA programs "
      ."cannot run, and the next install_driver installs again", "warn");
    $ok = 0;
  }

  unless ($ok) {
    Rex::Logger::info("NVIDIA driver verification incomplete — some features may not work until reboot", "warn");
  }

  return $ok;
}

# The kernel module and nvidia-smi checks both verify_* share; warns per
# failure, returns 1/0.
sub _verify_module_and_smi {
  my $ok = 1;

  my $lsmod = run "lsmod | grep '^nvidia '", auto_die => 0;
  if ($? != 0 || !$lsmod) {
    Rex::Logger::info("nvidia kernel module not loaded (reboot may be needed)", "warn");
    $ok = 0;
  }
  else {
    Rex::Logger::info("  [ok] nvidia kernel module loaded");
  }

  my $smi = run "nvidia-smi -L 2>&1", auto_die => 0;
  chomp $smi if defined $smi;
  if (defined $smi && $smi =~ /GPU \d+:/) {
    Rex::Logger::info("  [ok] $smi");
  }
  else {
    Rex::Logger::info("nvidia-smi not working: " . ($smi // 'no output'), "warn");
    $ok = 0;
  }

  return $ok;
}

# NVSwitch host (karr #23) or HGX B200/B300 (karr #56): is Fabric Manager
# running? Warns, never dies, like verify_nvidia. Returns 1/0.
sub _check_fabric_manager {
  my ($setup) = @_;
  my $unit  = $setup->fabric_manager_service;
  my $label = $setup->fabric_label;
  run "systemctl is-active --quiet $unit", auto_die => 0;
  if ($? == 0) {
    Rex::Logger::info("  [ok] $unit active ($label)");
    return 1;
  }
  Rex::Logger::info("$label present but $unit is not active: CUDA fails with "
    ."cudaErrorSystemNotReady until NVIDIA Fabric Manager of the driver's exact version runs. "
    ."After the reboot that loads the NVIDIA driver: systemctl start $unit; if it is not "
    ."installed (install_driver installs it with the driver, or for an existing driver only "
    ."from the host's own package sources), install it yourself", "warn");
  return 0;
}

# NVLink platforms Rex::GPU does not set up (karr #49), by GPU device ID
# (Setup nvlink_platforms): a note only, nothing installed, verify unaffected,
# no host command. HGX B200/B300 are set up since karr #56 (Setup
# install_nvlink_fabric / check_nvlink_fabric), so only NVL72 is left here.
sub _note_nvlink_platforms {
  my ($setup) = @_;
  for my $platform ($setup->nvlink_platforms) {
    if ($platform eq 'nvl72') {
      Rex::Logger::info("GB200/GB300 NVL72 compute tray: multi-node NVLink needs nvidia-imex "
        ."and its configuration -- not part of Rex::GPU");
    }
  }
  return;
}

# ============================================================
#  Debian / Ubuntu — Rex::GPU::NVIDIA::Setup::Debian / ::Ubuntu
# ============================================================

# Thin wrappers over the pure helpers that moved into the Setup classes
# (karr #31); t/ calls them by these names.

sub _sources_list_enable_nonfree {
  Rex::GPU::NVIDIA::Setup::Debian->_sources_list_enable_nonfree(@_);
}

sub _deb822_enable_nonfree {
  Rex::GPU::NVIDIA::Setup::Debian->_deb822_enable_nonfree(@_);
}

# ============================================================
#  RHEL / openSUSE — Rex::GPU::NVIDIA::Setup::RHEL / ::SUSE
# ============================================================

# Thin wrappers over the pure helpers that moved into the Setup classes
# (karr #32); t/ calls them by these names.

# `uname -m` -> NVIDIA's CUDA repo arch token ("sbsa" for aarch64/arm64,
# else "x86_64"). NOT the libnvidia-container toolkit repo's token, which is
# "aarch64" for the same machine: do not reuse it for the toolkit path.
sub _cuda_repo_arch {
  Rex::GPU::NVIDIA::Setup->_cuda_repo_arch(@_);
}

sub _os_major_version {
  # Rex::Commands::Gather::operating_system_version() strips dots, so "10.1"
  # becomes "101": the raw operating_system_release() string is read instead.
  # An explicit $release may be passed so callers stay pure and unit-testable.
  my ($release) = @_;
  $release //= Rex::Commands::Gather::operating_system_release();
  return Rex::GPU::NVIDIA::Setup->_major_version($release);
}

# ============================================================
#  Container toolkit installation
# ============================================================

# karr #42: a toolkit that is already there -- a re-run, or an image that
# ships it (DGX OS installs it from NVIDIA's apt repository) -- is left as it
# is. Both signals are required: nvidia-ctk runs, AND the package manager has
# the package. nvidia-ctk alone is not enough: configure_containerd points
# containerd at /usr/bin/nvidia-container-runtime, which only the package
# guarantees, and a copy unpacked outside the package manager (the GPU
# Operator's /usr/local/nvidia/toolkit) must still get the package. dpkg
# 'hi' (held, installed) counts as installed.
sub _toolkit_present {
  my ($family) = @_;
  return 0 unless can_run("nvidia-ctk");
  my $version = run "nvidia-ctk --version 2>&1", auto_die => 0;
  return 0 if $? != 0;
  ($version) = split /\n/, ($version // '');
  $version //= 'nvidia-ctk';
  run(($family eq 'debian'
      ? "dpkg -l nvidia-container-toolkit 2>/dev/null | grep -q '^[hi]i'"
      : "rpm -q nvidia-container-toolkit 2>&1"),
    auto_die => 0);
  if ($? != 0) {
    Rex::Logger::info("nvidia-ctk runs ($version) but the nvidia-container-toolkit package is not installed — installing it");
    return 0;
  }
  Rex::Logger::info("NVIDIA Container Toolkit already present — skipping repository setup and install ($version)");
  return 1;
}

sub _install_toolkit_debian {
  my $keyring = '/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg';

  # The driver path's apt layer (karr #37): the apt timers stopped before the
  # first apt-get, DPkg::Lock::Timeout on every one, install run directly and
  # dpkg -l ^ii as the only evidence. After the first-deploy reboot
  # apt-daily/cloud-init hold the dpkg lock; Rex::Pkg (pkg) has no lock
  # timeout and stopping the timers does not release a lock cloud-init holds,
  # so curl/gnupg go through apt-get too. --no-upgrade keeps pkg's
  # ensure => present meaning: an installed curl or gnupg is not upgraded.
  my $apt = Rex::GPU::NVIDIA::Setup::Apt->new;
  $apt->prepare_host({ packages => [ 'curl', 'gnupg', 'nvidia-container-toolkit' ] });
  $apt->run_cmd('DEBIAN_FRONTEND=noninteractive '.$apt->apt_get.' install -y --no-upgrade curl gnupg',
    auto_die => 0);
  $apt->verify_packages({ verify => [ 'curl', 'gnupg' ] });

  _install_toolkit_keyring($keyring);

  file "/etc/apt/sources.list.d/nvidia-container-toolkit.list",
    content => 'deb [signed-by='.$keyring.'] https://nvidia.github.io/libnvidia-container/stable/deb/$(ARCH) /' . "\n";

  $apt->prepare_source({});
  $apt->install_packages({ packages => [ 'nvidia-container-toolkit' ] });
  $apt->verify_packages({ verify => [ 'nvidia-container-toolkit' ] });
}

# karr #38: gpg --dearmor -o on an existing file without --yes fails with no
# TTY, so a re-run kept the old key forever and the error was swallowed. The
# key is dearmored to a temporary file that replaces the keyring only when it
# is non-empty (gpg can leave an empty file on bad input), readable by apt's
# _apt sandbox user; any failure dies instead of carrying on to an apt-get
# update that cannot verify the repository.
sub _install_toolkit_keyring {
  my ($keyring) = @_;
  my $asc = "$keyring.asc.tmp";
  my $tmp = "$keyring.tmp";

  run "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey -o $asc", auto_die => 0;
  if ($? != 0) {
    run "rm -f $asc", auto_die => 0;
    die "Could not download the NVIDIA Container Toolkit GPG key (https://nvidia.github.io/libnvidia-container/gpgkey)\n";
  }
  run "gpg --batch --yes --dearmor -o $tmp $asc && test -s $tmp && chmod 0644 $tmp && mv -f $tmp $keyring",
    auto_die => 0;
  my $failed = $? != 0;
  run "rm -f $asc $tmp", auto_die => 0;
  die "Could not dearmor the NVIDIA Container Toolkit GPG key into $keyring\n" if $failed;

  run "test -s $keyring", auto_die => 0;
  die "NVIDIA Container Toolkit keyring $keyring is missing or empty\n" if $? != 0;
}

# karr #44, the k38 pattern for the dnf .repo: `curl -s -L | tee` wrote an
# HTTP error page into /etc/yum.repos.d and dnf failed later with a parse
# error. curl -f fails on an HTTP error; the download lands in a .repo.tmp
# next to the target (dnf reads only *.repo) and replaces it only when it has
# the [nvidia-container-toolkit] section. Every failure dies, leaving an
# existing .repo as it was.
sub _install_toolkit_repo_file {
  my ($repo) = @_;
  my $url = 'https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo';
  my $tmp = "$repo.tmp";

  run "curl -fsSL $url -o $tmp", auto_die => 0;
  if ($? != 0) {
    run "rm -f $tmp", auto_die => 0;
    die "Could not download the NVIDIA Container Toolkit repository file ($url)\n";
  }
  run "grep -q '^\\[nvidia-container-toolkit\\]' $tmp && chmod 0644 $tmp && mv -f $tmp $repo",
    auto_die => 0;
  my $failed = $? != 0;
  run "rm -f $tmp", auto_die => 0;
  die "The NVIDIA Container Toolkit repository file from $url has no [nvidia-container-toolkit] section or could not be moved into place; $repo was not changed\n"
    if $failed;
}

sub _install_toolkit_redhat {
  _install_toolkit_repo_file('/etc/yum.repos.d/nvidia-container-toolkit.repo');
  run "dnf clean expire-cache", auto_die => 0;
  run "dnf install -y nvidia-container-toolkit", auto_die => 0;
  my $check = run "rpm -q nvidia-container-toolkit 2>&1", auto_die => 0;
  die "nvidia-container-toolkit not installed\n" if $? != 0;
}

sub _install_toolkit_suse {
  # The .repo file URL is yum/dnf format — zypper needs the baseurl directly.
  # Remove any stale entry (possibly added with the wrong URL) before re-adding.
  my $arch = run "uname -m", auto_die => 0;
  chomp $arch;
  $arch ||= 'x86_64';

  run "rpm --import https://nvidia.github.io/libnvidia-container/gpgkey 2>/dev/null",
    auto_die => 0;
  # karr #52: rr + addrepo + refresh, dying on a failed addrepo or refresh.
  Rex::GPU::NVIDIA::Setup::SUSE->add_repo('nvidia-container-toolkit',
    "https://nvidia.github.io/libnvidia-container/stable/rpm/$arch");

  # zypper's exit code is not the evidence (karr #27): rpm -q is, as on RHEL.
  # karr #53: waits for the zypp lock, as add_repo does.
  my $zypper = Rex::GPU::NVIDIA::Setup::SUSE->zypper;
  run "$zypper install -y nvidia-container-toolkit", auto_die => 0;
  my $check = run "rpm -q nvidia-container-toolkit 2>&1", auto_die => 0;
  die "nvidia-container-toolkit not installed\n" if $? != 0;
}

# ============================================================
#  Containerd configuration
# ============================================================

sub _rke2_base_dir {
  my ($runtime) = @_;
  $runtime //= 'rke2';
  my $dist = ($runtime eq 'k3s') ? 'k3s' : 'rke2';
  return "/var/lib/rancher/$dist/agent/etc/containerd";
}

# Decide, from the effective containerd state, HOW to register the nvidia
# runtime. Pure (regex + booleans only, no I/O) so it is unit-testable offline.
#
#   config      => contents of the RKE2/K3s-generated config.toml (or undef)
#   has_v3_tmpl => a config-v3.toml.tmpl base template is present
#   has_v3_dir  => a config-v3.toml.d/ drop-in directory is present
#
# Returns one of:
#   'present' — the distro already wired an nvidia runtime (leave it alone)
#   'v3'      — modern containerd 2.x / config v3: use an additive drop-in
#   'v2'      — legacy containerd 1.x / config v2: extend the base template
#
# Ordering is load-bearing: a distro that auto-detected nvidia-container-runtime
# on PATH wires the runtime itself, so 'present' must win before any write path.
sub _containerd_nvidia_action {
  my (%s) = @_;
  my $config = $s{config} // '';

  # Already wired (RKE2/K3s auto-detect, or a prior additive drop-in) — no-op.
  return 'present' if $config =~ /runtimes\.'?nvidia'?[.\]]/;

  # Modern config v3: additive drop-in in config-v3.toml.d/.
  return 'v3' if $s{has_v3_tmpl} || $s{has_v3_dir};
  return 'v3' if $config =~ /^\s*version\s*=\s*3\b/m;
  return 'v3' if $config =~ /config-v3\.toml\.d/;

  # Legacy config v2 (containerd 1.x): base-extending config.toml.tmpl.
  return 'v2'
    if $config =~ /^\s*version\s*=\s*2\b/m
    || $config =~ /io\.containerd\.grpc\.v1\.cri/;

  # No generated config yet and no version markers: default to the modern
  # v3 drop-in (the current RKE2/K3s norm). Caller warns; see POD.
  return 'v3';
}

# Modern (containerd 2.x / config v3) additive drop-in. RKE2/K3s import
# config-v3.toml.d/*.toml into their generated config.toml, so this ADDS the
# nvidia runtime without touching the base — SystemdCgroup, the pinned sandbox
# image, snapshotter opts and the certs.d config_path all survive. Uses the
# v3 CRI plugin path (io.containerd.cri.v1.runtime), matching what the distro
# auto-wires. SystemdCgroup=true keeps the cgroup driver aligned with kubelet.
sub _nvidia_containerd_dropin_v3 {
  return <<'TOML';
version = 3

[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.'nvidia']
  runtime_type = "io.containerd.runc.v2"

[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.'nvidia'.options]
  BinaryName = "/usr/bin/nvidia-container-runtime"
  SystemdCgroup = true
TOML
}

# Legacy (containerd 1.x / config v2) base-extending template. RKE2/K3s render
# config.toml.tmpl if present; {{ template "base" . }} emits the full default
# config first, then we ADD the nvidia runtime under the v2 CRI plugin path.
# NEVER a bare full-config tmpl (that replaced the base and was karr #9).
sub _nvidia_containerd_tmpl_v2 {
  return <<'TOML';
{{ template "base" . }}

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia"]
  runtime_type = "io.containerd.runc.v2"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia".options]
  BinaryName = "/usr/bin/nvidia-container-runtime"
  SystemdCgroup = true
TOML
}

sub _path_exists {
  my ($flag, $path) = @_;
  run "test $flag $path", auto_die => 0;
  return $? == 0 ? 1 : 0;
}

# Write the modern (config v3) additive nvidia drop-in under $base. Shared by
# the normal 'v3' action and the karr #13 clobber-heal path so both emit the
# exact same additive wiring. RKE2/K3s import config-v3.toml.d/*.toml into the
# config.toml they generate, so this ADDS the nvidia runtime without touching
# the base.
sub _write_nvidia_v3_dropin {
  my ($base) = @_;
  file "$base/config-v3.toml.d", ensure => 'directory';
  file "$base/config-v3.toml.d/99-nvidia.toml",
    content => _nvidia_containerd_dropin_v3();
  Rex::Logger::info(
    "  wrote additive nvidia drop-in: $base/config-v3.toml.d/99-nvidia.toml");
}

# Pure predicate (karr #13): does this config.toml.tmpl content match the EXACT
# full-config clobber that rex-gpu 0.002 wrote (pre-karr #9)? That code wrote a
# bare template — literally:
#
#     imports = ["/etc/containerd/conf.d/*.toml"]
#     version = 2
#
# which REPLACED the RKE2/K3s base config (no `{{ template "base" . }}`, hence
# no SystemdCgroup / pinned sandbox image / certs.d config_path in the rendered
# config.toml). Matching this — and ONLY this — is what lets the heal remove it
# so the distro regenerates its native config.
#
# Removing a file on a live remote root shell is the top risk here, so the match
# is deliberately narrow. Returns 1 ONLY when, ignoring blank lines and #
# comments, the content is exactly an `imports =` line PLUS a `version = 2` line
# and nothing else. Any `{{ template "base" ... }}` directive (the karr #9
# base-extending tmpl, or any base-rendering template) => 0. Any other
# substantive line — a [plugins...] section, a real base key, any further
# content — means this carries actual config (a user's own tmpl, or something
# that is not the bare clobber) => 0. When in doubt, 0.
#
# Pure (regex/string only, no run/file) so it is unit-testable offline, like
# _containerd_nvidia_action / _nvidia_driver_present / _cdi_managed_source_present.
sub _is_rke2_clobber_tmpl {
  my ($content) = @_;
  return 0 unless defined $content && length $content;

  # The base-extending tmpl (#9) and any base-rendering template carry the
  # `{{ template "base" . }}` directive — the signature of the SAFE tmpl.
  return 0 if $content =~ /\{\{\s*template\s+["']base["']/;

  my @lines = grep { /\S/ && !/^\s*#/ } split /\n/, $content;
  return 0 unless @lines;

  my ($imports, $version2) = (0, 0);
  for my $l (@lines) {
    if    ($l =~ /^\s*imports\s*=/)         { $imports  = 1 }
    elsif ($l =~ /^\s*version\s*=\s*2\s*$/) { $version2 = 1 }
    else                                    { return 0 }
  }
  return ($imports && $version2) ? 1 : 0;
}

sub _configure_containerd_rke2 {
  my ($runtime) = @_;
  $runtime //= 'rke2';

  my $base        = _rke2_base_dir($runtime);
  my $config_file = "$base/config.toml";
  my $tmpl_file   = "$base/config.toml.tmpl";

  # Heal an EARLIER clobber (karr #13). rex-gpu 0.002 (pre-karr #9) wrote a bare
  # full-config config.toml.tmpl that REPLACED the RKE2/K3s base config. Detect
  # and remove THAT exact artifact BEFORE trusting the generated config.toml
  # below: the generated config IS the clobber's output — it already carries an
  # nvidia runtime, so the 'already-wired' (present) check would no-op and leave
  # the clobber (missing SystemdCgroup / pinned sandbox / certs.d) in place
  # forever. Removing the tmpl is what lets the distro regenerate its native
  # config on the next restart. _is_rke2_clobber_tmpl matches ONLY the bare
  # clobber, never the #9 base-extending tmpl or a user's own custom tmpl.
  my $tmpl = run "cat $tmpl_file 2>/dev/null", auto_die => 0;
  if (_is_rke2_clobber_tmpl($tmpl)) {
    Rex::Logger::info(
      "  removing legacy rex-gpu full-config clobber $tmpl_file so $runtime "
      . "regenerates its native containerd config (karr #13)", "warn");
    run "rm -f $tmpl_file", auto_die => 0;

    # The live config.toml is STILL the clobber's output until $runtime restarts
    # and regenerates it. We deliberately do NOT restart rke2/k3s here: that
    # bounces the node's containerd and its workloads as a side effect of GPU
    # setup, and the node is no worse than before (it was already clobbered).
    # The heal completes on the next $runtime restart / node reboot — warn so
    # the operator triggers it. (config.toml is NOT self-healing.)
    Rex::Logger::info(
      "  restart $runtime (or reboot the node) to regenerate the native "
      . "containerd config — config.toml stays clobbered until then", "warn");

    # Wire nvidia additively into the config $runtime will regenerate. The
    # real-world clobber target is modern RKE2/K3s (containerd 2.x / config v3),
    # whose native config imports config-v3.toml.d/*.toml; a base-extending
    # config.toml.tmpl would just recreate the file we just removed.
    _write_nvidia_v3_dropin($base);
    return;
  }

  # RKE2/K3s regenerate config.toml on every startup; it reflects the effective
  # merged runtime config, including any nvidia runtime the distro auto-wired
  # after finding nvidia-container-runtime on PATH.
  my $config = run "cat $config_file 2>/dev/null", auto_die => 0;

  my $action = _containerd_nvidia_action(
    config      => $config,
    has_v3_tmpl => _path_exists("-f", "$base/config-v3.toml.tmpl"),
    has_v3_dir  => _path_exists("-d", "$base/config-v3.toml.d"),
  );

  if ($action eq 'present') {
    Rex::Logger::info(
      "  $runtime already wired the nvidia runtime natively — leaving containerd config untouched");
    return;
  }

  if ($action eq 'v3') {
    Rex::Logger::info(
      "  no generated $config_file yet and no config version markers — "
      . "assuming modern (config v3) $runtime", "warn")
      unless defined $config && length $config;

    _write_nvidia_v3_dropin($base);
  }
  else {
    file $base, ensure => 'directory';
    file "$base/config.toml.tmpl", content => _nvidia_containerd_tmpl_v2();
    Rex::Logger::info(
      "  wrote base-extending config.toml.tmpl (legacy v2): $base/config.toml.tmpl");
  }
}

sub _configure_containerd_standalone {
  run "nvidia-ctk runtime configure --runtime=containerd 2>&1", auto_die => 0;
  run "systemctl restart containerd 2>/dev/null", auto_die => 0;
}

# ============================================================
#  CDI spec generation
# ============================================================


sub generate_cdi_specs {
  Rex::Logger::info("Generating NVIDIA CDI specs...");

  # Hand off to a managed CDI source if one owns the runtime scan dir. Modern
  # nvidia-container-toolkit ships nvidia-cdi-refresh.path/.service, which keep
  # /run/cdi/nvidia.yaml fresh across driver updates. /etc/cdi and /run/cdi are
  # BOTH default CDI scan dirs, so writing a static /etc/cdi/nvidia.yaml
  # alongside the managed /run/cdi copy defines the same device kind
  # (nvidia.com/gpu) twice — a duplicate-device load error in CDI consumers —
  # and the static copy drifts against the refreshed one over driver updates.
  # See _cdi_managed_source_present for the signal choice (karr #11).
  my $enabled = run "systemctl is-enabled nvidia-cdi-refresh.path 2>/dev/null", auto_die => 0;
  chomp $enabled if defined $enabled;
  my $active = run "systemctl is-active nvidia-cdi-refresh.path 2>/dev/null", auto_die => 0;
  chomp $active if defined $active;

  if (_cdi_managed_source_present(
      enabled_state => $enabled,
      active_state  => $active,
      run_cdi       => _path_exists("-f", "/run/cdi/nvidia.yaml"),
  )) {
    Rex::Logger::info(
      "  nvidia-cdi-refresh manages CDI in /run/cdi — not writing a static "
      . "/etc/cdi/nvidia.yaml (avoids a duplicate nvidia.com/gpu across scan dirs)");
    # Kick the managed generator once so /run/cdi is populated NOW: /run is
    # tmpfs and empty after the first-deploy reboot, and the .path watcher may
    # not have fired yet (no driver-file change since it was armed). Best-effort
    # — the unit re-runs itself on the next driver change; if the unit name
    # differs (detected via the /run/cdi file), this is a harmless no-op.
    run "systemctl start nvidia-cdi-refresh.service 2>/dev/null", auto_die => 0;
    return;
  }

  run "mkdir -p /etc/cdi", auto_die => 0;
  run "nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml 2>/dev/null", auto_die => 0;
  Rex::Logger::info("  [ok] CDI specs written to /etc/cdi/nvidia.yaml");
}

# Pure predicate for the generate_cdi_specs managed-source short-circuit: is a
# MANAGED CDI source already present that owns /run/cdi/nvidia.yaml? Modern
# nvidia-container-toolkit ships nvidia-cdi-refresh.path/.service, which
# regenerate a CDI spec into the /run/cdi runtime scan dir and keep it fresh
# across driver updates. When it is present, generate_cdi_specs must NOT also
# write a static /etc/cdi/nvidia.yaml (both are default scan dirs → duplicate
# nvidia.com/gpu + drift; karr #11).
#
# Signals (gathered impurely by generate_cdi_specs, matched here):
#   enabled_state => `systemctl is-enabled nvidia-cdi-refresh.path` output
#   active_state  => `systemctl is-active  nvidia-cdi-refresh.path` output
#   run_cdi       => a /run/cdi/nvidia.yaml already exists (boolean)
#
# The systemd unit state is the PRIMARY signal, not the file. /run is tmpfs and
# is wiped on every boot, so on a first deploy (right after the nouveau reboot)
# the managed source may not have fired yet and /run/cdi/nvidia.yaml is absent
# even though the refresh unit owns CDI from here on. The unit being installed
# (enabled/enabled-runtime/static/indirect/alias) or armed (active/activating)
# is durable across that reboot and answers the real question — "will this host
# keep /run/cdi fresh?" — which a bare file check cannot. run_cdi is a
# belt-and-suspenders confirmation: this code only ever writes /etc/cdi, so a
# /run/cdi/nvidia.yaml can only have come from some OTHER producer — unambiguous
# evidence of a second CDI source for the same kind (catches a producer under a
# different unit name, or a host with no systemctl). disabled/masked/not-found
# (opted out, or no such unit) do NOT count as managed.
#
# Pure (regex/string/boolean only, no run/systemctl/test) so it is unit-testable
# offline, like _nvidia_driver_present / _containerd_nvidia_action.
sub _cdi_managed_source_present {
  my (%s) = @_;
  my $enabled = $s{enabled_state} // '';
  my $active  = $s{active_state}  // '';
  return 1 if $enabled =~ /^(?:enabled|enabled-runtime|static|indirect|alias)\b/;
  return 1 if $active  =~ /^(?:active|activating)\b/;
  return 1 if $s{run_cdi};
  return 0;
}

# ============================================================
#  Reboot
# ============================================================

sub _reboot_and_wait {
  Rex::Logger::info("Rebooting host to activate NVIDIA driver (replacing nouveau)...");

  # Schedule reboot 2 s from now so the run() call can return cleanly
  run "nohup sh -c 'sleep 2 && shutdown -r now' >/dev/null 2>&1 &", auto_die => 0;

  # Wait long enough for the system to actually go down
  sleep 20;

  # Poll until SSH comes back (up to 5 minutes)
  my $conn = Rex::get_current_connection()->{conn};
  my $back = 0;
  for my $i (1..60) {
    eval { $conn->disconnect() };
    eval { $conn->reconnect() };
    unless ($@) {
      # Verify we can actually run a command: its output, not just that run
      # returned (karr #65); a PTY session answers "ok\r"
      my $test = eval { run "echo ok", auto_die => 0 };
      if (defined $test && $test =~ /^ok\r?$/m) {
        Rex::Logger::info("  Host is back online (after ~" . ($i * 5 + 20) . "s)");
        $back = 1;
        last;
      }
    }
    Rex::Logger::info("  Waiting for host to come back... ($i/60)");
    sleep 5;
  }

  die "Host did not come back after reboot\n" unless $back;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA - NVIDIA GPU driver and container toolkit management

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Rex::GPU::NVIDIA;

  # Step 1: Install driver (with reboot on first deploy)
  install_driver(reboot => 1);

  # Step 2: Install NVIDIA Container Toolkit
  install_container_toolkit();

  # Step 3: Generate CDI specs for the device plugin
  generate_cdi_specs();

  # Step 4: Configure containerd for Kubernetes
  configure_containerd('rke2');   # 'rke2', 'k3s', or 'containerd'

  # Verify the current installation status
  my $ok = verify_nvidia();

=head1 DESCRIPTION

L<Rex::GPU::NVIDIA> manages the full NVIDIA software stack needed to run
GPU-accelerated workloads in Kubernetes: driver installation, the Container
Toolkit, CDI spec generation, and containerd runtime configuration.

Each step is OS-aware and handles Debian/Ubuntu, RHEL/Rocky/CentOS, and
openSUSE Leap without further configuration.

=head2 Driver installation

Drivers are installed via DKMS, so they survive kernel upgrades without
needing reinstallation. The C<nouveau> open-source driver is blacklisted
and the initramfs is regenerated to prevent it from loading at boot.

On Debian, whichever of C<contrib>, C<non-free> and C<non-free-firmware>
is missing is added to each Debian archive entry, in both source formats:
active C<deb> lines of C</etc/apt/sources.list> (appended after the last
component; C<non-free-firmware> alone, as the Debian 12 installer writes it,
does not count as C<non-free>), and the C<Components:> field of stanzas in the
deb822 format (C</etc/apt/sources.list.d/*.sources>, e.g. C<debian.sources> on
Debian 13 and Debian cloud images). An entry is a Debian archive when it is
of type C<deb> (not C<deb-src>, not commented out or C<Enabled: no>), its
components include C<main>, and either C<Signed-By> / C<[signed-by=...]>
names only C<debian-archive-*> keyrings under C</usr/share/keyrings> (whatever
the URI, so a mirror of your own signed with Debian's key counts), or there
is no C<signed-by> and every URI is a C<*.debian.org> host, Hetzner's
C<mirror.hetzner.com/debian/> (or C<.de>) mirror or the cloud images'
C<mirror+file:/etc/apt/mirrors/debian*.list>. Third-party sources and unknown
mirrors are left untouched, and a file with nothing to add is not rewritten;
if no Debian archive entry is recognised in either format, a warning is
logged. To recognise a mirror of your own, override
L<Rex::GPU::NVIDIA::Setup::Debian/is_debian_archive_uri> in a subclass.

The install is done by L<Rex::GPU::NVIDIA::Setup::Debian>,
L<Rex::GPU::NVIDIA::Setup::Ubuntu>, L<Rex::GPU::NVIDIA::Setup::RHEL> and
L<Rex::GPU::NVIDIA::Setup::SUSE> (experimental classes, see
L<Rex::GPU::NVIDIA::Setup>); the steps and commands are the ones described
here. A subclass of your own replaces them through the C<setup> option of
L</install_driver> or C<set gpu_nvidia_setup> -- see
L<Rex::GPU::NVIDIA::Setup/WRITING YOUR OWN SETUP>.

The package choice also depends on the GPU generation, read from the PCI
device IDs of the GPUs passed as C<gpus> (or C<gpu>) to L</install_driver>
(L<Rex::GPU/gpu_setup> passes every compute GPU it detected); one driver has
to fit them all. Without that option every host gets the default selection
below.

=over

=item * B<Turing, Ampere, Ada, Hopper> and unknown IDs: the default per-distro
selection.

=item * B<Blackwell> (B200/GB200/B300, GeForce RTX 50xx, RTX PRO Blackwell,
GB10), on any CPU architecture: it has no proprietary kernel module. Ubuntu
selects the C<-server-open> variant. Debian 12/13 installs the open-module set
from NVIDIA's CUDA repository instead of C<non-free>.

=item * B<Maxwell, Pascal, Volta> (e.g. V100, P100, GeForce GT 1030, GTX
980): only the proprietary
module of the 580 branch supports them. Ubuntu pins
C<nvidia-driver-580-server>, RHEL pins branch 580 (module stream or
versionlock) with C<kmod-nvidia-latest-dkms>, and openSUSE uses
C<nvidia-driver-G06-kmp-meta>.

=item * B<Kepler or older>: no supported branch is installed and
L</install_driver> dies before changing the host. L<Rex::GPU/gpu_setup>
never passes one: detection skips it with a warning.

=item * B<NVIDIA vGPU guest> (C<vgpu =E<gt> 1>): it needs NVIDIA's licensed
vGPU guest driver, which is not installed here; unless a working driver is
already there, L</install_driver> dies before changing the host.

=back

See the C<gpus> option of L</install_driver> for the exact packages.

On Ubuntu, the newest available C<nvidia-driver-NNN-server> package is
auto-detected and installed by default. It is looked up after C<apt-get
update>; if the refreshed index lists none, C<install_driver> dies before
installing a driver package.

On RHEL/Rocky/AlmaLinux/CentOS Stream, the NVIDIA CUDA repository is added
and the open-kernel DKMS variant is used by default. For RHEL 10+ the module
streams approach is not available; C<kmod-nvidia-open-dkms> is installed
directly. The CUDA repository URL is architecture-aware: aarch64 hosts use the
C<sbsa> tree (C<repos/rhelN/sbsa/>), x86_64 hosts the C<x86_64> tree.

On openSUSE Leap, a kmp-meta package is used (by default
C<nvidia-open-driver-G06-signed-kmp-meta> for Leap 15.x,
C<nvidia-open-driver-G07-signed-kmp-meta> for Leap 16.x) to ensure the kernel
module and userspace libraries are always at the same version. Stale OSS
non-free packages are removed before installation and locked afterwards to
prevent C<nvidia-smi> from reporting a C<Driver/library version mismatch>.

=head2 Container Toolkit

C<nvidia-container-toolkit> is installed from the official NVIDIA GitHub
package repository (L<https://nvidia.github.io/libnvidia-container/>).

=head2 CDI specs

Container Device Interface specifications let the Kubernetes device plugin
enumerate GPU resources without requiring privileged container access. When a
managed CDI source — the C<nvidia-cdi-refresh> systemd unit shipped by modern
C<nvidia-container-toolkit> — already keeps C</run/cdi/nvidia.yaml> fresh, that
source is left to own CDI; otherwise a static spec is written to
C</etc/cdi/nvidia.yaml> by C<nvidia-ctk cdi generate>. Only one of the two
default scan dirs (C</etc/cdi>, C</run/cdi>) is populated, so C<nvidia.com/gpu>
is never defined twice.

=head2 Containerd configuration

For RKE2 and K3s, the NVIDIA runtime is registered additively and
version-aware, without clobbering the config that the distribution generates:
a no-op when RKE2/K3s already wired the runtime natively, a
C<config-v3.toml.d/> drop-in on modern (containerd 2.x / config v3) hosts, or
a base-extending (C<{{ template "base" . }}>) C<config.toml.tmpl> on legacy
(containerd 1.x / config v2) hosts. A stale full-config C<config.toml.tmpl>
left by the 0.001 release is detected by its exact bare-clobber signature and
removed so the distribution regenerates its native config (the operator must
restart the service or reboot for that to take effect). For standalone
containerd, C<nvidia-ctk runtime configure> is used.

Supported distributions:

=over

=item * Debian 11 (bullseye), 12 (bookworm), 13 (trixie)

=item * Ubuntu 22.04 (jammy), 24.04 (noble)

=item * RHEL / Rocky Linux / AlmaLinux 8, 9, 10 — CentOS Stream 9, 10

=back

The verified target set is the RKE2 Linux family above. B<openSUSE Leap / SLES
is unverified and unsupported> — SUSE is not a deploy target for the
GPU-on-Rancher pipeline. The L<Rex::GPU::NVIDIA::Setup::SUSE> path exists but
is not exercised; do not treat a SUSE run as evidence.

Tested on Hetzner dedicated servers with NVIDIA RTX 4000 SFF Ada Generation.

=head2 install_driver

Install NVIDIA GPU drivers appropriate for the detected OS using DKMS.
Blacklists the C<nouveau> driver and rebuilds the initramfs so the blacklist
takes effect on next boot.

After installation (and after reboot, if C<reboot =E<gt> 1>), calls
L</verify_nvidia_driver> to confirm the kernel module loaded correctly. Not
the full L</verify_nvidia>: the container toolkit is installed after the
driver, so its check could only warn here.

Dies if the detected OS is not supported.

If a working NVIDIA driver is already loaded and functional (C<nvidia-smi -L>
lists a GPU B<and> C<libcuda.so.1> is in the linker cache, C<ldconfig -p>) —
for example on a host provisioned via the NVIDIA CUDA package repository, or
on a re-run — C<install_driver> logs this and returns immediately without
installing anything, and without blacklisting nouveau or rebooting. A host
where C<nvidia-smi> works but C<libcuda.so.1> is missing gets a warning and
the driver install (see L<Rex::GPU::NVIDIA::Setup/already_installed>). This keeps the call idempotent and stops the per-distro package
selection from installing a second, version-conflicting (or lower) driver over
the one already present.

Options:

=over

=item C<reboot>

If true, the host is rebooted immediately after driver installation.
The function waits up to 5 minutes for the host to come back (polling
every 5 seconds via SSH reconnect; the host counts as back once
C<echo ok> run over the new connection prints C<ok>), then continues with
verification.
Default: C<0>.

Rebooting is required on the first deployment when the C<nouveau>
open-source driver was previously loaded, because nouveau must be
unloaded before the NVIDIA kernel module can bind to the device.

=item C<gpus>

Optional arrayref of the GPUs this driver install is for.
L<Rex::GPU/gpu_setup> passes every CUDA-capable NVIDIA GPU it detected here,
in the shape L<Rex::GPU::Detect/detect> returns. Only C<device_id>,
C<name> and the vGPU keys (C<vgpu>, C<vgpu_type>, C<subsystem_id>) are
read, so a caller that finds the GPUs itself -- without C<lspci> -- passes
just the first two; a GPU without C<vgpu> is not a vGPU:

  install_driver(gpu => { device_id => '2b85', name => 'NVIDIA GeForce RTX 5090' });

B<NVIDIA vGPU guest> (karr #24; C<vgpu =E<gt> 1>, see
L<Rex::GPU::Detect/NVIDIA vGPU guests>): such a device needs NVIDIA's
licensed vGPU guest (GRID) driver, which none of the package sources
Rex::GPU installs from carries, and the open C<nvidia.ko> of the datacenter packages
refuses an Ampere-or-newer vGPU. The already-installed check below runs
first: a guest whose vGPU driver already works (C<nvidia-smi -L> lists the
GPU and C<libcuda.so.1> is in the linker cache) goes on as usual, and
L<Rex::GPU/gpu_setup> then installs the container toolkit, CDI and
containerd for it. Without a working driver C<install_driver> B<dies> after
that probe and before anything on the host is changed:

  NVIDIA vGPU guest (type NVIDIA A10-2Q, 10de:2236 sub 14b9): install the
  licensed NVIDIA vGPU guest driver, then run again. No driver package was
  installed and no package source was added

The same when a vGPU is passed together with a GPU that is not one (a
passed-through card next to it): one NVIDIA kernel module drives every GPU
of the host, so the vGPU guest driver and the driver Rex::GPU would install
exclude each other; the message names both. With a working driver that
mixed host also goes on as usual.

C<device_id> is four hex digits, without C<0x> (sysfs C<device> reads
C<0x2b85>) and without a newline; any other defined value dies before the
host is touched. See L<Rex::GPU::NVIDIA::Setup/gpus>. C<install_driver>
itself never runs C<lspci> or installs C<pciutils>, with or without
C<gpus>. One driver has to drive them all: the driver is chosen for
the B<intersection> of their requirements (L<Rex::GPU::NVIDIA::Requirement>:
kernel module and driver-branch range, keyed on the C<device_id>), and
C<install_driver> B<dies> before anything on the host is changed when the
GPUs cannot share one driver -- e.g. a V100 (proprietary module, 580 or
older) next to a B200 (open module only) -- naming the GPUs on each side.

=item C<gpu>

A single GPU hashref: C<< gpu => $g >> is C<< gpus => [ $g ] >>. Kept for
callers from before C<gpus>; passing both dies.

=item C<setup>

B<Experimental.> A L<Rex::GPU::NVIDIA::Setup> class name or object to
install with, instead of the class for the OS. Chosen in this order: this
option, then C<set gpu_nvidia_setup =E<gt> ...> in the Rexfile, then
L</setup_class_for_os> (see L</setup_for>). A class name is loaded from
C<@INC> -- Rex puts the C<lib/> directory next to the Rexfile there --
unless the package is already defined, e.g. in the Rexfile itself. An
object is used as it is, except that one without GPUs of its own gets
C<gpus> (see L<Rex::GPU::NVIDIA::Setup/adopt>). A module that is missing
or does not compile, or a class that is not a Setup, dies before anything
touches the host. One object serves one host: build it inside the task (it
caches that host's facts); a second install with it dies. With a class of
your own, an OS without a built-in class is no longer refused. How to write
one:
L<Rex::GPU::NVIDIA::Setup/WRITING YOUR OWN SETUP>.

=item C<requirement>

B<Experimental.> An extra constraint on the driver: a hashref with any of
C<kernel_module> (C<open>, C<proprietary>, C<either>), C<min_branch>,
C<max_branch>, or a L<Rex::GPU::NVIDIA::Requirement> object. It is
B<intersected> with what C<gpus> need, never replaces it: C<< { kernel_module
=E<gt> 'open' } >> moves an Ada to the open driver, but on a V100
(proprietary only) makes C<install_driver> die before anything on the host
is changed, and a Kepler is refused whatever it says. An unknown key or a
bad value dies before the host is touched. See
L<Rex::GPU::NVIDIA::Setup/extra_requirement>.

=item C<nvswitches>

Optional arrayref of the host's NVSwitch chips, what
L<Rex::GPU::Detect/detect> returns under C<nvswitch>;
L<Rex::GPU/gpu_setup> passes it when it found one. Non-empty means an HGX
baseboard whose GPUs need NVIDIA Fabric Manager:

=over

=item * the driver source must provide one -- a source that does not
(Debian C<non-free>, openSUSE's GFX repository) is rejected, and with none
left C<install_driver> dies before anything on the host is changed;

=item * on apt its package must have an installation candidate after the
index refresh, checked before the driver is installed;

=item * after the driver packages are verified it is installed at
B<exactly> the installed driver's upstream version, checked with
C<dpkg-query> / C<rpm -q> (dies otherwise; the driver stays installed), and
C<nvidia-fabricmanager.service> is enabled;

=item * with C<reboot> the enabled unit starts on boot; without it,
C<install_driver> starts it after C<modprobe nvidia>. Either way it then
checks C<systemctl is-active> and only warns if the unit is not running
(e.g. nouveau still holds the GPUs until the reboot).

=back

The package: Ubuntu C<nvidia-fabricmanager-NNN> of the chosen C<-server>
branch; Debian 12/13 and RHEL/Rocky/Alma C<nvidia-fabricmanager> from
NVIDIA's CUDA repository.

If a working driver is already installed (e.g. an HGX host provisioned
before Rex::GPU installed Fabric Manager), the driver is left alone and
L<Rex::GPU::NVIDIA::Setup/retrofit_fabric_manager> decides, host-read-only
first:

=over

=item * a Fabric Manager package is already installed: nothing is changed;
if its version is not the loaded driver's (C<nvidia-smi
--query-gpu=driver_version>) it warns;

=item * none is: after C<apt-get update> (apt; dnf refreshes expired
metadata itself) it asks the host's B<current> package sources -- C<apt-cache
madison> / C<dnf list --showduplicates> -- for the same package name a fresh
install would use, at exactly the loaded driver's version (on apt a
simulated install must also remove nothing). Offered: installed, checked
with C<dpkg-query> / C<rpm -q>, the unit enabled and started; a failure
there dies, the driver untouched. Not offered, the version unreadable, or
no package name known (openSUSE): it warns with the reason and the version
needed, and installs nothing. No package source is ever added for this.

=back

Then, as after an install, it warns if the unit is not active. Omitted or empty
(the default, and every caller that finds its GPUs without C<lspci>): no
Fabric Manager, nothing changes.

B<HGX B200/B300> (karr #56): their NVSwitches are not PCI devices on the
host, so there are no C<nvswitches>; they are recognised by the GPUs'
device IDs instead (B200 C<2901>/C<2909>, B300 C<3182>;
L<Rex::GPU::NVIDIA::Setup/nvlink_platforms>, from C<gpus>, so also for a
caller without L<Rex::GPU::Detect>), and everything above applies to them
as to an NVSwitch host -- the driver source must provide Fabric Manager, it
is installed at exactly the driver's version and its unit enabled and
started. On top of that, after Fabric Manager:

=over

=item * C<nvlsm> (the NVLink Subnet Manager; no service of its own,
C<nvidia-fabricmanager.service> starts it), C<infiniband-diags> and
C<libibumad3> (RHEL family: C<libibumad>), plus on Ubuntu
C<linux-modules-extra> of the running kernel, B<unversioned> -- the newest
the repository has, as NVIDIA's own gpu-driver-container installs them --
through C<apt-get>/C<dnf> and checked with C<dpkg -l>/C<rpm -q> (dies if
one is missing; the driver and Fabric Manager stay installed);

=item * C<nvlsm> comes from NVIDIA's CUDA repository. On Debian 12/13 and
the RHEL family that is where the driver came from. Ubuntu's driver comes
from Ubuntu's archive, which has no C<nvlsm>: the CUDA repository is added
there, only on these hosts, after the driver and Fabric Manager are
installed, with an apt pin that lets nothing but C<nvlsm> come from it (see
L<Rex::GPU::NVIDIA::Setup::Ubuntu/prepare_nvlink_fabric_source>);

=item * C<ib_umad> is loaded (C<modprobe>) and listed in
C</etc/modules-load.d/ib_umad.conf> -- Fabric Manager's start script
refuses to run without it;

=item * a running kernel older than 5.17 gets a warning (not on the RHEL
family, whose 5.14 kernel NVIDIA supports for these boards); nothing stops;

=item * after Fabric Manager is started (or the reboot), C<nvidia-smi -q>
must show C<Fabric State: Completed>, C<Status: Success> for every GPU,
read up to 12 times 10 seconds apart while the unit is active
(L<Rex::GPU::NVIDIA::Setup/check_nvlink_fabric>). If not, one loud warning
with what it read and where to look; C<install_driver> does not die and
L</verify_nvidia> is not affected.

=back

Where Rex::GPU knows no C<nvlsm> source -- Ubuntu other than 22.04/24.04
or not amd64, RHEL before 9, Debian other than 12/13 -- and on openSUSE
(no Fabric Manager source), C<install_driver> dies before anything on the
host is changed. With an already-installed driver the missing ones of those
packages are installed from the host's B<current> package sources only (no
repository is added, as for Fabric Manager above; a package still missing
only warns), C<ib_umad> is loaded, the unit started if anything was
installed or loaded, and the Fabric State is checked the same way.
GB200/GB300 NVL72 compute trays get an info line instead: multi-node NVLink
needs C<nvidia-imex> and its configuration, which Rex::GPU does not set up.

=back

Omit C<gpus> and C<gpu> (or pass C<undef>) to keep the GPU-agnostic
package selection.

Each distro's L<Rex::GPU::NVIDIA::Setup> class has an ordered list of
driver sources; the first that fits the requirement is installed, and if
none fits, C<install_driver> dies before anything is changed, listing every
source and why it was rejected. What the requirement picks:

=over

=item * B<No constraint> (Turing, Ampere, Ada, Hopper and every GPU the
table does not know; no GPU): the first source -- Ubuntu the newest
C<-server>, Debian C<non-free> C<nvidia-driver>, RHEL C<open-dkms>,
openSUSE open C<G06>/C<G07>.

=item * B<Blackwell> (open kernel module only, branch 570 or newer; GB10 and
Blackwell Ultra 580 or newer): Ubuntu the newest C<-server-open>. On Debian
no Debian-packaged driver fits (bookworm ships 535, trixie 550), so the
driver comes from NVIDIA's CUDA apt repository instead of C<non-free>: the
C<cuda-keyring> package for C<debian12> or C<debian13> (C<x86_64> for amd64,
C<sbsa> for arm64), then the compute-only open-module set
C<nvidia-driver-cuda> + C<nvidia-kernel-open-dkms>; C<non-free> is not
enabled on that path. On any other Debian release or architecture it dies.
RHEL and openSUSE: their default open driver.

=item * B<Maxwell, Pascal, Volta> (C<1340>-C<1DF6>, e.g. Tesla M60, P100,
P40, V100): the proprietary driver of the 580 branch, their last. On Ubuntu
C<nvidia-driver-580-server>; if apt has no candidate for it,
C<install_driver> dies before installing and does not fall back to another
branch. On RHEL/Rocky/Alma 8 and 9 module stream C<nvidia-driver:580-dkms>;
on RHEL 10 C<python3-dnf-plugin-versionlock> and a C<dnf versionlock> on
C<*nvidia*580*>; both then install C<kmod-nvidia-latest-dkms> +
C<nvidia-driver> + C<nvidia-driver-cuda>, and verify the kmod and a 580
C<nvidia-driver>. On openSUSE Leap 15 and 16 C<nvidia-driver-G06-kmp-meta>,
verified with C<rpm -q>. On Debian 11/12/13 the C<non-free> driver (470,
535, 550); on a Debian release without a known C<non-free> branch it dies.

=item * B<Kepler or older> (device ID below C<1340>, e.g. Tesla K80/K40), as
any one of the GPUs: the newest driver that supports it is the end-of-life
470 branch. C<install_driver> B<dies> on every distro before anything on the
host is changed. A host whose driver was installed by hand (C<nvidia-smi -L>
lists the GPU and C<libcuda.so.1> is in the linker cache) passes the
already-installed check above instead. L<Rex::GPU/gpu_setup> passes only
compute GPUs, and detection never counts a Kepler as compute, at any PCI
class (karr #55): a Kepler display card and a class-C<0302> Tesla
K80/K40/K20 are skipped there with a warning and never reach
C<install_driver>. The refusal here is for a caller that passes one
directly.

=back

A mixed host gets what the combination needs: an Ada next to a B200 gets
the open driver (Ubuntu C<-server-open>), an Ada next to a V100 the
proprietary 580 one (Ubuntu C<nvidia-driver-580-server>).

  install_driver();              # install only, load module without reboot
  install_driver(reboot => 1);   # install, reboot, verify
  install_driver(gpus => [ grep { $_->{compute} } @{ $gpus->{nvidia} } ]);
  install_driver(gpu => $gpus->{nvidia}[0]);   # one GPU, the older form
  install_driver(gpus => \@compute, setup => 'My::GPU::Setup');
  install_driver(gpus => \@compute, requirement => { min_branch => 580 });

=head2 setup_class_for_os

  my $class = Rex::GPU::NVIDIA->setup_class_for_os;

B<Experimental.> The L<Rex::GPU::NVIDIA::Setup> class L</install_driver> uses
on this host: L<Rex::GPU::NVIDIA::Setup::Ubuntu> on Ubuntu,
L<Rex::GPU::NVIDIA::Setup::Debian> on every other Debian-family host,
L<Rex::GPU::NVIDIA::Setup::RHEL> on the RHEL family,
L<Rex::GPU::NVIDIA::Setup::SUSE> on openSUSE, and C<undef> elsewhere
(L</install_driver> then dies). Asked only when neither the C<setup> option
nor C<set gpu_nvidia_setup> chose a class (see L</setup_for>).

The RHEL family is what L<Rex::Commands::Gather/is_redhat> accepts, plus the
names Rex reports for Rocky Linux, AlmaLinux and CentOS Stream when
C<lsb_release> is installed and C<is_redhat> does not know them: C<Rocky>,
C<RockyLinux>, C<AlmaLinux>, C<CentOSStream>. L</install_container_toolkit>
recognises the same names. Reads nothing from the host.

=head2 setup_for

  my $setup = Rex::GPU::NVIDIA->setup_for(
    gpus              => \@gpus,
    setup             => 'My::GPU::Setup',   # optional
    extra_requirement => { ... },            # optional
    nvswitches        => \@nvswitches,        # optional
  );

B<Experimental.> The L<Rex::GPU::NVIDIA::Setup> object L</install_driver>
runs, chosen in this order:

=over

=item 1. C<setup> -- a class name or an object (L</install_driver>'s
C<setup> option);

=item 2. C<set gpu_nvidia_setup =E<gt> ...> in the Rexfile -- a class name
only: the setting is shared by every host, an object holds one host's
facts;

=item 3. L</setup_class_for_os>.

=back

A class is loaded (L</custom_setup>) and built with C<gpus>,
C<extra_requirement> and C<nvswitches>; an object gets them through
L<Rex::GPU::NVIDIA::Setup/adopt>. Returns C<undef> only when nothing chose
a class and the OS has none. Reads nothing from the host.

=head2 custom_setup

  my $class_or_object = Rex::GPU::NVIDIA->custom_setup($setup_option);

B<Experimental.> The setup the user chose -- C<$setup_option> if defined,
else C<set gpu_nvidia_setup> -- validated, or C<undef> for "choose by OS".
A class name is loaded with L<Module::Runtime/use_module> unless the package
is already defined (e.g. written into the Rexfile itself), from C<@INC>,
where Rex puts the C<lib/> directory next to the Rexfile and in the current
directory. Croaks, before anything touches the host, if the name is not a
package name, the module cannot be found or does not compile, or the class
or object is not a L<Rex::GPU::NVIDIA::Setup>.

=head2 install_container_toolkit

Install the NVIDIA Container Toolkit (C<nvidia-container-toolkit> package)
from the official NVIDIA package repository at
L<https://nvidia.github.io/libnvidia-container/>.

B<Already installed toolkit.> If C<nvidia-ctk --version> runs and the
package manager lists C<nvidia-container-toolkit> as installed (C<dpkg -l>
C<ii>/C<hi>, or C<rpm -q>) -- a re-run, or an image that ships the toolkit,
such as NVIDIA DGX OS -- C<install_container_toolkit> logs this and returns
without touching the repository, the key or the package. The trade-off: a
re-run no longer upgrades an installed toolkit to the repository's newest
version; upgrade it with the package manager (C<apt-get install
--only-upgrade nvidia-container-toolkit>, C<dnf upgrade
nvidia-container-toolkit>, C<zypper update nvidia-container-toolkit>). An
C<nvidia-ctk> that the package manager does not know about (e.g. unpacked by
the GPU Operator) does not count: the package is installed, because
L</configure_containerd> relies on the packaged
C</usr/bin/nvidia-container-runtime>.

Otherwise the repository GPG key is imported and the package repository is
registered before installing. On Debian/Ubuntu the apt timers
(C<unattended-upgrades>, C<apt-daily>, C<apt-daily-upgrade>) are stopped
first and every C<apt-get> -- the C<curl>/C<gnupg> helpers included -- waits
up to 120 seconds for the dpkg lock, as in L</install_driver>; the key is
downloaded and dearmored to a temporary file that replaces
C</usr/share/keyrings/nvidia-container-toolkit-keyring.gpg> only when it is
non-empty, so a re-run refreshes a rotated key, and a failed download or
dearmor dies. Then the signed APT source list is written. On RHEL the
C<.repo> file is downloaded with C<curl -f> to a temporary file that
replaces C</etc/yum.repos.d/nvidia-container-toolkit.repo> only when it
contains the C<[nvidia-container-toolkit]> section; a failed download (e.g.
an HTTP error) or a file without that section dies and leaves an existing
C<.repo> as it was. On openSUSE Leap the base repository
URL is added directly (zypper cannot parse RPM C<.repo> files directly) and
refreshed, replacing any existing C<nvidia-container-toolkit> entry; a
failed C<zypper addrepo> or C<refresh> (e.g. an HTTP error or an
unresolvable host, which only the refresh reveals) dies before
C<zypper install>, and a repository that fails its refresh is removed again
(L<Rex::GPU::NVIDIA::Setup::SUSE/add_repo>). Every zypper call waits up
to 120 seconds for the zypp lock (L<Rex::GPU::NVIDIA::Setup::SUSE/zypper>).

The package is installed with C<apt-get>/C<dnf>/C<zypper> directly, never
through L<Rex::Commands::Pkg/pkg>, and the result is checked with C<dpkg -l>
(C<ii>) or C<rpm -q> on every distro, openSUSE included.

Dies if the OS is not supported or if installation fails.

=head2 configure_containerd

  configure_containerd($runtime);

Configure the containerd runtime to use the NVIDIA container runtime.
The C<nvidia-container-runtime> binary must already be installed
(L</install_container_toolkit> provides it); if it is not present this
function returns immediately without error.

An unknown C<$runtime> makes it die before any command runs on the host,
naming the valid values -- with or without C<nvidia-container-runtime>.
C<none> is not one of them here; that is L<Rex::GPU/gpu_setup>'s switch
for not calling this function at all.

C<$runtime> selects how containerd is configured:

=over

=item C<rke2> or C<k3s> (default: C<rke2>)

Registers the NVIDIA runtime C<additively>, without replacing the base
containerd config that RKE2/K3s generate. The mechanism is chosen from the
effective, generated C<config.toml> under
C</var/lib/rancher/{rke2,k3s}/agent/etc/containerd/>:

=over

=item * B<Already wired> — if that C<config.toml> already contains an
C<nvidia> runtime block (modern RKE2/K3s auto-detect
C<nvidia-container-runtime> on C<PATH> and wire it themselves), this is a
B<no-op>: nothing is written and the native config is left untouched.

=item * B<Modern (containerd 2.x / config v3)> — writes an additive drop-in
at C<config-v3.toml.d/99-nvidia.toml> (RKE2/K3s already import
C<config-v3.toml.d/*.toml>). The base config — C<SystemdCgroup>, the pinned
sandbox image, snapshotter options and the registry C<certs.d> path — is
preserved.

=item * B<Legacy (containerd 1.x / config v2)> — writes a C<config.toml.tmpl>
that begins with C<{{ template "base" . }}> and only I<adds> the nvidia
runtime, so the rendered base config is preserved.

=back

Both RKE2 and K3s use the same logic (only the C</var/lib/rancher/*> base
directory differs). If no generated C<config.toml> exists yet and no config
version marker is found, the modern v3 drop-in is written and a warning is
logged.

B<Healing an earlier clobber.> A host set up by the 0.001 release carries a
stale full-config C<config.toml.tmpl> — the bare C<imports = [...]> +
C<version = 2> template (B<no> C<{{ template "base" . }}>) that I<replaced> the
distribution's base config. RKE2/K3s render that stale template, so the
generated C<config.toml> already shows an C<nvidia> runtime and the
B<Already wired> check above would no-op and leave the clobber (missing
C<SystemdCgroup> / pinned sandbox / C<certs.d>) in place. Before that check,
C<configure_containerd> therefore removes that C<config.toml.tmpl> B<only> when
it matches the exact bare-clobber signature (never the base-extending template
above, never a user's own custom C<config.toml.tmpl>, never
C<config-v3.toml.d/>), then writes the additive v3 drop-in. Removing the
template lets the distribution regenerate its native config, but the live
C<config.toml> stays clobbered until then: this function does B<not> restart
RKE2/K3s (that would bounce the node's containerd and its workloads); it logs a
warning that the operator must restart the service or reboot the node for the
native config to regenerate.

=item C<containerd>

Calls C<nvidia-ctk runtime configure --runtime=containerd> and restarts
the C<containerd> systemd service. Suitable for standalone (non-Rancher)
containerd installations.

=back

=head2 verify_nvidia

Verify the current NVIDIA installation by checking three things:

=over

=item 1. C<nvidia> kernel module is loaded (C<lsmod | grep nvidia>)

=item 2. C<nvidia-smi -L> reports at least one GPU

=item 3. C<nvidia-ctk> binary is available (Container Toolkit present)

=back

Returns C<1> if all checks pass, C<0> if any check fails. A warning is
logged for each failure; the function does not die. A partial installation
(e.g. driver installed but host not yet rebooted) emits a summary warning
noting that features may not work until reboot.

=head2 verify_nvidia_driver

The driver half of L</verify_nvidia>, what L</install_driver> runs after an
install:

=over

=item 1. C<nvidia> kernel module is loaded (C<lsmod | grep nvidia>)

=item 2. C<nvidia-smi -L> reports at least one GPU

=item 3. C<libcuda.so.1> is in the linker cache
(L<Rex::GPU::NVIDIA::Setup/libcuda_command>) -- what
L<Rex::GPU::NVIDIA::Setup/already_installed> requires, so a failure here
means the next run installs again

=back

Does not look for the container toolkit. Returns C<1> if all checks pass,
C<0> otherwise; logs a warning per failure and never dies. Not exported:
call it as C<Rex::GPU::NVIDIA::verify_nvidia_driver()>.

=head2 generate_cdi_specs

Generate CDI (Container Device Interface) specifications for the detected
NVIDIA GPUs so the Kubernetes NVIDIA device plugin can enumerate GPU resources
without requiring a privileged container.

If a B<managed CDI source> already owns the runtime scan dir, this function
does B<not> also write a static C</etc/cdi/nvidia.yaml>. Modern
C<nvidia-container-toolkit> ships C<nvidia-cdi-refresh.path>/C<.service>, which
regenerate C</run/cdi/nvidia.yaml> and keep it fresh across driver updates.
Because C</etc/cdi> and C</run/cdi> are both default CDI scan dirs, a second
static copy would define the same device kind (C<nvidia.com/gpu>) twice — a
duplicate-device load error in CDI consumers — and would drift against the
refreshed copy over driver updates. In that case the managed generator is
triggered once (so C</run/cdi> is populated immediately) and left to own CDI.

Otherwise — no managed refresh unit and no existing C</run/cdi/nvidia.yaml> —
output is written to C</etc/cdi/nvidia.yaml> via C<nvidia-ctk cdi generate>, and
the C</etc/cdi/> directory is created if it does not exist. Only one of the two
scan dirs is ever populated.

The managed-source check keys on the C<nvidia-cdi-refresh.path> systemd unit
state (installed/armed) rather than only on the presence of
C</run/cdi/nvidia.yaml>, because C</run> is tmpfs and is empty right after the
first-deploy reboot even though the refresh unit owns CDI from then on.

This step must be run after L</install_container_toolkit> (which provides
C<nvidia-ctk> and the refresh unit) and, on first deploy, after the reboot that
activates the NVIDIA kernel module (so the tool can enumerate physical devices).

B<MIG.> The spec reflects the MIG layout at the time it is generated (MIG
instances are included by default). Neither the static C</etc/cdi/nvidia.yaml>
nor C<nvidia-cdi-refresh> regenerates it when MIG mode or instances are
reconfigured. After changing MIG, run
C<systemctl restart nvidia-cdi-refresh.service>, or on a host without that unit
C<nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml>. The MIG strategy
Kubernetes exposes (C<single> / C<mixed>) is configured in the NVIDIA device
plugin or GPU Operator, not here.

=head1 SEE ALSO

L<Rex::GPU>, L<Rex::GPU::Detect>,
L<https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/>

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
