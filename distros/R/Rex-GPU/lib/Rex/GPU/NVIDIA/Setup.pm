# ABSTRACT: Base class of the per-distro NVIDIA driver setups (experimental)

package Rex::GPU::NVIDIA::Setup;
our $VERSION = '0.002';
use Moo;
use Carp qw( croak );
use Rex::Commands::File ();
use Rex::Commands::Gather ();
use Rex::Commands::Pkg ();
use Rex::Commands::Run ();
use Rex::Logger ();
use Rex::GPU::NVIDIA::Requirement ();
use Scalar::Util qw( blessed );
use namespace::autoclean;

# No `use utf8` here, on purpose: the die messages carry UTF-8 em dashes as
# byte strings exactly like Rex::GPU::NVIDIA always emitted them.


has gpu  => ( is => 'ro' );
has gpus => ( is => 'lazy', writer => '_set_gpus' );

sub _build_gpus {
  my ( $self ) = @_;
  return defined $self->gpu ? [ $self->gpu ] : [];
}

sub BUILD {
  my ( $self, $args ) = @_;
  croak __PACKAGE__.'->new: pass gpu or gpus, not both'
    if defined $args->{gpu} && defined $args->{gpus};
  croak __PACKAGE__.'->new: gpus must be an arrayref of GPU hashrefs'
    if defined $args->{gpus} && ref $args->{gpus} ne 'ARRAY';
  croak __PACKAGE__.'->new: nvswitches must be an arrayref'
    if defined $args->{nvswitches} && ref $args->{nvswitches} ne 'ARRAY';
  $self->_check_gpus($args->{gpus} // [ defined $args->{gpu} ? $args->{gpu} : () ]);
}

# A device_id that is there but not four hex digits ("0x2b85" from sysfs,
# "2b85\n" from a cat) would make Requirement->from_gpu see an unknown GPU:
# no Kepler refusal, no open module for Blackwell. Croak instead (karr #42).
sub _check_gpus {
  my ( $self, $gpus ) = @_;
  for my $gpu (grep { ref $_ eq 'HASH' } @$gpus) {
    my $id = $gpu->{device_id};
    next if !defined $id || $id =~ /\A[0-9a-f]{4}\z/i;
    croak "NVIDIA GPU '".( $gpu->{name} // 'unknown' )."': device_id '".$id."' is not "
      .'a PCI device ID of four hex digits, e.g. 2b85 (no 0x, no newline). No driver '
      .'package was installed and no package source was added';
  }
  return;
}


has nvswitches => ( is => 'lazy', writer => '_set_nvswitches' );

sub _build_nvswitches { [] }

sub fabric_manager_needed {
  my ( $self ) = @_;
  return 1 if grep { ref $_ eq 'HASH' } @{ $self->nvswitches };
  return $self->nvlink_fabric_needed;
}

sub fabric_label {
  my ( $self ) = @_;
  return ( grep { ref $_ eq 'HASH' } @{ $self->nvswitches } )
    ? 'NVSwitch' : 'HGX B200/B300 NVLink fabric';
}


sub nvlink_platform_ids {
  return (
    '2901' => 'hgx-nvlink5',   # B200
    '2909' => 'hgx-nvlink5',   # B200
    '3182' => 'hgx-nvlink5',   # B300 SXM6 AC
    '2941' => 'nvl72',         # GB200
    '31c2' => 'nvl72',         # GB300
    '31c3' => 'nvl72'          # GB300
  );
}

sub nvlink_platforms {
  my ( $self ) = @_;
  my %platform = $self->nvlink_platform_ids;
  my %seen = map { $_ => 1 }
    grep { defined }
    map { $platform{ lc( $_->{device_id} // '' ) } }
    grep { ref $_ eq 'HASH' } @{ $self->gpus };
  return sort keys %seen;
}

sub nvlink_fabric_needed {
  my ( $self ) = @_;
  return ( grep { $_ eq 'hgx-nvlink5' } $self->nvlink_platforms ) ? 1 : 0;
}

# extra_requirement may be given as a plain hashref; it becomes an object of
# the class's requirement_class here, so a typo croaks at construction -- on
# every host, not only on one that gets as far as plan.
around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args->{extra_requirement} = $class->_coerce_requirement($args->{extra_requirement})
    if defined $args->{extra_requirement};
  return $args;
};


has requirement => ( is => 'lazy', predicate => '_has_requirement' );

has extra_requirement => ( is => 'ro', writer => '_set_extra_requirement' );

sub requirement_class { 'Rex::GPU::NVIDIA::Requirement' }

sub _build_requirement {
  my ( $self ) = @_;
  my $class = $self->requirement_class;
  my $extra = $self->extra_requirement;
  my @gpus  = grep { ref $_ eq 'HASH' } @{ $self->gpus };
  return $extra // $class->new unless @gpus;
  my @reqs = map { $class->from_gpu($_) } @gpus;
  if ( my @conflicts = $class->conflicts(@reqs) ) {
    die 'No single NVIDIA driver supports all GPUs on this host: '
      .join('; ', @conflicts).'. No driver package was installed and no package '
      .'source was added. Install the '
      ."driver yourself; once `nvidia-smi -L` lists the GPUs and libcuda.so.1 is in "
      ."the linker cache, install_driver skips the driver step\n";
  }
  my $gpu_req = $class->intersect(@reqs);
  return $gpu_req unless $extra;
  # The user's requirement only tightens (karr #34): a conflict with what the
  # GPUs need dies here, in plan, before anything on the host is changed.
  if ( my @conflicts = $class->conflicts($gpu_req, $extra) ) {
    die 'No NVIDIA driver meets both what the GPUs need and '.$extra->who.' ('
      .$extra->describe.'): '.join('; ', @conflicts).'. No driver package was '
      .'installed and no package source was added. '
      ."Loosen the requirement, or install the driver yourself\n";
  }
  return $class->intersect($gpu_req, $extra);
}

my %REQUIREMENT_KEY = map { $_ => 1 } qw( kernel_module min_branch max_branch name );

# A hashref or requirement object -> requirement object. Callable on the class
# (BUILDARGS) and on an object (adopt).
sub _coerce_requirement {
  my ( $self, $req ) = @_;
  my $base = 'Rex::GPU::NVIDIA::Requirement';
  return $req if blessed($req) && $req->isa($base);
  croak __PACKAGE__.': a requirement is a hashref or a '.$base.' object, not '
    .( defined $req ? "'".$req."'" : 'undef' )
    unless ref $req eq 'HASH';
  my @unknown = sort grep { !$REQUIREMENT_KEY{$_} } keys %$req;
  croak __PACKAGE__.': unknown requirement key'.( @unknown == 1 ? '' : 's' ).' '
    .join(', ', @unknown).' -- known: kernel_module, min_branch, max_branch, name'
    if @unknown;
  return $self->requirement_class->new(name => 'the requirement option', %$req);
}


sub adopt {
  my ( $self, %arg ) = @_;
  my $gpus  = $arg{gpus} // [];
  croak __PACKAGE__.'->adopt: gpus must be an arrayref of GPU hashrefs'
    unless ref $gpus eq 'ARRAY';
  croak ref($self).' object passed as setup => has already run install -- it '
    .'holds that host\'s facts and GPUs. Build a new object per host, or pass a '
    .'class name. No driver package was installed and no package source was added'
    if $self->_installed;
  my $extra = defined $arg{extra_requirement}
    ? $self->_coerce_requirement($arg{extra_requirement}) : undef;
  $self->_check_gpus($gpus);
  my $nvswitches = $arg{nvswitches} // [];
  croak __PACKAGE__.'->adopt: nvswitches must be an arrayref'
    unless ref $nvswitches eq 'ARRAY';
  # NVSwitches add the Fabric Manager step and a source filter plan applies;
  # they do not touch the requirement, so no fixed-requirement check for them.
  $self->_set_nvswitches($nvswitches) if @$nvswitches && !@{ $self->nvswitches };
  my $take_gpus = @$gpus && !@{ $self->gpus };
  return $self unless $take_gpus || $extra;
  croak ref($self).' object passed as setup => already has a fixed requirement '
    .'(given to new or built by plan), so the detected GPUs or the requirement '
    .'option could not be checked. Build it without requirement =>, or pass a '
    .'class name. No driver package was installed and no package source was added'
    if $self->_has_requirement;
  croak ref($self).' object passed as setup => has an extra_requirement of its '
    .'own and the requirement option was given too; pass one of them. No driver '
    .'package was installed and no package source was added'
    if $extra && $self->extra_requirement;
  $self->_set_gpus($gpus) if $take_gpus;
  $self->_set_extra_requirement($extra) if $extra;
  return $self;
}


has os      => ( is => 'lazy' );
has release => ( is => 'lazy' );
has arch    => ( is => 'lazy' );
has kernel  => ( is => 'lazy' );

sub _build_os      { Rex::Commands::Gather::operating_system() }
sub _build_release { Rex::Commands::Gather::operating_system_release() }

sub _build_arch {
  my ( $self ) = @_;
  my $arch = $self->run_cmd('uname -m', auto_die => 0);
  chomp $arch if defined $arch;
  return $arch;
}

sub _build_kernel {
  my ( $self ) = @_;
  # auto_die left to Rex's default, as install_driver always read it
  my $kernel = $self->run_cmd('uname -r');
  chomp $kernel;
  return $kernel;
}

#### The host seam ############################################################


sub run_cmd  { my ( $self, @args ) = @_; return Rex::Commands::Run::run(@args) }
sub pkg_cmd  { my ( $self, @args ) = @_; return Rex::Commands::Pkg::pkg(@args) }
sub file_cmd { my ( $self, @args ) = @_; return Rex::Commands::File::file(@args) }

#### The flow #################################################################


# Set once install starts: the object has read (and cached) one host's facts
# and GPUs, so adopt refuses to hand it to another host.
has _installed => ( is => 'rwp', init_arg => undef );

sub install {
  my ( $self ) = @_;
  $self->_set__installed(1);
  return 0 if $self->already_installed;
  my $plan = $self->plan;
  $self->prepare_host($plan);
  $self->prepare_source($plan);
  $self->resolve_plan($plan);
  $self->install_packages($plan);
  $self->verify_packages($plan);
  $self->install_fabric_manager($plan) if $self->fabric_manager_needed;
  $self->install_nvlink_fabric($plan) if $self->nvlink_fabric_needed;
  $self->post_install($plan);
  return 1;
}


sub already_installed {
  my ( $self ) = @_;
  # nvidia-smi -L lists a "GPU N:" device only when the module is loaded and
  # functional, so it is the safe, OS-neutral signal. Distro-neutral and
  # BEFORE package selection: a host set up from NVIDIA's CUDA repo would
  # otherwise get a different (possibly lower) driver whose libs conflict.
  my $smi = $self->run_cmd('nvidia-smi -L 2>&1', auto_die => 0);
  chomp $smi if defined $smi;
  return 0 unless $self->_driver_present($smi);
  # ... and libcuda (karr #42): a module without the CUDA user-space library
  # cannot run a CUDA workload, so it is not "installed". Probed only after
  # nvidia-smi passed: a fresh host runs no more than the one probe.
  unless ($self->_libcuda_present) {
    Rex::Logger::info("nvidia-smi lists a GPU ($smi) but libcuda.so.1 is not in the "
      .'linker cache (ldconfig -p) — installing the driver packages', 'warn');
    return 0;
  }
  Rex::Logger::info("NVIDIA driver already present and working — skipping driver install ($smi)");
  return 1;
}

sub libcuda_command { q{/sbin/ldconfig -p 2>/dev/null | grep -q '^[[:space:]]*libcuda\.so\.1 '} }

# Runs libcuda_command; 1 if it exited 0.
sub _libcuda_present {
  my ( $self ) = @_;
  $self->run_cmd($self->libcuda_command, auto_die => 0);
  return $? == 0 ? 1 : 0;
}


sub plan {
  my ( $self ) = @_;
  # vGPU guest (karr #24): after already_installed (a guest whose vGPU
  # driver runs passes there) and before anything on the host is changed.
  $self->_reject_vgpu_guest;
  # Kepler or older (karr #26), on any GPU in the list: die here, after
  # already_installed (a host whose operator installed 470 by hand still
  # passes) and before anything on the host is changed or even read.
  $self->_reject_unsupported_gpu($_) for @{ $self->gpus };
  # Multi-GPU (karr #33): one driver for all of them, or die untouched.
  my $requirement = $self->requirement;
  Rex::Logger::info('Installing NVIDIA drivers on '.$self->os.' (kernel '.$self->kernel.')');
  Rex::Logger::info('  Driver requirement: '.$requirement->who.': '.$requirement->describe)
    if @{ $self->gpus } || $self->extra_requirement;

  my $plan = { packages => [ $self->kernel_packages ], verify => [] };
  my @sources = $self->sources;
  return $plan unless @sources;
  my $source = $self->select_source(@sources);
  # HGX B200/B300 (karr #56): nvlsm must have a source too, known before any
  # change -- a driver without it cannot run CUDA there either.
  if ($self->nvlink_fabric_needed) {
    my $why = $self->nvlink_fabric_unavailable($source);
    die 'HGX B200/B300 on this '.$self->os.' '.( $self->release // '' ).' host: '.$why
      .'. Without nvlsm and Fabric Manager CUDA fails with cudaErrorSystemNotReady, so '
      .'no driver package was installed and no package source was added. Install the '
      ."driver, Fabric Manager and nvlsm yourself\n" if defined $why;
  }
  $plan->{source} = $source;
  push @{ $plan->{packages} }, @{ $source->{packages} // [] };
  $plan->{verify} = [ @{ $source->{verify} // [] } ];
  return $plan;
}

sub kernel_packages { () }
sub sources         { () }

sub resolve_source {
  my ( $self, $source ) = @_;
  return $source;
}

sub select_source {
  my ( $self, @candidates ) = @_;
  my $requirement = $self->requirement;
  my @rejected;
  for my $candidate (@candidates) {
    my $why = $candidate->{unavailable} // $requirement->why_not($candidate)
      // $self->_fabric_manager_why_not($candidate);
    unless (defined $why) {
      Rex::Logger::info('  Driver source: '.$candidate->{name});
      return $candidate;
    }
    push @rejected, $candidate->{name}.': '.$why;
  }
  die 'No NVIDIA driver source on this '.$self->os.' '.( $self->release // '' ).' host fits '
    .$requirement->who.' ('.$requirement->describe.') -- '.join('; ', @rejected)
    .'. No driver package was installed and no package source was added. Install '
    .'the driver yourself; once '
    ."`nvidia-smi -L` lists the GPU and libcuda.so.1 is in the linker cache, "
    ."install_driver skips the driver step\n";
}

sub resolve_plan {
  my ( $self, $plan ) = @_;
  my $source = $plan->{source} or return;
  # After prepare_source (karr #35): the package index is fresh now, so a
  # source that picks its package from it (Ubuntu's apt-cache search) sees
  # what the repository carries, not a fresh image's stale or empty lists.
  my $resolved = $self->resolve_source($source);
  my $requirement = $self->requirement;
  my $why = $resolved->{unavailable} // $requirement->why_not($resolved);
  die 'The NVIDIA driver source '.$source->{name}.' chosen for '.$requirement->who
    .' ('.$requirement->describe.') has nothing to install on this '.$self->os.' '
    .( $self->release // '' ).' host: '.$why.'. No driver package was installed, '
    .'only the package sources were prepared. Install the driver yourself; once '
    ."`nvidia-smi -L` lists the GPU and libcuda.so.1 is in the linker cache, "
    ."install_driver skips the driver step\n"
    if defined $why;
  $self->_check_fabric_manager_source($resolved) if $self->fabric_manager_needed;
  return if $resolved == $source;
  my %old = map { $_ => 1 } @{ $source->{packages} // [] };
  $plan->{source}   = $resolved;
  $plan->{packages} = [ ( grep { !$old{$_} } @{ $plan->{packages} } ),
    @{ $resolved->{packages} // [] } ];
  $plan->{verify}   = [ @{ $resolved->{verify} // [] } ];
  Rex::Logger::info('  Driver packages: '.join(', ', @{ $resolved->{packages} // [] }));
  return;
}

# NVSwitch host (karr #23): a source that names no Fabric Manager package
# cannot make the GPUs usable -- without Fabric Manager CUDA init fails with
# cudaErrorSystemNotReady -- so it does not fit, like a wrong branch.
sub _fabric_manager_why_not {
  my ( $self, $source ) = @_;
  return unless $self->fabric_manager_needed;
  return if defined $source->{fabric_manager};
  return 'no NVIDIA Fabric Manager package for the '.$self->fabric_label.' on this host';
}

# After resolve (the branch is exact now): the package name must be complete
# and the repository must carry it -- dies before any driver package goes in.
sub _check_fabric_manager_source {
  my ( $self, $source ) = @_;
  my $fm  = $self->fabric_manager_package($source);
  my $why = defined $fm
    ? $self->fabric_manager_unavailable($fm)
    : 'its Fabric Manager package '.( $source->{fabric_manager} // '(none)' )
      .' needs an exact driver branch, and none is known';
  die 'The NVIDIA driver source '.$source->{name}.' has no Fabric Manager for the '
    .$self->fabric_label.' on this host: '.$why.'. No driver package was installed, only the package sources '
    ."were prepared. Install the driver and a Fabric Manager of exactly its version yourself\n"
    if defined $why;
  Rex::Logger::info('  Fabric Manager package: '.$fm);
  return;
}


sub fabric_manager_package {
  my ( $self, $source ) = @_;
  return $self->_with_branch($source->{fabric_manager}, $source);
}

sub fabric_manager_unavailable { return }

sub fabric_manager_service { 'nvidia-fabricmanager.service' }

sub install_fabric_manager {
  my ( $self, $plan ) = @_;
  my $source = $plan->{source} // {};
  my $fm = $self->fabric_manager_package($source);
  die 'No Fabric Manager package is known for the '.$self->fabric_label.' on this host; the '
    ."driver is installed, Fabric Manager is not\n" unless defined $fm;
  my $version = $self->installed_driver_version($source);
  die 'Cannot read the installed NVIDIA driver version ('.( $version // 'nothing' ).'); '
    .'Fabric Manager must match it exactly, so none was installed. The driver is '
    ."installed, Fabric Manager is not\n"
    unless $self->_is_driver_version($version);
  Rex::Logger::info('  Installing NVIDIA Fabric Manager '.$fm.' '.$version.' ('.$self->fabric_label.')');
  $self->install_versioned_package($fm, $version);
  $self->verify_versioned_package($fm, $version);
  my $unit = $self->fabric_manager_service;
  $self->run_cmd('systemctl enable '.$unit, auto_die => 0);
  die 'systemctl enable '.$unit.' failed after installing '.$fm.' '.$version."\n"
    if $? != 0;
  return;
}


sub retrofit_fabric_manager {
  my ( $self ) = @_;
  return 0 unless $self->fabric_manager_needed;
  my $unit    = $self->fabric_manager_service;
  my $version = $self->loaded_driver_version;
  my @present = $self->installed_fabric_managers;
  if (@present) {
    my @other = grep { !defined $version || !defined $_->[1] || $_->[1] ne $version } @present;
    Rex::Logger::info($self->fabric_label.': Fabric Manager '.join(', ', map { $_->[0].' '.( $_->[1] // 'unknown' ) } @other)
      .' is installed, but the loaded NVIDIA driver is '.( $version // 'unknown' )
      .'. Fabric Manager must match the driver exactly or '.$unit.' refuses to start; '
      .'it is left as it is -- install the matching version yourself', 'warn')
      if @other;
    return 0;
  }
  my $fix = 'install NVIDIA Fabric Manager of exactly the loaded driver version yourself';
  unless ($self->_is_driver_version($version)) {
    Rex::Logger::info($self->fabric_label.' present and no Fabric Manager installed, but the loaded '
      .'driver version cannot be read (nvidia-smi --query-gpu=driver_version); nothing '
      .'was installed -- '.$fix, 'warn');
    return 0;
  }
  my ($branch) = $version =~ /^(\d+)\./;
  my ( %seen, @packages );
  for my $source ($self->sources) {
    my $fm = $self->fabric_manager_package({ %$source, branch => $branch });
    push @packages, $fm if defined $fm && !$seen{$fm}++;
  }
  unless (@packages) {
    Rex::Logger::info($self->fabric_label.' present and no Fabric Manager installed: no driver source '
      .'Rex::GPU knows on this '.$self->os.' host has a Fabric Manager package, so none is '
      .'installed for the loaded driver '.$version.' -- '.$fix, 'warn');
    return 0;
  }
  $self->refresh_package_index;
  my @why;
  for my $fm (@packages) {
    my $why = $self->fabric_manager_version_unavailable($fm, $version);
    if (defined $why) {
      push @why, $why;
      next;
    }
    Rex::Logger::info('  Installing NVIDIA Fabric Manager '.$fm.' '.$version
      .' for the already-installed driver ('.$self->fabric_label.')');
    $self->install_versioned_package($fm, $version);
    $self->verify_versioned_package($fm, $version);
    $self->run_cmd('systemctl enable '.$unit, auto_die => 0);
    die 'systemctl enable '.$unit.' failed after installing '.$fm.' '.$version
      ."; the driver is unchanged\n" if $? != 0;
    return 1;
  }
  Rex::Logger::info($self->fabric_label.' present and no Fabric Manager installed: the package sources '
    .'configured on this host offer none for the loaded driver '.$version.' ('
    .join('; ', @why).'). No package source was added and nothing was installed -- '
    .$fix, 'warn');
  return 0;
}

sub installed_fabric_managers { () }

sub loaded_driver_version {
  my ( $self ) = @_;
  my $out = $self->run_cmd('nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1',
    auto_die => 0);
  return if $? != 0 || !defined $out;
  my %v;
  $v{ s/^\s+|\s+$//gr } = 1 for grep { /\S/ } split /\n/, $out;
  return unless keys %v == 1;
  my ($version) = keys %v;
  return $self->_is_driver_version($version) ? $version : undef;
}

sub refresh_package_index { }

sub fabric_manager_version_unavailable {
  my ( $self, $pkg ) = @_;
  return ref($self).' cannot list the versions of '.$pkg.' its package sources offer';
}

# Pure: is this package name a Fabric Manager (nvidia-fabricmanager,
# nvidia-fabricmanager-580, the older nvidia-fabric-manager)? Not -dev or
# libnvidia-nscq.
sub _is_fabric_manager_name {
  my ( $self, $name ) = @_;
  return defined $name && $name =~ /\Anvidia-fabric-?manager(?:-\d+)?\z/ ? 1 : 0;
}

sub installed_driver_version {
  my ( $self ) = @_;
  die ref($self)." has no packaging layer to read the driver version from\n";
}

sub install_versioned_package {
  my ( $self ) = @_;
  die ref($self)." has no packaging layer to install Fabric Manager with\n";
}

sub verify_versioned_package {
  my ( $self ) = @_;
  die ref($self)." has no packaging layer to verify Fabric Manager with\n";
}

# Pure: an NVIDIA driver version, "580.95.05" / "570.211.01" -- two or three
# dot-separated numbers, nothing else.
sub _is_driver_version {
  my ( $self, $version ) = @_;
  return defined $version && $version =~ /\A\d+\.\d+(?:\.\d+)?\z/ ? 1 : 0;
}

# Pure: a source key's %s filled with the source's exact branch; undef when
# there is no key, or a %s and no exact branch.
sub _with_branch {
  my ( $self, $name, $source ) = @_;
  return unless defined $name;
  return $name unless $name =~ /%s/;
  return unless defined $source->{branch};
  ( my $filled = $name ) =~ s/%s/$source->{branch}/g;
  return $filled;
}

#### HGX B200/B300 NVLink fabric (karr #56) ###################################


sub nvlink_fabric_packages { () }

sub nvlink_fabric_unavailable {
  my ( $self ) = @_;
  return if $self->nvlink_fabric_packages;
  return ref($self).' knows no package source for the NVLink Subnet Manager (nvlsm)';
}

sub prepare_nvlink_fabric_source { }

sub install_nvlink_fabric {
  my ( $self, $plan ) = @_;
  $self->warn_nvlink_kernel;
  my @packages = $self->nvlink_fabric_packages;
  Rex::Logger::info('  HGX B200/B300: NVLink Subnet Manager and InfiniBand user space ('
    .join(', ', @packages).')');
  $self->prepare_nvlink_fabric_source($plan);
  $self->install_packages({ packages => [ @packages ] });
  $self->verify_packages({ verify => [ @packages ] });
  $self->load_ib_umad;
  return;
}

sub retrofit_nvlink_fabric {
  my ( $self ) = @_;
  $self->warn_nvlink_kernel;
  my @packages = $self->nvlink_fabric_packages;
  my @missing  = grep { !$self->_package_installed($_) } @packages;
  $self->run_cmd(q{lsmod | grep -q '^ib_umad '}, auto_die => 0);
  my $loaded = $? == 0;
  return 0 if !@missing && $loaded;
  if (@missing) {
    Rex::Logger::info('  HGX B200/B300: installing '.join(', ', @missing)
      .' for the already-installed driver, from the host\'s own package sources');
    $self->refresh_package_index;
    $self->install_packages({ packages => [ @missing ] });
    if (my @still = grep { !$self->_package_installed($_) } @missing) {
      Rex::Logger::info('HGX B200/B300: '.join(', ', @still).' not installed -- the package '
        .'sources configured on this host do not offer '.( @still == 1 ? 'it' : 'them' )
        .' (nvlsm comes from NVIDIA\'s CUDA repository). No package source was added; '
        .'without nvlsm CUDA fails with cudaErrorSystemNotReady -- install '
        .( @still == 1 ? 'it' : 'them' ).' yourself', 'warn');
    }
  }
  $self->load_ib_umad;
  return 1;
}

# Whether one of nvlink_fabric_packages is installed: verify_packages for it
# alone, which dies when it is not.
sub _package_installed {
  my ( $self, $pkg ) = @_;
  return eval { $self->verify_packages({ verify => [ $pkg ] }); 1 } ? 1 : 0;
}

sub load_ib_umad {
  my ( $self ) = @_;
  $self->file_cmd('/etc/modules-load.d/ib_umad.conf', content => "ib_umad\n");
  $self->run_cmd('modprobe ib_umad', auto_die => 0);
  Rex::Logger::info('modprobe ib_umad failed: the Fabric Manager start script needs the '
    .'module, so nvidia-fabricmanager.service will not start until it is loaded (on Ubuntu '
    .'it is in linux-modules-extra-'.( $self->kernel // '$(uname -r)' ).')', 'warn')
    if $? != 0;
  return;
}

sub nvlink_kernel_backported { 0 }

sub warn_nvlink_kernel {
  my ( $self ) = @_;
  return if $self->nvlink_kernel_backported;
  my $kernel = $self->kernel;
  my ( $major, $minor ) = ( $kernel // '' ) =~ /^(\d+)\.(\d+)/;
  if (!defined $major) {
    Rex::Logger::info('HGX B200/B300: cannot read the kernel version ('.( $kernel // 'nothing' )
      .'); NVIDIA requires kernel 5.17 or newer for the NVLink fabric', 'warn');
    return;
  }
  return if $major > 5 || ( $major == 5 && $minor >= 17 );
  Rex::Logger::info('HGX B200/B300: kernel '.$kernel.' is older than 5.17, which NVIDIA '
    .'requires for the NVLink 5 fabric (Fabric Manager user guide); Fabric Manager and nvlsm '
    .'may not come up on it. Boot a newer kernel -- on Ubuntu 22.04 the HWE kernel '
    .'(linux-generic-hwe-22.04). Rex::GPU does not change the kernel', 'warn');
  return;
}

sub fabric_state_poll { ( 12, 10 ) }

sub check_nvlink_fabric {
  my ( $self, $active ) = @_;
  my ( $reads, $seconds ) = $self->fabric_state_poll;
  my $want = scalar grep { ref $_ eq 'HASH' } @{ $self->gpus };
  my @states;
  for my $read (1 .. ( $active ? $reads : 1 )) {
    sleep $seconds if $read > 1 && $seconds;
    my $out = $self->run_cmd('nvidia-smi -q 2>&1', auto_die => 0);
    @states = $self->_fabric_states($out);
    if ($self->_fabric_complete($want, @states)) {
      Rex::Logger::info('  [ok] NVLink fabric: Fabric State Completed, Status Success on '
        .scalar(@states).' GPU'.( @states == 1 ? '' : 's' ));
      return 1;
    }
  }
  my $seen = @states
    ? join('; ', map { 'GPU '.$_.': '.( $states[$_]{state} // 'no State' ).' / '
        .( $states[$_]{status} // 'no Status' ) } 0 .. $#states)
    : 'no Fabric section';
  my $unit = $self->fabric_manager_service;
  Rex::Logger::info('HGX B200/B300: the NVLink fabric is not up -- nvidia-smi -q reports '
    .$seen.( $want > @states ? ' ('.$want.' GPUs expected)' : '' )
    .', not State Completed / Status Success on every GPU. CUDA jobs fail with '
    .'cudaErrorSystemNotReady until it is. Look at systemctl status '.$unit
    .', journalctl -u '.$unit.', /var/log/nvlsm.log, lsmod | grep ib_umad and the kernel '
    .'(5.17 or newer); after the first-deploy reboot check again with nvidia-smi -q', 'warn');
  return 0;
}

# Pure: every "Fabric" section of `nvidia-smi -q` output, in GPU order, as
# { state => ..., status => ... } (a key is missing when the section has no
# such line). The first State / Status inside the section count; a line
# indented no deeper than "Fabric" ends it.
sub _fabric_states {
  my ( $self, $out ) = @_;
  my ( @states, $cur, $indent );
  for my $line (split /\n/, $out // '') {
    next unless $line =~ /\S/;
    my $depth = length( ( $line =~ /^([ \t]*)/ )[0] );
    if ($line =~ /^[ \t]*Fabric[ \t]*$/) {
      $cur = {};
      $indent = $depth;
      push @states, $cur;
      next;
    }
    next unless $cur;
    if ($depth <= $indent) { undef $cur; next }
    if ($line =~ /^[ \t]*(State|Status)[ \t]*:[ \t]*(.*?)\s*$/) {
      $cur->{ lc $1 } //= $2;
    }
  }
  return @states;
}

# Pure: at least $want sections (and at least one), each Completed / Success.
sub _fabric_complete {
  my ( $self, $want, @states ) = @_;
  return 0 unless @states && @states >= $want;
  for my $s (@states) {
    return 0 unless ( $s->{state} // '' ) eq 'Completed' && ( $s->{status} // '' ) eq 'Success';
  }
  return 1;
}


sub prepare_host     { }
sub prepare_source   { }
sub install_packages { }
sub verify_packages  { }


sub post_install {
  my ( $self ) = @_;
  $self->file_cmd('/etc/modprobe.d/blacklist-nouveau.conf',
    content => "blacklist nouveau\noptions nouveau modeset=0\n");
  $self->run_cmd($self->initramfs_command, auto_die => 0);
}

sub initramfs_command { 'dracut --force 2>/dev/null' }

#### Pure helpers #############################################################
#
# Callable on the class as on an object, and with explicit arguments, because
# Rex::GPU::NVIDIA keeps some old private names as thin wrappers over them
# (t/ calls those).

# Given `nvidia-smi -L` output: is a working driver loaded? Every failure form
# (NVML init error, "No devices were found", "command not found") does not
# match.
sub _driver_present {
  my ( $self, $smi ) = @_;
  return 0 unless defined $smi;
  return $smi =~ /GPU \d+:/ ? 1 : 0;
}

# Die for a GPU no installable branch supports -- Kepler or older, max_branch
# 470. Maintainer decision (epic karr #25): reject loudly instead of
# installing the EOL 470 driver. Quiet for every other GPU, 580 included, and
# for anything that is not a GPU hashref.
sub _reject_unsupported_gpu {
  my ( $self, $gpu ) = @_;
  return unless $gpu && ref $gpu eq 'HASH';
  my $req = $self->requirement_class->from_gpu($gpu);
  return unless defined $req->max_branch && $req->max_branch < 580;
  die "NVIDIA GPU '" . ($gpu->{name} // 'unknown') . "' (10de:$gpu->{device_id}) is "
    . $req->generation." silicon: no driver newer than the end-of-life "
    . $req->max_branch." branch supports it, and Rex::GPU does not install "
    . "that. No driver package was installed and no package source was added. "
    . "Install the driver yourself; once "
    . "`nvidia-smi -L` lists the GPU and libcuda.so.1 is in the linker cache, "
    . "install_driver skips the driver step\n";
}

# Die for a vGPU guest device among the GPUs (karr #24): it needs NVIDIA's
# licensed vGPU guest driver, which no package source carries, and the open
# nvidia.ko of the datacenter packages refuses an Ampere+ vGPU function. With
# a non-vGPU GPU next to it both are named: one NVIDIA kernel module drives
# every GPU of the host, so the two drivers cannot both be installed. A GPU
# hash without vgpu (a caller that finds its GPUs itself) is not a vGPU.
sub _reject_vgpu_guest {
  my ( $self ) = @_;
  my @gpus = grep { ref $_ eq 'HASH' } @{ $self->gpus };
  my @vgpu = grep { $_->{vgpu} } @gpus;
  return unless @vgpu;
  my @other = grep { !$_->{vgpu} } @gpus;
  die join('; ', map {
      'NVIDIA vGPU guest (type '.( $_->{vgpu_type} // 'unknown' ).', 10de:'
        .( $_->{device_id} // '????' ).' sub '.( $_->{subsystem_id} // '????' ).')'
    } @vgpu)
    .( @other
      ? ' next to '.join(', ', map {
          "NVIDIA GPU '".( $_->{name} // 'unknown' )."' (10de:"
            .( $_->{device_id} // '????' ).', not a vGPU)'
        } @other)
        .': one NVIDIA kernel module drives every GPU of the host, and the '
        .'driver Rex::GPU installs does not drive a vGPU'
      : '' )
    .': install the licensed NVIDIA vGPU guest driver, then run again. '
    ."No driver package was installed and no package source was added\n";
}

# `uname -m` / dpkg arch -> the token NVIDIA's CUDA repos use under
# repos/<distro>/<arch>/: aarch64/arm64 are "sbsa", everything else (an empty
# string included) "x86_64". NOT the libnvidia-container toolkit repo's token,
# which is "aarch64" for the same machine.
sub _cuda_repo_arch {
  my ( $self, $machine ) = @_;
  $machine //= '';
  return 'sbsa' if $machine eq 'aarch64' || $machine eq 'arm64';
  return 'x86_64';
}

# Major version from a raw release string ("10.1" -> 10, "trixie/sid" -> 0).
# operating_system_version() strips the dots, so it is never the input.
sub _major_version {
  my ( $self, $release ) = @_;
  my ($major) = ($release // '') =~ /^(\d+)/;
  return ($major // 0) + 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::NVIDIA::Setup - Base class of the per-distro NVIDIA driver setups (experimental)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  package My::GPU::Setup;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';

  # one more step before the packages go in
  sub prepare_source {
    my ( $self, $plan ) = @_;
    $self->run_cmd('add-apt-repository -y ppa:my/mirror', auto_die => 0);
    $self->SUPER::prepare_source($plan);
  }

=head1 DESCRIPTION

B<Experimental.> The class layout, the step names, the source keys and the
C<$plan> keys may change in the next release without a deprecation cycle.
L<Rex::GPU::NVIDIA/install_driver> and L<Rex::GPU/gpu_setup> use a class of
your own when told to -- see L</WRITING YOUR OWN SETUP>.

One driver install is one object: the GPUs and the host facts it was built
with, and a fixed L</install> sequence of overridable steps. Which driver it
installs is not a per-distro special case but data: the GPUs'
L</requirement> against the ordered L</sources>, the first that fits wins
(L</select_source>). The per-distro
classes are L<Rex::GPU::NVIDIA::Setup::Debian> and
L<Rex::GPU::NVIDIA::Setup::Ubuntu> on the apt packaging layer
L<Rex::GPU::NVIDIA::Setup::Apt>, and L<Rex::GPU::NVIDIA::Setup::RHEL> and
L<Rex::GPU::NVIDIA::Setup::SUSE> on the rpm packaging layer
L<Rex::GPU::NVIDIA::Setup::Rpm>.

Every host interaction goes through L</run_cmd>, L</pkg_cmd> and
L</file_cmd>.

=head2 gpus

Arrayref of the GPUs this driver install is for. One driver has to drive
them all, so L</requirement> is the intersection of their requirements.
Empty (the default) keeps the GPU-agnostic package selection. Elements that
are not hashrefs are ignored.

Each GPU is a hashref; the elements L<Rex::GPU::Detect/detect> returns for
C<nvidia> fit, but only the keys below are read, so a caller that finds the GPU
another way (e.g. sysfs, without C<lspci>) passes just these:

  { device_id => '2b85', name => 'NVIDIA GeForce RTX 5090' }

=over

=item * C<device_id> -- the PCI device ID as four hex digits, without
C<0x> and without a trailing newline (C<2b85>; sysfs C<device> reads
C<0x2b85>). It is what the driver is chosen by
(L<Rex::GPU::NVIDIA::Requirement>): Kepler is refused, Blackwell gets the
open kernel module, Maxwell/Pascal/Volta the 580 branch. Any other defined
value croaks in C<new> (and in L</adopt>), before anything touches the
host -- it would otherwise silently count as an unknown GPU and lose those
guards. Leaving it out (or C<undef>, as detection does for an C<lspci> line
without C<[10de:XXXX]>) is accepted and means exactly that: an unknown GPU,
no constraint.

=item * C<name> -- for log lines and messages only. Optional.

=item * C<vgpu> -- true for an NVIDIA vGPU guest device
(L<Rex::GPU::Detect/NVIDIA vGPU guests>); C<vgpu_type> and C<subsystem_id>
go into the message. L</plan> dies for one, before anything on the host is
changed; L</already_installed> runs first, so a guest whose vGPU driver
already works is not refused. Missing (a caller that finds its GPUs itself)
means not a vGPU. Optional.

=back

C<compute>, C<pci_class> and C<vendor> are not read: whether a GPU gets a
driver at all is the caller's decision (L<Rex::GPU/gpu_setup> passes only
C<compute> ones).

=head2 gpu

A single GPU hashref, the older form of L</gpus>: C<< gpu => $g >> is the
same as C<< gpus => [ $g ] >>, C<< gpu => undef >> the same as no GPU.
Passing both croaks.

=head2 nvswitches

Arrayref of the host's NVSwitch chips, as L<Rex::GPU::Detect/detect>
returns them under C<nvswitch>; only whether there is one counts, no key is
read. Empty (the default): no Fabric Manager, nothing changes. Non-empty: the
driver source must name a Fabric Manager package (C<fabric_manager>, see
L</sources>) -- a source without one is rejected with that reason by
L</select_source> -- and L</install_fabric_manager> runs after the driver
packages are verified. On a host whose driver is already installed,
L<Rex::GPU::NVIDIA/install_driver> runs L</retrofit_fabric_manager>
instead. A caller that finds its GPUs without C<lspci> and passes none gets
no Fabric Manager.

=head2 fabric_manager_needed

True when L</nvswitches> lists at least one NVSwitch, or
L</nvlink_fabric_needed> (HGX B200/B300, whose NVSwitches are not on the
host PCI bus). Everything said above for a host with L</nvswitches> then
holds for it too.

=head2 fabric_label

What the Fabric Manager messages name as the reason: C<NVSwitch> on a host
with L</nvswitches>, C<HGX B200/B300 NVLink fabric> on one that only has
L</nvlink_fabric_needed>.

=head2 nvlink_platform_ids

  my %platform = $self->nvlink_platform_ids;   # device_id => platform

The GPUs that mark an NVLink platform, as a list of lowercase PCI device
IDs and the platform each one marks (karr #49; IDs from the supported-GPU
table of NVIDIA's open-gpu-kernel-modules README, driver 615):

=over

=item * C<hgx-nvlink5> -- HGX B200 (C<2901>, C<2909>) and B300 (C<3182>).
Their NVSwitches are not PCI devices on the host, so there are no
L</nvswitches>; CUDA needs NVIDIA Fabric Manager, the NVLink Subnet Manager
(C<nvlsm>), the InfiniBand user-space stack and kernel 5.17 or newer. It
makes L</nvlink_fabric_needed> true, so the driver comes with Fabric
Manager and L</install_nvlink_fabric> (karr #56).

=item * C<nvl72> -- GB200 (C<2941>) and GB300 (C<31c2>, C<31c3>) NVL72
compute trays: multi-node NVLink needs C<nvidia-imex>; Fabric Manager runs
on the NVLink switch trays, not here. Nothing is installed for them, the
driver choice does not depend on it; L<Rex::GPU::NVIDIA/install_driver>
logs a note.

=back

Override it to add or drop an ID. Read only by L</nvlink_platforms>.

=head2 nvlink_platforms

  my @platforms = $self->nvlink_platforms;   # ('hgx-nvlink5')

The platforms of L</nvlink_platform_ids> that L</gpus> mark, each once,
sorted; empty on every other host. Reads nothing from the host.

=head2 nvlink_fabric_needed

True when L</nvlink_platforms> contains C<hgx-nvlink5>.

=head2 requirement

The L<Rex::GPU::NVIDIA::Requirement> the driver has to meet: the
L<Rex::GPU::NVIDIA::Requirement/intersect> of every GPU in L</gpus>, looked
up through L</requirement_class>; C<either> with no bounds for no GPU. Built
on first use -- by L</plan> -- and B<dies> there, before anything on the
host is changed, when the GPUs need different kernel modules or no common
branch (a V100 next to a B200), naming the GPUs on each side. May be passed
to C<new> instead.

=head2 extra_requirement

  My::GPU::Setup->new(extra_requirement => { kernel_module => 'open', min_branch => 580 });

An additional constraint of your own, B<intersected> with what the GPUs
need -- the C<requirement> option of L<Rex::GPU::NVIDIA/install_driver> and
L<Rex::GPU/gpu_setup> ends up here. It can only tighten: a V100 stays
C<proprietary> and at most 580 whatever you ask for, and a constraint the
GPUs cannot meet (C<open> on a V100) makes L</plan> die before anything on
the host is changed, naming both sides. With no GPU it is the whole
requirement.

A hashref with the keys C<kernel_module>, C<min_branch>, C<max_branch> and
optionally C<name> (for messages; default C<the requirement option>), or a
L<Rex::GPU::NVIDIA::Requirement> object. A hashref becomes an object of
L</requirement_class> in C<new>, so an unknown key or a bad value croaks
there. C<undef> (the default) adds nothing.

=head2 requirement_class

The requirement class, C<Rex::GPU::NVIDIA::Requirement>. Override it to use
a subclass with rows of your own in its
L<generations|Rex::GPU::NVIDIA::Requirement/generations> table.

=head2 adopt

  $setup->adopt(gpus => \@gpus, extra_requirement => { min_branch => 580 });

What L<Rex::GPU::NVIDIA/install_driver> does to a setup B<object> passed as
C<setup>: it hands over the GPUs it was called with and its C<requirement>
option. C<gpus> is taken only if the object has none of its own (built
without C<gpu>/C<gpus>, or with an empty list) -- an object built for
specific GPUs keeps them. C<nvswitches> likewise, only if the object has
none. C<extra_requirement> (hashref or object, see
L</extra_requirement>) is set if given. Returns the object.

Croaks, before anything on the host is changed, if the object has already
run L</install> -- it caches the host facts (L</os>, L</kernel>, ...) of
that host, so one object serves one host -- or if it would have to change
an object whose L</requirement> is already fixed (passed to C<new>, or built
by an earlier L</plan>) -- the detected GPUs would otherwise not be checked
-- or if both the object and the option carry an C<extra_requirement>.

=head2 os

The OS name as L<Rex::Commands::Gather/operating_system> reports it
(C<Debian>, C<Ubuntu>, ...). Read from the host on first use unless passed
to C<new>.

=head2 release

The raw release string, L<Rex::Commands::Gather/operating_system_release>
(C<12.11>, C<13.1>, C<10.0>, C<trixie/sid>). Never
C<operating_system_version>, which strips the dots (C<10.1> becomes C<101>).
Read on first use unless passed to C<new>.

=head2 arch

The host architecture as the packaging layer names it. The base class reads
C<uname -m> (C<x86_64>, C<aarch64>); L<Rex::GPU::NVIDIA::Setup::Apt> reads
C<dpkg --print-architecture> (C<amd64>, C<arm64>). Read on first use unless
passed to C<new>.

=head2 kernel

The running kernel, C<uname -r>. Read on first use unless passed to C<new>.

=head2 run_cmd

  my $out = $self->run_cmd('uname -r');
  $self->run_cmd('modprobe nvidia', auto_die => 0);

The only way this class and its subclasses run a command on the host: the
arguments go to L<Rex::Commands::Run/run> unchanged, in the caller's
context, and C<$?> is left as C<run> set it. Override it to record or fake
the host in a test.

=head2 pkg_cmd

The only way to L<Rex::Commands::Pkg/pkg>. Reserved for inert helpers
(C<curl>, C<gnupg>, C<epel-release>): C<Rex::Pkg> dies on the non-zero exit
that DKMS builds, grub and initramfs regeneration return on success, so a
driver or toolkit package never goes through it.

=head2 file_cmd

The only way to L<Rex::Commands::File/file>.

=head2 install

  my $installed = $setup->install;

Runs the fixed sequence, each step a method a subclass can override:

  already_installed  -> return 0, nothing else runs
  plan               -> host-read-only; dies before any change
  prepare_host($plan)
  prepare_source($plan)
  resolve_plan($plan) -> fixes the packages; dies before any install
  install_packages($plan)
  verify_packages($plan)
  install_fabric_manager($plan)   -> only if fabric_manager_needed
  install_nvlink_fabric($plan)    -> only if nvlink_fabric_needed
  post_install($plan)

Returns C<1> after an install, C<0> if a working driver was already there.
Loading the module (C<modprobe nvidia>) or rebooting, and
L<Rex::GPU::NVIDIA/verify_nvidia_driver>, are done by
L<Rex::GPU::NVIDIA/install_driver> after this returns, not by the setup:
the reboot is a per-call option that needs Rex's live connection.

=head2 already_installed

True if a working NVIDIA driver with its CUDA user-space library is there:
C<nvidia-smi -L> lists a C<GPU N:> device B<and> C<libcuda.so.1> is in the
dynamic linker cache (L</libcuda_command>). Then nothing is installed,
nouveau is not blacklisted and the host is not rebooted, so a re-run, or a
host provisioned from NVIDIA's own repository, does not get a second,
conflicting driver.

The library probe runs only when C<nvidia-smi> lists a GPU. If it does and
C<libcuda.so.1> is missing -- the kernel module and C<nvidia-smi> are there,
but no CUDA program could run (e.g. Debian's C<nvidia-driver> installed
without recommends, which does not pull C<libcuda1>) -- a warning is logged
and the driver B<is installed>, over whatever is there: on a host whose
driver came from elsewhere (NVIDIA's CUDA repository, a C<.run> installer)
that is the distro driver next to it, and its install may fail with a
package conflict.

=head2 libcuda_command

The read-only probe L</already_installed> runs for the CUDA library,
C</sbin/ldconfig -p 2E<gt>/dev/null | grep -q '^[[:space:]]*libcuda\.so\.1 '>;
exit C<0> means present. The linker cache is where every distro's driver
packages register C<libcuda.so.1> (Debian through the C<nvidia> alternative
in the multiarch directory, Ubuntu C<libnvidia-compute-NNN>, RHEL
C<nvidia-driver-cuda-libs>, openSUSE C<nvidia-compute-G06>/C<G07>), whatever
the library directory, and it is what the loader of a CUDA program
consults. C</sbin/ldconfig> by path: C</sbin> is not on every login's
C<PATH>, and it exists on every supported release (a symlink to C</usr/sbin>
where C</usr> is merged). Matches the soname only, not C<libcudart> or
C<libcudadebugger>. Override it for a host that keeps the library elsewhere.

=head2 plan

  my $plan = $self->plan;

Decides what to install and returns it as a hashref: C<source> (the chosen
driver source, see L</sources>), C<packages> (arrayref, in install order:
L</kernel_packages>, then the source's) and C<verify> (the source's
packages that must be installed afterwards); a subclass adds keys for its
own later steps. A source whose packages are known only once its
repository is refreshed (see L</resolve_source>) has none here yet;
L</resolve_plan> adds them. Must only B<read> the host: every "this cannot
work here" that is known without a refreshed package index dies from here,
before anything is changed:

=over

=item * an NVIDIA vGPU guest device among the GPUs (see L</gpus>);

=item * a GPU no installable driver branch supports (Kepler or older, even
one among several GPUs);

=item * GPUs that cannot share one driver (L</requirement>);

=item * no source that fits the requirement (L</select_source>);

=item * on an HGX B200/B300 (L</nvlink_fabric_needed>): no known source for
the NVLink fabric packages (L</nvlink_fabric_unavailable>).

=back

A class without L</sources> (the base class) gets an empty plan.

=head2 kernel_packages

The packages the driver build needs before any source's: kernel headers.
None in the base class.

=head2 sources

  my @candidates = $self->sources;

The driver sources this setup can install from, B<in order of preference>.
Each is a hashref:

=over

=item * C<name> -- for log lines and messages.

=item * C<kernel_module> -- C<open> or C<proprietary>.

=item * C<branch> -- the exact driver branch it installs; or
C<branch_at_least> when it installs the newest branch its repository
carries, which is known only to be at least that one (see
L<Rex::GPU::NVIDIA::Requirement/satisfied_by> for how each counts); or
neither when the branch is unknown.

=item * C<packages>, C<verify> -- as in L</plan>. May be filled only by
L</resolve_source>, after the repository is refreshed.

=item * C<unavailable> -- a reason: this source does not exist on this host
(no repository for the release or architecture). Skipped with that reason.

=item * C<fabric_manager> -- the NVIDIA Fabric Manager package for this
source's driver, C<%s> standing for the exact branch
(C<nvidia-fabricmanager-%s>); and C<fabric_manager_match>, the package
whose installed version is the driver's (L</installed_driver_version>). A
source without C<fabric_manager> is rejected on a host with
L</nvswitches>.

=back

Plus whatever keys the class's later steps read. Host-read-only, like
L</plan>. Empty in the base class. Override it in a subclass to add,
reorder or drop candidates; C<< $self->SUPER::sources >> gives the built-in
ones.

=head2 select_source

  my $source = $self->select_source(@candidates);

The first candidate L</requirement> accepts
(L<Rex::GPU::NVIDIA::Requirement/satisfied_by>) on what it declares --
C<kernel_module>, C<branch> or C<branch_at_least>, C<unavailable>. Called
by L</plan>, so it must only read the host, and it does not look at a
package index: on a fresh host that index is stale or empty until
L</prepare_source> refreshes it. Dies when none fits, naming the GPUs, what
they need and every rejected candidate with its reason; no driver package
has been installed and no package source added then.

=head2 resolve_plan

  $self->resolve_plan($plan);

The step between L</prepare_source> and L</install_packages>: passes the
chosen source through L</resolve_source>, now that its repository is
refreshed, and checks the result against L</requirement> again. If
L</resolve_source> returned a new source, it goes into C<$plan>: C<source>,
C<packages> (the plan's other packages, then the resolved source's) and
C<verify>. Dies, before any driver package is installed, when the resolved
source is C<unavailable> or no longer fits, or -- on a host with
L</nvswitches> -- its Fabric Manager package has no exact name or no
installation candidate (L</fabric_manager_unavailable>); the source L</plan> chose is not
swapped for another candidate then. A plan without a source is left alone.

=head2 resolve_source

  my $resolved = $self->resolve_source($source);

Turns the chosen source into a concrete one, called by L</resolve_plan>
after L</prepare_source> has refreshed the package index. The base class
returns it unchanged (the same reference: nothing to do);
L<Rex::GPU::NVIDIA::Setup::Ubuntu> asks C<apt-cache search> for the newest
package and records its branch. Returns a new hashref with C<packages>,
C<verify> and, if known, the exact C<branch> -- or with C<unavailable> set
to the reason when the repository has nothing to install. May read the
host, must not change it. Override it to pick the package some other way (a
site index, C<ubuntu-drivers list>); L</resolve_plan> checks whatever it
returns against the requirement.

=head2 fabric_manager_package

  my $pkg = $self->fabric_manager_package($source);

The source's C<fabric_manager> with C<%s> replaced by its exact C<branch>;
C<undef> without C<fabric_manager>, or with C<%s> and no exact branch.

=head2 fabric_manager_unavailable

  my $why = $self->fabric_manager_unavailable($pkg);

Run by L</resolve_plan> after the package index is refreshed and before any
driver package is installed: a reason when the repository has no
installation candidate for C<$pkg>, C<undef> when it has one or this layer
cannot tell. C<undef> here and on the rpm layer; the apt layer asks
C<apt-cache policy>.

=head2 install_fabric_manager

  $self->install_fabric_manager($plan);

Runs after L</verify_packages> when L</fabric_manager_needed>: reads the
installed driver's version (L</installed_driver_version>), installs the
source's L</fabric_manager_package> at B<exactly> that upstream version
(L</install_versioned_package>) and checks it
(L</verify_versioned_package>), then C<systemctl enable> of
L</fabric_manager_service>. It is not started here: before the reboot that
unloads nouveau the NVIDIA module may not be bound, and Fabric Manager
aborts when the loaded driver does not match;
L<Rex::GPU::NVIDIA/install_driver> starts it after the C<modprobe>, or
checks it after the reboot, which starts the enabled unit. Dies -- the
driver is installed then, no Fabric Manager of another version is -- when
the driver version cannot be read, the repository has no Fabric Manager of
that version, it does not end up installed at that version, or the unit
cannot be enabled.

=head2 fabric_manager_service

C<nvidia-fabricmanager.service>.

=head2 installed_driver_version

  my $version = $self->installed_driver_version($source);   # "580.95.05"

The upstream version of the installed driver, read from the package the
source's C<fabric_manager_match> names (C<%s> = branch). Dies in the base
class; the packaging layers read C<dpkg-query> / C<rpm -q>.

=head2 install_versioned_package

  $self->install_versioned_package($pkg, $version);

Installs C<$pkg> at upstream version C<$version> through L</run_cmd>, never
L<Rex::Commands::Pkg/pkg>. Dies in the base class.

=head2 verify_versioned_package

  $self->verify_versioned_package($pkg, $version);

Dies unless C<$pkg> is installed at upstream version C<$version>. Dies in
the base class.

=head2 retrofit_fabric_manager

  my $installed = $setup->retrofit_fabric_manager;

For a host whose driver was B<already installed> (L</already_installed>)
and that has NVSwitches (L</fabric_manager_needed>) -- e.g. an HGX host
provisioned before Rex::GPU installed Fabric Manager. Returns C<1> after
installing Fabric Manager, C<0> otherwise; it never changes the driver or
the host's package sources. In this order:

=over

=item * L</loaded_driver_version>: the version of the driver that runs.

=item * L</installed_fabric_managers>: a Fabric Manager package is already
on the host -- nothing is installed or changed. If its version is not the
loaded driver's, it warns (the version change is the maintainer's).

=item * the loaded driver version is unreadable: warn, nothing installed.

=item * the Fabric Manager package names of L</sources> -- the same names a
fresh install uses (L</fabric_manager_package>), C<%s> filled with the
loaded driver's branch. None (openSUSE, Debian C<non-free> only): warn.

=item * L</refresh_package_index>, then per name
L</fabric_manager_version_unavailable>: whether the host's B<current>
package sources offer it at exactly the loaded driver's version. No
repository is added. The first one that does is installed with
L</install_versioned_package>, checked with L</verify_versioned_package>,
and L</fabric_manager_service> is enabled; a failure there dies (the driver
is untouched). None does: warn with each reason and the version needed.

=back

L<Rex::GPU::NVIDIA/install_driver> runs it and starts the unit after an
install.

=head2 installed_fabric_managers

  my @fm = $self->installed_fabric_managers;   # ([ 'nvidia-fabricmanager-580', '580.95.05' ])

The Fabric Manager packages on the host, whatever their version or branch,
each C<[ name, upstream version ]>. Empty in the base class.

=head2 loaded_driver_version

  my $version = $self->loaded_driver_version;   # "580.95.05"

The version of the driver that runs, from C<nvidia-smi
--query-gpu=driver_version>: what Fabric Manager must match. C<undef>
unless every GPU reports the same driver version.

=head2 refresh_package_index

Refreshes the package index before L</fabric_manager_version_unavailable>
is asked. Nothing in the base class and on the rpm layer (dnf refreshes
expired metadata itself, as for a fresh install); C<apt-get update> on the
apt layer.

=head2 fabric_manager_version_unavailable

  my $why = $self->fabric_manager_version_unavailable($pkg, $version);

C<undef> when the host's configured package sources offer C<$pkg> at
upstream version C<$version> and installing it removes nothing; a reason
otherwise. Host-read-only. The base class cannot tell and returns a reason.

=head2 nvlink_fabric_packages

The packages an HGX B200/B300 needs next to the driver and Fabric Manager,
installed B<unversioned> (the newest the sources offer, as NVIDIA's own
gpu-driver-container does: C<nvlsm> is versioned independently of the
driver): the NVLink Subnet Manager C<nvlsm> (from NVIDIA's CUDA
repository; it has no service of its own -- C<nvidia-fabricmanager.service>
starts it before Fabric Manager), C<infiniband-diags> (C<ibstat>, which the
Fabric Manager start script requires) and C<libibumad>. Empty in the base
class; the apt layer, L<Rex::GPU::NVIDIA::Setup::Ubuntu> and
L<Rex::GPU::NVIDIA::Setup::RHEL> fill it.

=head2 nvlink_fabric_unavailable

  my $why = $self->nvlink_fabric_unavailable($source);

Host-read-only, from L</plan> on an HGX B200/B300: a reason when this setup
knows no source for L</nvlink_fabric_packages> next to the chosen driver
C<$source>, C<undef> otherwise. L</plan> dies with it before anything is
changed. The base class returns a reason when there are no packages.

=head2 install_nvlink_fabric

  $self->install_nvlink_fabric($plan);

The step after L</install_fabric_manager> on an HGX B200/B300
(L</nvlink_fabric_needed>): L</warn_nvlink_kernel>, then
L</prepare_nvlink_fabric_source>, L</install_packages> and
L</verify_packages> of L</nvlink_fabric_packages> -- the same bypass of
C<Rex::Pkg> as the driver, a package not installed afterwards B<dies> (the
driver and Fabric Manager stay installed) -- and L</load_ib_umad>.

=head2 prepare_nvlink_fabric_source

  $self->prepare_nvlink_fabric_source($plan);

Makes L</nvlink_fabric_packages> installable. Nothing here: on Debian and
the RHEL family they come from the CUDA repository the driver came from.
L<Rex::GPU::NVIDIA::Setup::Ubuntu> adds NVIDIA's CUDA repository, pinned to
C<nvlsm> alone.

=head2 retrofit_nvlink_fabric

  my $installed = $setup->retrofit_nvlink_fabric;

For an HGX B200/B300 whose driver was B<already installed>, after
L</retrofit_fabric_manager>: L</warn_nvlink_kernel>; then the
L</nvlink_fabric_packages> that are not installed are installed from the
host's B<current> package sources (L</refresh_package_index> first) -- no
repository is added, the driver is not touched -- and L</load_ib_umad>.
Returns C<1> if it installed or loaded something, C<0> when everything was
there already (then nothing is changed). A package still missing afterwards
(e.g. C<nvlsm> on an Ubuntu host without NVIDIA's CUDA repository) only
warns, naming it.

=head2 load_ib_umad

Writes C</etc/modules-load.d/ib_umad.conf> (so the module is loaded on every
boot) and runs C<modprobe ib_umad>: the Fabric Manager start script aborts
unless C<ib_umad> is loaded. A failed C<modprobe> warns (on Ubuntu the
module is in C<linux-modules-extra-$kernel>), it does not die.

=head2 warn_nvlink_kernel

Warns when the running kernel (L</kernel>) is older than 5.17, which NVIDIA's
Fabric Manager guide requires for HGX B200/B300, unless
L</nvlink_kernel_backported>. Never stops anything: the kernel is not
changed by Rex::GPU.

=head2 nvlink_kernel_backported

True where the distribution supports HGX B200/B300 on an older kernel with
the needed patches backported, so L</warn_nvlink_kernel> stays quiet: the
RHEL family (NVIDIA lists RHEL 9.6/9.8 with kernel 5.14 for B200/B300).
False here.

=head2 check_nvlink_fabric

  my $ok = $setup->check_nvlink_fabric($fabric_manager_active);

Run by L<Rex::GPU::NVIDIA/install_driver> on an HGX B200/B300 after Fabric
Manager is started (or the host rebooted): reads C<nvidia-smi -q> and
expects every GPU's C<Fabric> section at C<State: Completed>,
C<Status: Success>. While it is not and C<$fabric_manager_active>, it reads
again, L</fabric_state_poll> times at most. Returns C<1> when the fabric is
up; otherwise it logs one loud warning with what it read and where to look,
and returns C<0>. It never dies, and it does not change the host.

=head2 fabric_state_poll

  my ( $reads, $seconds ) = $self->fabric_state_poll;   # (12, 10)

How often L</check_nvlink_fabric> reads C<nvidia-smi -q> while the fabric
registers, and the seconds between two reads.

=head2 prepare_host

Readies the host's own package manager.

=head2 prepare_source

Registers and refreshes the repository the driver comes from.

=head2 install_packages

Installs C<< $plan->{packages} >>.

=head2 verify_packages

Dies unless every package in C<< $plan->{verify} >> ended up installed. That
check, not the package manager's exit code, is the evidence of an install.

Each of these four takes the C<$plan> from L</plan> (completed by
L</resolve_plan> before L</install_packages>) and does nothing in the base
class; the packaging layer (L<Rex::GPU::NVIDIA::Setup::Apt>,
L<Rex::GPU::NVIDIA::Setup::Rpm>) and the distro classes fill them.

=head2 post_install

Blacklists C<nouveau> in C</etc/modprobe.d/blacklist-nouveau.conf> and runs
L</initramfs_command>, so the blacklist takes effect on the next boot.

=head2 initramfs_command

The command that regenerates the initramfs: C<dracut --force 2E<gt>/dev/null>
here (and so on the rpm layer), C<update-initramfs -u 2E<gt>/dev/null> in
L<Rex::GPU::NVIDIA::Setup::Apt>. Run with C<auto_die =E<gt> 0>.

=head1 WRITING YOUR OWN SETUP

A setup of your own is a Moo class that extends one of the built-in ones and
overrides what it needs to; nothing in Rex::GPU has to be patched. Put it in
your Rex project's C<lib/> directory -- Rex puts the C<lib/> next to the
Rexfile, and the one in the current directory, first on C<@INC> -- or write
the package straight into the Rexfile:

  my-project/
    Rexfile
    lib/My/GPU/Setup.pm

=head2 Adding a driver source

Override L</sources> and put your candidate first; C<SUPER::sources> keeps
the built-in ones behind it. The GPUs' L</requirement> still decides: a
source they cannot use is skipped with its reason, and the next one is
tried.

  package My::GPU::Setup;
  use Moo;
  use namespace::autoclean;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';

  sub sources {
    my ( $self ) = @_;
    return (
      {
        name            => 'pinned-580-open',
        kernel_module   => 'open',
        branch          => 580,
        packages        => [ 'nvidia-driver-580-server-open' ],
        verify          => [ 'nvidia-driver-580-server-open' ],
        check_candidate => 'nvidia-driver-580-server-open'
      },
      $self->SUPER::sources
    );
  }

  1;

An Ada or a B200 gets the pinned open driver; a V100 (proprietary only)
rejects it and gets the built-in C<nvidia-driver-580-server>.
C<check_candidate> is a key L<Rex::GPU::NVIDIA::Setup::Ubuntu> reads in its
C<resolve_source>, after C<apt-get update>; which extra keys a source may carry depends on the class
you extend.

=head2 Changing a step

Override the step and call C<SUPER::> for the built-in part. Reach the host
only through L</run_cmd> and L</file_cmd> (L</pkg_cmd> only for inert
helpers such as C<curl>): the driver packages are installed and verified by
the packaging layer's L</install_packages> and L</verify_packages>, never
through C<Rex::Pkg>, which dies on the non-zero exit a successful DKMS build
can return. L</plan> and everything it calls must only read the host.

  has apt_line => ( is => 'ro', predicate => 1 );

  # a local mirror, in before the inherited step runs `apt-get update`
  sub prepare_source {
    my ( $self, $plan ) = @_;
    $self->file_cmd('/etc/apt/sources.list.d/internal-nvidia.list',
      content => $self->apt_line."\n") if $self->has_apt_line;
    $self->SUPER::prepare_source($plan);
  }

=head2 Choosing the package another way

Override L</resolve_source>: it runs after C<apt-get update>, may read the
host but not change it, and whatever it returns is checked against the
requirement again. C<eg/ubuntu-drivers/> in the distribution asks
C<ubuntu-drivers list --gpgpu> (read-only) for the Ubuntu package instead
of C<apt-cache search>; the package it names is installed and verified by
the inherited steps, not by C<ubuntu-drivers install>:

  package My::GPU::UbuntuDrivers;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';

  sub resolve_source {
    my ( $self, $source ) = @_;
    return $self->SUPER::resolve_source($source) unless defined $source->{search};
    my $list = $self->run_cmd('ubuntu-drivers list --gpgpu 2>/dev/null', auto_die => 0);
    # ... pick the newest nvidia-driver-NNN-server(-open) line of the
    # source's kernel module flavour, then:
    my %resolved = ( %$source, packages => [ $pkg ], verify => [ $pkg ], branch => $branch );
    delete $resolved{branch_at_least};
    return \%resolved;   # or { %$source, unavailable => 'why' }
  }

=head2 Choosing it

First hit wins (L<Rex::GPU::NVIDIA/setup_for>):

  # 1. per call -- a class name, or an object with settings of its own
  gpu_setup(setup => 'My::GPU::Setup');
  gpu_setup(setup => My::GPU::Setup->new(apt_line => 'deb [...] http://... noble main'));

  # 2. for the whole Rexfile -- also reaches Rex::Rancher's gpu => 1
  set gpu_nvidia_setup => 'My::GPU::Setup';

  # 3. neither: Rex::GPU::NVIDIA->setup_class_for_os

The same C<setup> option works on L<Rex::GPU::NVIDIA/install_driver>. The
class is built with the detected GPUs (C<gpus>); an object gets them through
L</adopt> if it has none. A class extends one distro's setup, so it is for
hosts of that distro: to cover several, choose per host in the Rexfile, or
override L<Rex::GPU::NVIDIA/setup_class_for_os> in a subclass of
L<Rex::GPU::NVIDIA>.

To narrow the driver choice without a class, pass C<requirement> (see
L</extra_requirement>). To teach the GPU table a device, override
L</requirement_class> with a L<Rex::GPU::NVIDIA::Requirement> subclass that
adds rows to its C<generations>.

A runnable example: C<eg/custom-setup/> in the distribution.

=head1 SEE ALSO

L<Rex::GPU::NVIDIA>, L<Rex::GPU::NVIDIA::Requirement>

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
