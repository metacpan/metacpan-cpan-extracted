# ABSTRACT: AMD GPU driver (amdgpu) and ROCm management (experimental)

package Rex::GPU::AMD;
our $VERSION = '0.006';
use v5.14.4;
use warnings;

use Carp qw( croak );
use Rex::Commands::Run ();
use Rex::Config ();
use Rex::Logger;
use Scalar::Util qw( blessed );

use Rex::GPU::NVIDIA ();
use Rex::GPU::AMD::Hardware;
use Rex::GPU::AMD::Setup;
use Rex::GPU::AMD::Setup::Apt;
use Rex::GPU::AMD::Setup::Debian;
use Rex::GPU::AMD::Setup::RHEL;
use Rex::GPU::AMD::Setup::Ubuntu;

# karr k1. No Rex::Exporter: the functions are called fully qualified
# (Rex::GPU::AMD::install_driver(...), the contract with kubernetes-ocp) or
# as class methods, so a Rexfile that also uses Rex::GPU::NVIDIA keeps its
# install_driver.
#
# Every host command of this module and its setup classes goes through ONE
# method, host_run: a subclass that overrides it sees (and may refuse) every
# command, and the golden harness records them. Files are written with
# printf + mv over the exec channel, never through Rex's file commands: these
# hosts have no SFTP subsystem.

# True while Rex::GPU::gpu_setup runs install_driver (local there, k90): its
# die for GPUs whose rows disagree then names gpu_setup's ways out. Internal:
# no option, so install_driver -- a subclass's override included -- gets the
# arguments it always got from gpu_setup.
our $GPU_SETUP;

# The driver state, one read-only command with shell builtins only (a fork
# only per AMD device for its driver/render symlink). Lines:
#   amdgpu 0|1                  /sys/module/amdgpu exists
#   kfd 0|1                     /dev/kfd is a character device
#   pci SLOT CLASS DEVICE DRV   every vendor 0x1002 device of class 0x03xxxx
#                               or 0x1200xx; DRV the bound driver or "-"
#   vram SLOT BYTES / gtt SLOT BYTES   mem_info_vram_total / mem_info_gtt_total
#   render renderDN VENDOR SLOT every /sys/class/drm/renderD*
#   node N / prop KEY VALUE     KFD topology nodes, decimal properties
#   end                         the read got to its end
my $STATE_SCRIPT =
    q{[ -d /sys/module/amdgpu ] && echo 'amdgpu 1' || echo 'amdgpu 0'; }
  . q{[ -c /dev/kfd ] && echo 'kfd 1' || echo 'kfd 0'; }
  . q{for d in /sys/bus/pci/devices/*; do [ -r "$d/vendor" ] && [ -r "$d/class" ] || continue; }
  . q{read -r v < "$d/vendor"; [ "$v" = 0x1002 ] || continue; read -r c < "$d/class"; }
  . q{case $c in 0x03*|0x1200*) ;; *) continue;; esac; i=-; [ -r "$d/device" ] && read -r i < "$d/device"; }
  . q{r=-; [ -e "$d/driver" ] && r=$(cd -P "$d/driver" 2>/dev/null && echo "${PWD##*/}"); }
  . q{echo "pci ${d##*/} $c $i ${r:--}"; }
  . q{[ -r "$d/mem_info_vram_total" ] && read -r m < "$d/mem_info_vram_total" && echo "vram ${d##*/} $m"; }
  . q{[ -r "$d/mem_info_gtt_total" ] && read -r m < "$d/mem_info_gtt_total" && echo "gtt ${d##*/} $m"; }
  . q{done; }
  . q{for d in /sys/class/drm/renderD*; do [ -r "$d/device/vendor" ] || continue; read -r v < "$d/device/vendor"; }
  . q{s=$(cd -P "$d/device" 2>/dev/null && echo "${PWD##*/}"); echo "render ${d##*/} $v ${s:--}"; done; }
  . q{for n in /sys/class/kfd/kfd/topology/nodes/*; do [ -r "$n/properties" ] || continue; echo "node ${n##*/}"; }
  . q{while read -r k v; do case $k in gfx_target_version|vendor_id|device_id|location_id|domain|drm_render_minor) }
  . q{echo "prop $k $v";; esac; done < "$n/properties"; done; }
  . q{echo end};


sub install_driver {
  my $class = _invocant(@_) // return __PACKAGE__->configured_class->install_driver(@_);
  my ( undef, %opts ) = @_;
  $class->_check_options('install_driver', \%opts, qw( gpus method reboot ));
  my $method = $opts{method} // 'auto';
  die "install_driver: method must be 'auto', 'inbox' or 'dkms', not '$method'. "
    ."Nothing was changed on the host\n"
    unless $method =~ /\A(?:auto|inbox|dkms)\z/;
  my $gpus = $class->_check_gpus('install_driver', $opts{gpus});

  my $state = $class->read_state;
  die "install_driver: could not read the AMD driver state from the host (sysfs, KFD "
    ."topology). Nothing was changed on the host\n"
    unless $state;
  my @targets = $class->_targets($state, $gpus);
  die "install_driver: no AMD GPU found on the host (vendor 1002, PCI class 03xx or 1200 "
    ."under /sys/bus/pci/devices). Nothing was changed on the host\n"
    unless @targets;
  for my $missing (grep { $_->{missing} } @targets) {
    die 'install_driver: '.$class->gpu_label($missing).' is not on the host. '
      ."Nothing was changed on the host\n";
  }
  $class->_check_method($method, \@targets);

  # A working driver is never touched, whatever the method (karr k1): an
  # explicit method that is not the working driver's only gets a warning.
  unless ($class->state_problems($state, \@targets)) {
    if ($method ne 'auto') {
      my $source = $class->module_source // '';
      if ($source ne $method) {
        my $have = { inbox => 'inbox ', dkms => 'DKMS ' }->{$source} // '';
        Rex::Logger::info("install_driver: method => '$method' asked, but a working ${have}amdgpu "
          .'already drives the GPUs; install_driver never replaces a working driver. Nothing was '
          .'changed on the host', 'warn');
      }
    }
    Rex::Logger::info('AMD driver already active: '.join(', ', map { $class->gpu_label($_) } @targets));
    return 'present';
  }

  $class->_warn_inbox_for_dkms(\@targets) if $method eq 'inbox';
  my $setup = $class->setup_for(gpus => \@targets, state => $state);
  $method = $class->_auto_method(\@targets, $setup) if $method eq 'auto';
  Rex::Logger::info("Installing the AMD driver ($method) for "
    .join(', ', map { $class->gpu_label($_) } @targets));
  my $installed = $setup->install($method);
  return $class->_activate($method, \@targets, $state, $installed, $opts{reboot});
}

# Before the present check: method => 'dkms' for a GPU AMD supports only
# with the inbox driver dies, also on a host where the driver works.
sub _check_method {
  my ( $class, $method, $targets ) = @_;
  return unless $method eq 'dkms';
  my @inbox = grep { ( $_->{driver} // '' ) eq 'inbox' } @$targets;
  die "install_driver: method => 'dkms', but AMD supports "
    .join(', ', map { $class->gpu_label($_) } @inbox)
    ." only with the distribution kernel's inbox amdgpu, not amdgpu-dkms. "
    ."Nothing was changed on the host\n"
    if @inbox;
  return;
}

# After the present check, only when the inbox driver is really installed
# for a GPU AMD supports with amdgpu-dkms.
sub _warn_inbox_for_dkms {
  my ( $class, $targets ) = @_;
  Rex::Logger::info('  '.$class->gpu_label($_).": AMD supports it with amdgpu-dkms; using the "
    ."inbox driver as asked (method => 'inbox')", 'warn')
    for grep { ( $_->{driver} // '' ) eq 'dkms' } @$targets;
  return;
}

sub _auto_method {
  my ( $class, $targets, $setup ) = @_;
  my %by;
  push @{ $by{ $_->{driver} } }, $class->gpu_label($_) for grep { defined $_->{driver} } @$targets;
  $class->_die_mixed_drivers($setup, join(', ', @{ $by{inbox} }), join(', ', @{ $by{dkms} }),
    !grep { ( $_->{driver} // '' ) eq 'inbox' && !$_->{integrated} } @$targets)
    if $by{inbox} && $by{dkms};
  return 'inbox' if $by{inbox};
  return 'dkms'  if $by{dkms};
  my $method = $setup->fallback_method;
  Rex::Logger::info("  no hardware row says which driver AMD supports for these GPUs: $method "
    .( $method eq 'inbox' ? '(the running kernel has or can get amdgpu.ko)'
                          : '(the running kernel has no amdgpu.ko and cannot get one)' ));
  return $method;
}

# Rows that disagree under auto (karr k85): the way out it names must not
# die in turn. method => 'inbox' only where plan_inbox would let every GPU
# through (the same checks, host-read-only, in its order), else gpus => with
# the amdgpu-dkms GPUs only. On a host no driver may go to, that reason. A
# Radeon GPU outside AMD's matrix on this host (k82) is in both ways out --
# every GPU for inbox, and its row says dkms -- and both plans die for it:
# no way out is named, check_radeon dies as the plans would.
#
# Called from Rex::GPU::gpu_setup ($GPU_SETUP, k90), whose caller cannot pass
# method or gpus: its ways out first -- leaving out amd_integrated, only
# where that skips every inbox-only GPU ($apus: all of them integrated) --
# then install_driver called directly, with the hints above.
sub _die_mixed_drivers {
  my ( $class, $setup, $inbox, $dkms, $apus ) = @_;
  if (my $why = $setup->host_unsupported) {
    die 'install_driver: '.$why.". Nothing was changed on the host\n";
  }
  $setup->check_radeon;
  my $only = $setup->inbox_only_unsupported;
  my $all  = $only ? undef : $setup->inbox_unsupported;
  my $hint = ( $only ? "method => 'inbox' is no way out on this host for ".$inbox.': '.$only.'. '
             : $all  ? "method => 'inbox' is no way out on this host: ".$all.'. '
             :         "Pass method => 'inbox' to drive all of them with the inbox driver. " )
    .( $only || $all ? 'Pass gpus => with '.$dkms.' only to leave '.$inbox.' out. ' : '' );
  $hint = ( $apus ? "Leave out gpu_setup's amd_integrated => 1 to give the driver to ".$dkms
                    .' only; gpu_setup then skips '.$inbox.' with a warning. Or call'
                  : 'Call' )
    .' Rex::GPU::AMD->install_driver directly instead of gpu_setup: '.lcfirst($hint)
    if $GPU_SETUP;
  die 'install_driver: AMD supports '.$inbox.' only with the inbox driver and '.$dkms
    .' with amdgpu-dkms, and one amdgpu drives every GPU of a host. '.$hint
    ."Nothing was changed on the host\n";
}

# After the install: load the module if it was not loaded, else (or if that
# was not enough) reboot -- only with reboot => 1, else warn and return.
sub _activate {
  my ( $class, $method, $targets, $before, $installed, $reboot ) = @_;
  my $what = 'AMD driver ('.$method.') '.( $installed ? 'installed' : 'already installed' );
  my @problems;
  unless ($before->{amdgpu}) {
    $class->host_run('modprobe amdgpu');
    @problems = $class->state_problems($class->read_state, $targets);
    unless (@problems) {
      Rex::Logger::info($what.', amdgpu loaded and verified');
      return $method;
    }
  }
  unless ($reboot) {
    Rex::Logger::info($what.', not active yet'.( @problems ? ' ('.join('; ', @problems).')' : '' )
      .' -- reboot the host (or pass reboot => 1) to activate it', 'warn');
    return $method;
  }
  $class->reboot_and_wait;
  @problems = $class->state_problems($class->read_state, $targets);
  die $what.', but not usable after the reboot: '.join('; ', @problems)."\n" if @problems;
  Rex::Logger::info($what.' and verified after the reboot');
  return $method;
}


sub verify_amd {
  my $class = _invocant(@_) // return __PACKAGE__->configured_class->verify_amd(@_);
  my ( undef, %opts ) = @_;
  my $gpus = eval {
    $class->_check_options('verify_amd', \%opts, 'gpus');
    $class->_check_gpus('verify_amd', $opts{gpus});
  };
  unless ($gpus) {
    ( my $error = $@ ) =~ s/\s+\z//;
    $error =~ s/ Nothing was changed on the host\z//;
    Rex::Logger::info($error, 'warn');
    return { ok => 0, gpus => [] };
  }
  my $state = eval { $class->read_state };
  unless ($state) {
    Rex::Logger::info('verify_amd: could not read the AMD driver state from the host', 'warn');
    return { ok => 0, gpus => [] };
  }
  my @targets  = $class->_targets($state, $gpus);
  my @problems = $class->state_problems($state, \@targets);
  Rex::Logger::info('  AMD: '.$_, 'warn') for @problems;
  Rex::Logger::info(@problems ? 'AMD driver verification failed ('.scalar(@problems).' problem(s))'
    : 'AMD driver verified: '.join(', ', map { $class->gpu_label($_) } @targets));
  return {
    ok   => @problems ? 0 : 1,
    gpus => [ map {
      { slot       => $_->{slot},
        device_id  => $_->{device_id},
        gfx_target => $_->{gfx_target},
        vram_bytes => $_->{vram_bytes},
        gtt_bytes  => $_->{gtt_bytes},
        kfd_node   => $_->{kfd_nodes}[0],
        kfd_nodes  => [ @{ $_->{kfd_nodes} } ] }
    } @targets ],
  };
}


sub install_rocm {
  my $class = _invocant(@_) // return __PACKAGE__->configured_class->install_rocm(@_);
  my ( undef, %opts ) = @_;
  $class->_check_options('install_rocm', \%opts, qw( release gpus targets ));
  my $releases = $class->rocm_releases;
  my $known = join ', ', sort keys %$releases;
  die "install_rocm: release => '...' is required (known: $known). Nothing was changed on the host\n"
    unless defined $opts{release};
  my $rocm = $releases->{ $opts{release} }
    or die "install_rocm: unknown ROCm release '$opts{release}' (known: $known). "
      ."Nothing was changed on the host\n";
  die "install_rocm: pass gpus or targets, not both. Nothing was changed on the host\n"
    if defined $opts{gpus} && defined $opts{targets};

  my @targets;
  if (defined $opts{targets}) {
    die "install_rocm: targets must be an arrayref of gfx target names. Nothing was changed on the host\n"
      unless ref $opts{targets} eq 'ARRAY' && !grep { !defined $_ || ref $_ } @{ $opts{targets} };
    @targets = map { lc } @{ $opts{targets} };
  }
  elsif (defined $opts{gpus}) {
    for my $gpu (@{ $class->_check_gpus('install_rocm', $opts{gpus}) }) {
      die 'install_rocm: '.$class->gpu_label($gpu).' has no gfx_target; pass targets => [...]. '
        ."Nothing was changed on the host\n"
        unless defined $gpu->{gfx_target};
      push @targets, lc $gpu->{gfx_target};
    }
  }
  else {
    my $state = $class->read_state;
    @targets = map { $_->{gfx_target} } grep { defined $_->{gfx_target} } @{ $state ? $state->{nodes} : [] };
  }
  my %seen;
  @targets = grep { !$seen{$_}++ } @targets;
  die "install_rocm: no gfx target -- no AMD GPU with a running driver (KFD) found; pass "
    ."targets => [...]. Nothing was changed on the host\n"
    unless @targets;
  my %ships = map { $_ => 1 } @{ $rocm->{targets} };
  for my $gfx (@targets) {
    die "install_rocm: ROCm $rocm->{release} has no package for $gfx (it ships: "
      .join(' ', @{ $rocm->{targets} })."). Nothing was changed on the host\n"
      unless $ships{$gfx};
  }
  return $class->setup_for->install_rocm($rocm, \@targets);
}


sub rocm_releases {
  return {
    '10.1' => {
      release         => '10.1',
      package_prefix  => 'amdrocm10.1-',
      targets         => [qw( gfx908 gfx90a gfx942 gfx950 gfx1010 gfx1011 gfx1012
                              gfx1030 gfx1031 gfx1032 gfx1033 gfx1034 gfx1035 gfx1036
                              gfx1100 gfx1101 gfx1102 gfx1103 gfx1150 gfx1151 gfx1152 gfx1153
                              gfx1200 gfx1201 gfx1250 )],
      extra_packages  => [qw( libatomic1 libquadmath0 )],
      repo_url        => 'https://stable.repo.amd.com/rocm/core/packages/',
      key_url         => 'https://stable.repo.amd.com/rocm/gpg/packages.gpg',
      key_fingerprint => 'D0F004A0025A1145C7807FCD0701EAC4D5E02107',
    },
  };
}


sub state_script { $STATE_SCRIPT }

sub read_state {
  my ( $class ) = @_;
  my $out = $class->host_run($class->state_script);
  return $class->parse_state($out);
}

sub parse_state {
  my ( $class, $out ) = @_;
  return unless defined $out && $out =~ /^end\r?$/m;
  my %state = ( amdgpu => 0, kfd => 0, pci => [], render => [], nodes => [] );
  my ( %pci, $node );
  for my $line (split /\r?\n/, $out) {
    if ($line =~ /\A(amdgpu|kfd) ([01])\z/) {
      $state{$1} = $2;
    }
    elsif ($line =~ /\Apci (\S+) 0x([0-9a-f]{4})[0-9a-f]{2} (\S+) (\S+)\z/i) {
      my $slot = $class->normalize_slot($1) // next;
      my $dev = { slot => $slot, class => lc $2, device_id => _hex4($3),
                  bound_driver => ( $4 eq '-' ? undef : $4 ), vram_bytes => undef, gtt_bytes => undef };
      push @{ $state{pci} }, $dev;
      $pci{$slot} = $dev;
    }
    elsif ($line =~ /\A(vram|gtt) (\S+) (\d+)\z/) {
      my $dev = $pci{ $class->normalize_slot($2) // '' } or next;
      $dev->{$1.'_bytes'} = $3;
    }
    elsif ($line =~ /\Arender (renderD\d+) (\S+) (\S+)\z/) {
      push @{ $state{render} }, { name => $1, vendor => _hex4($2), slot => $class->normalize_slot($3) };
    }
    elsif ($line =~ /\Anode (\d+)\z/) {
      push @{ $state{nodes} }, $node = { id => $1 + 0 };
    }
    elsif ($node && $line =~ /\Aprop (\w+) (\d+)\z/) {
      $node->{$1} = $2 + 0;
    }
  }
  for my $n (@{ $state{nodes} }) {
    $n->{gfx_target} = $class->hardware_class->gfx_target_from_version($n->{gfx_target_version});
    $n->{vendor}     = sprintf '%04x', delete $n->{vendor_id} if defined $n->{vendor_id};
    $n->{device_id}  = sprintf '%04x', $n->{device_id} if defined $n->{device_id};
    # location_id = bus << 8 | devfn, both decimal in the topology
    $n->{slot} = sprintf '%04x:%02x:%02x.%x', $n->{domain} // 0, $n->{location_id} >> 8,
      ( $n->{location_id} & 0xff ) >> 3, $n->{location_id} & 7
      if defined $n->{location_id};
  }
  @{ $state{nodes} } = sort { $a->{id} <=> $b->{id} } @{ $state{nodes} };
  return \%state;
}


sub state_problems {
  my ( $class, $state, $gpus ) = @_;
  return ('the AMD driver state could not be read from the host') unless $state;
  my @problems;
  push @problems, 'the amdgpu kernel module is not loaded (no /sys/module/amdgpu)' unless $state->{amdgpu};
  push @problems, 'no /dev/kfd (the ROCm compute interface of amdgpu)' unless $state->{kfd};
  my @gpus = $gpus && @$gpus ? @$gpus : map { $class->_target($state, $_) } @{ $state->{pci} };
  push @problems, 'no AMD GPU found on the host' unless @gpus;
  for my $gpu (@gpus) {
    my $label = $class->gpu_label($gpu);
    if ($gpu->{missing}) {
      push @problems, $label.': not on the host';
      next;
    }
    push @problems, $label.': no KFD compute node (/sys/class/kfd/kfd/topology)'
      unless $class->kfd_nodes($state, $gpu);
    push @problems, $label.': no render node (/sys/class/drm/renderD*)'
      unless grep { ( $_->{vendor} // '' ) eq '1002' && defined $_->{slot} && $_->{slot} eq $gpu->{slot} }
        @{ $state->{render} };
  }
  return @problems;
}

sub kfd_nodes {
  my ( $class, $state, $gpu ) = @_;
  my $slot = $class->normalize_slot($gpu->{slot});
  my $id   = _hex4($gpu->{device_id});
  return grep {
    $_->{gfx_target_version}
      && ( defined $_->{slot} ? defined $slot && $_->{slot} eq $slot
                              : defined $id && ( $_->{device_id} // '' ) eq $id )
  } @{ $state->{nodes} };
}

# The GPUs a call is about, each resolved against the state: the given ones
# (matched by slot, else by device ID to a device not taken yet; one not on
# the host gets missing => 1), or every AMD GPU the state lists.
sub _targets {
  my ( $class, $state, $gpus ) = @_;
  return map { $class->_target($state, $_) } @{ $state->{pci} } unless @$gpus;
  my ( @targets, %taken );
  for my $gpu (@$gpus) {
    my $slot = $class->normalize_slot($gpu->{slot});
    my $id   = _hex4($gpu->{device_id});
    my ( $dev ) = grep {
      !$taken{ $_->{slot} }
        && ( defined $slot ? $_->{slot} eq $slot : ( $_->{device_id} // '' ) eq $id )
    } @{ $state->{pci} };
    unless ($dev) {
      push @targets, { name => $gpu->{name}, slot => $slot, device_id => $id, missing => 1,
                       kfd_nodes => [] };
      next;
    }
    $taken{ $dev->{slot} } = 1;
    push @targets, $class->_target($state, $dev, $gpu->{name});
  }
  return @targets;
}

sub _target {
  my ( $class, $state, $dev, $name ) = @_;
  my @nodes = $class->kfd_nodes($state, $dev);
  my $hw = $class->hardware_class->resolve(
    device_id      => $dev->{device_id},
    kfd_gfx_target => ( @nodes ? $nodes[0]{gfx_target} : undef ),
    name           => $name,
  );
  return {
    name         => $name,
    slot         => $dev->{slot},
    device_id    => $dev->{device_id},
    bound_driver => $dev->{bound_driver},
    vram_bytes   => $dev->{vram_bytes},
    gtt_bytes    => $dev->{gtt_bytes},
    kfd_nodes    => [ map { $_->{id} } @nodes ],
    %$hw,
  };
}


sub gpu_label {
  my ( $class, $gpu ) = @_;
  my $slot = $class->normalize_slot($gpu->{slot}) // $gpu->{slot};
  return join ' ', 'AMD GPU', ( defined $slot ? $slot : () ),
    '[1002:'.( _hex4($gpu->{device_id}) // '????' ).']',
    ( defined $gpu->{gfx_target} ? '('.$gpu->{gfx_target}.')' : () );
}


sub module_source {
  my ( $class, %arg ) = @_;
  my $kernel = $arg{kernel} // _trim($class->host_run('uname -r'));
  my $path = _trim($class->host_run('modinfo -n amdgpu 2>/dev/null'));
  return unless length $path && $path =~ m{\A/};
  return 'inbox' if $path =~ m{\A(?:/usr)?/lib/modules/\Q$kernel\E/kernel/};
  return 'dkms'  if $path =~ m{\A(?:/usr)?/lib/modules/\Q$kernel\E/(?:updates|extra)/};
  return 'other';
}


sub host_run {
  my ( $class, $command, %opt ) = @_;
  my $out = Rex::Commands::Run::run($command, auto_die => 0, %opt);
  return $out;
}


# /etc/os-release, not Rex::Commands::Gather: Rex reports the lsb_release
# names where lsb_release is installed (Rocky, RockyLinux, AlmaLinux, ... --
# karr #39), a release can come back with its dots in an unexpected form,
# and its probes are commands this module's host_run would not see. ID and
# VERSION_ID are the distribution's own, stable keys.
sub read_os_release {
  my ( $class ) = @_;
  my $out = $class->host_run('cat /etc/os-release 2>/dev/null');
  my %os;
  for my $line (split /\r?\n/, $out // '') {
    next unless $line =~ /\A([A-Z][A-Z0-9_]*)=(.*)\z/;
    my ( $key, $value ) = ( $1, $2 );
    $value =~ s/\s+\z//;
    $value = $1 if $value =~ /\A"(.*)"\z/ || $value =~ /\A'(.*)'\z/;
    $os{$key} = $value;
  }
  return \%os;
}


sub setup_class_for_os {
  my ( $class, $os ) = @_;
  my $id = lc( $os->{ID} // '' );
  return 'Rex::GPU::AMD::Setup::Ubuntu' if $id eq 'ubuntu';
  return 'Rex::GPU::AMD::Setup::Debian' if $id eq 'debian';
  return 'Rex::GPU::AMD::Setup::RHEL'   if $id =~ /\A(?:rhel|rocky|almalinux)\z/;
  return;
}

sub setup_for {
  my ( $class, %arg ) = @_;
  my $os = $class->read_os_release;
  my $setup = $class->setup_class_for_os($os)
    or die 'Unsupported OS for the AMD driver: '
      .( $os->{PRETTY_NAME} // $os->{ID} // 'unknown (no /etc/os-release)' )
      ." (supported: Ubuntu, Debian, RHEL, Rocky Linux, AlmaLinux). Nothing was changed on the host\n";
  return $setup->new(amd => $class, os_release => $os, %arg);
}


sub hardware_class { 'Rex::GPU::AMD::Hardware' }

# Always one value (undef included), also in the list of a hash constructor.
sub normalize_slot {
  my ( $class, $slot ) = @_;
  return defined $slot
    && $slot =~ /\A(?:([0-9a-f]{4,}):)?([0-9a-f]{2}):([0-9a-f]{2})\.([0-7])\z/i
    ? lc join('', $1 // '0000', ':', $2, ':', $3, '.', $4)
    : undef;
}


sub reboot_and_wait {
  my ( $class ) = @_;
  Rex::Logger::info('Rebooting host to activate the AMD driver...');
  my $boot_id = $class->_read_boot_id;
  Rex::Logger::info('  boot_id not readable before reboot, checking only that the host answers')
    unless length $boot_id;
  $class->host_run("nohup sh -c 'sleep 2 && shutdown -r now' >/dev/null 2>&1 &");
  sleep 20;
  my $conn = Rex::get_current_connection()->{conn};
  for my $i (1 .. 60) {
    eval { $conn->disconnect() };
    eval { $conn->reconnect() };
    unless ($@) {
      my $test = eval { $class->host_run('echo ok') };
      if (defined $test && $test =~ /^ok\r?$/m
          && ( !length $boot_id || $class->_new_boot_id($boot_id) )) {
        Rex::Logger::info('  Host is back online (after ~'.( $i * 5 + 20 ).'s)');
        return;
      }
    }
    Rex::Logger::info("  Waiting for host to come back... ($i/60)");
    sleep 5;
  }
  die "Host did not come back after reboot\n";
}

sub _new_boot_id {
  my ( $class, $old ) = @_;
  my $now = $class->_read_boot_id;
  return length $now && $now ne $old ? 1 : 0;
}

sub _read_boot_id {
  my ( $class ) = @_;
  my $out = eval { $class->host_run('cat /proc/sys/kernel/random/boot_id 2>/dev/null') };
  return '' unless defined $out;
  return $out =~ /^\s*([0-9a-fA-F-]{32,36})\s*$/m ? lc $1 : '';
}


sub configured_class {
  my ( $class, $amd ) = @_;
  my $origin = 'amd =>';
  unless (defined $amd && $amd ne '') {
    $amd = Rex::Config->get('gpu_amd_class');
    $origin = 'set gpu_amd_class';
    return __PACKAGE__ unless defined $amd && $amd ne '';
  }
  croak 'AMD class from '.$origin.' must be a class name, not '.$amd.'. Nothing was changed on the host'
    if ref $amd;
  return Rex::GPU::NVIDIA->load_user_class($amd,
    base => __PACKAGE__, what => 'AMD class', origin => $origin);
}

sub _check_options {
  my ( $class, $fn, $opts, @known ) = @_;
  my %known = map { $_ => 1 } @known;
  my @unknown = sort grep { !$known{$_} } keys %$opts;
  die "$fn: unknown option".( @unknown > 1 ? 's' : '' ).' '.join(', ', @unknown)
    .' (known: '.join(', ', @known)."). Nothing was changed on the host\n"
    if @unknown;
  return;
}

# gpus => undef or a non-empty arrayref of hashrefs, each with a valid slot
# or device_id. Returns the arrayref ([] for undef: every AMD GPU of the
# host). An explicit [] dies (karr k1): a caller that filtered every GPU out
# must not get all of them.
sub _check_gpus {
  my ( $class, $fn, $gpus ) = @_;
  return [] unless defined $gpus;
  die "$fn: gpus must be an arrayref of GPU hashrefs. Nothing was changed on the host\n"
    unless ref $gpus eq 'ARRAY' && !grep { ref $_ ne 'HASH' } @$gpus;
  die "$fn: gpus is empty; omit gpus for every AMD GPU of the host. Nothing was changed on the host\n"
    unless @$gpus;
  for my $gpu (@$gpus) {
    my $name = $gpu->{name} // 'a GPU';
    die "$fn: $name is vendor '$gpu->{vendor}', not amd. Nothing was changed on the host\n"
      if defined $gpu->{vendor} && $gpu->{vendor} ne 'amd';
    die "$fn: $name has neither a slot nor a device_id. Nothing was changed on the host\n"
      unless defined $gpu->{slot} || defined $gpu->{device_id};
    die "$fn: $name has a slot that is no PCI address: '$gpu->{slot}'. Nothing was changed on the host\n"
      if defined $gpu->{slot} && !defined $class->normalize_slot($gpu->{slot});
    die "$fn: $name has a device_id that is not four hex digits: '$gpu->{device_id}'. "
      ."Nothing was changed on the host\n"
      if defined $gpu->{device_id} && !defined _hex4($gpu->{device_id});
  }
  return $gpus;
}

# '0x1586' / '1586' => '1586'; anything else undef.
sub _hex4 {
  my ( $id ) = @_;
  return defined $id && $id =~ /\A(?:0x)?([0-9a-f]{4})\z/i ? lc $1 : undef;
}

sub _trim {
  my ( $text ) = @_;
  $text //= '';
  $text =~ s/\A\s+|\s+\z//g;
  return $text;
}

# As in Rex::GPU::NVIDIA: the invocant when called as a method on a class or
# object that isa Rex::GPU::AMD, undef when called as a function -- a first
# argument such as 'gpus' is no package of ours.
sub _invocant {
  my ( $first ) = @_;
  return unless defined $first && ( !ref $first || blessed $first );
  return $first if eval { $first->isa(__PACKAGE__) };
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::GPU::AMD - AMD GPU driver (amdgpu) and ROCm management (experimental)

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Rex -feature => ['1.4'];
  use Rex::GPU;
  use Rex::GPU::AMD;

  task 'setup', sub {
    # detect + driver; an integrated GPU (APU) only with amd_integrated => 1
    gpu_setup(containerd_config => 'none', amd_integrated => 1, reboot => 1);
  };

  task 'amd', sub {
    my @amd = grep { $_->{compute} } @{ gpu_detect()->{amd} };
    return unless @amd;   # gpus => [] dies; no gpus at all means every AMD GPU
    Rex::GPU::AMD::install_driver(gpus => \@amd, reboot => 1);   # 'present', 'inbox', 'dkms'
    my $check = Rex::GPU::AMD::verify_amd(gpus => \@amd);
    die "AMD driver not usable\n" unless $check->{ok};
    Rex::GPU::AMD::install_rocm(release => '10.1', gpus => \@amd);
  };

=head1 DESCRIPTION

B<Experimental.> The AMD half of L<Rex::GPU>: the C<amdgpu> kernel driver
-- the distribution kernel's own (I<inbox>) or AMD's C<amdgpu-dkms> -- and,
separately, AMD's ROCm Core SDK. Which driver AMD supports for a GPU comes
from L<Rex::GPU::AMD::Hardware> (by gfx target), which OS, release and
kernel from the setup classes (L<Rex::GPU::AMD::Setup> and its per-OS
subclasses).

Kubernetes needs nothing else from the host: the AMD device plugin finds
the GPUs through C</dev/kfd> and C</dev/dri/renderD*>; there is no
container runtime hook and no CDI step as for NVIDIA.

Every host command goes through L</host_run>, and the checks
(L</read_state>, L</verify_amd>, C<install_driver>'s C<present> path) are
read-only: C<install_driver> on a host with a working driver runs exactly
one command, the L</state_script>.

=head1 FUNCTIONS

B<Experimental.> Each function is also a class method:
C<Rex::GPU::AMD-E<gt>install_driver(...)> or C<My::GPU::AMD-E<gt>...> for a
subclass, with the same arguments. Called as a function
(C<Rex::GPU::AMD::install_driver(...)>) it runs as the class
L</configured_class> names (C<set gpu_amd_class>, or C<Rex::GPU::AMD>).
Nothing is exported: call them fully qualified.

=head2 install_driver

  my $how = Rex::GPU::AMD::install_driver(
    gpus   => \@amd,     # optional: AMD GPU hashrefs, e.g. from Rex::GPU::Detect
    method => 'auto',    # 'auto' (default), 'inbox' or 'dkms'
    reboot => 1,         # optional: reboot when the driver cannot take effect otherwise
  );
  # 'present', 'inbox' or 'dkms'

B<Experimental.> Makes the AMD kernel driver C<amdgpu> usable for ROCm on
the given GPUs and returns how:

=over

=item C<present> -- it already was: C</sys/module/amdgpu> exists,
C</dev/kfd> is a character device, and every GPU has a KFD topology node
with a C<gfx_target_version> other than C<0> and a
C</sys/class/drm/renderD*> node of vendor C<0x1002> at its PCI address.
That check is one read-only command (L</read_state>); nothing else runs, and
nothing is changed. A working driver is never replaced, whatever the
C<method>: an explicit C<inbox> or C<dkms> that is not the working driver's
kind is answered with C<present> and a warning (the two read-only commands
C<uname -r> and C<modinfo -n amdgpu> tell the kinds apart).

=item C<inbox> -- the distribution kernel's own C<amdgpu> was made usable:
only what is missing is installed (the firmware package if none of
L<Rex::GPU::AMD::Setup/firmware_packages> is installed, the module package
if the running kernel has no C<amdgpu.ko> -- where
L<Rex::GPU::AMD::Setup/inbox_module_packages> has none, as on Debian, it
dies before any change), nothing if nothing is missing. On Debian only on
12 and 13 with the release's own C<amd64> kernel, as C<dkms>.

=item C<dkms> -- AMD's C<amdgpu-dkms> 31.60 was installed from
C<repo.radeon.com> with the running kernel's headers, its signing key
checked against a pinned fingerprint, and its module verified to be built
for the running kernel (C<dkms status> and C<modinfo -n amdgpu>).

=back

C<gpus> is an arrayref of hashrefs, each with a C<slot> (PCI address,
C<95:00.0> or C<0000:95:00.0>) or a C<device_id> (four hex digits) or both;
C<name> is used in messages, a C<vendor> other than C<amd> is refused, every
other key is ignored. The elements L<Rex::GPU::Detect/detect> returns under
C<amd> fit as they are. Without C<gpus> every AMD GPU of the host is meant:
vendor C<1002>, PCI class C<03xx> or C<1200>, as read from
C</sys/bus/pci/devices>. An empty C<gpus =E<gt> []> is refused: omit
C<gpus> to mean every AMD GPU.

C<method =E<gt> 'auto'> follows L<Rex::GPU::AMD::Hardware>: the C<driver>
of each GPU's gfx target row (C<inbox> for the Ryzen APUs, which AMD
supports only with the inbox driver). GPUs whose rows disagree make it die
(one C<amdgpu> drives every GPU of a host), naming the way out:
C<method =E<gt> 'inbox'> only where the inbox driver is supported for all
of them on this host (neither L<Rex::GPU::AMD::Setup/inbox_only_unsupported>
nor L<Rex::GPU::AMD::Setup/inbox_unsupported> gives a reason), else that
reason and C<gpus> with only the C<amdgpu-dkms> ones -- on a Proxmox VE host
the Proxmox reason instead, and for a Radeon GPU AMD's matrix does not list
on this host (L<Rex::GPU::AMD::Setup/check_radeon>) the Radeon reason,
naming no way out: both would include it. Called from
L<Rex::GPU/gpu_setup>, which takes neither C<method> nor C<gpus>, the
message names its ways out instead: leaving out its C<amd_integrated>
(where that skips every GPU AMD supports only with the inbox driver), or
calling C<install_driver> directly, with the advice above. For GPUs without
a row it takes C<inbox> if the running kernel has an C<amdgpu.ko> or can
get one from the host's package sources, else C<dkms>.
C<method =E<gt> 'dkms'> for a GPU AMD supports only with the inbox driver
dies, also where the driver already works; C<method =E<gt> 'inbox'> for
one whose row says C<dkms> warns and goes ahead. C<install_driver> never
removes or replaces a driver.

Then -- also when nothing had to be installed -- C<amdgpu> is loaded with
C<modprobe amdgpu> if it was not loaded before. If it was, or if the GPUs
are still not usable, only a reboot can activate the driver: with
C<reboot =E<gt> 1> the host is rebooted and waited for (20 seconds, then up
to 60 reconnects 5 seconds apart, over 5 minutes in all, until C<echo ok>
answers from the new boot -- a changed C<boot_id>, where it was readable
before; it dies if the host does not come back, see L</reboot_and_wait>),
and the driver must then be usable or it dies; without it a warning says so
and the method is returned.

Dies -- B<before anything is changed on the host> -- for an unknown option,
a malformed or empty C<gpus>, a GPU that is not on the host, a host
without an AMD GPU, a state that could not be read; and, unless the driver
already works (C<present>), for an unsupported OS, a Proxmox VE host
(C<pve-firmware> installed; whatever the method), an unsupported release
or kernel for C<dkms>, for a GPU AMD supports only with the inbox driver,
for a Radeon GPU (hardware row C<matrix =E<gt> 'radeon'>) outside the
releases and kernels AMD's matrix lists for Radeon
(L<Rex::GPU::AMD::Setup/radeon_supported>: none on Debian, Ubuntu 26.04 GA
7.0, 24.04 HWE 7.0, 22.04 HWE 6.8, RHEL 10.2 and 9.8 with their kernel
build) whatever the method (this distribution's reading of the matrix),
and on Debian for C<inbox> too (the per-OS matrix is in
L<Rex::GPU::AMD::Setup::Ubuntu>, L<Rex::GPU::AMD::Setup::Debian> and
L<Rex::GPU::AMD::Setup::RHEL>; on Ubuntu and RHEL C<inbox> for any GPU
but these two kinds checks neither the release nor the kernel series; a
GPU whose row has no C<matrix> is not taken for a Radeon), a kernel command
line with C<nomodeset>, C<amdgpu.modeset=0> or a module
blacklist naming C<amdgpu>, an C<amdgpu> blacklist in C<modprobe.d>, a GPU
bound to another driver (C<vfio-pci>, C<radeon>), and, for C<dkms>, a
non-x86_64 host, Secure Boot enabled (the DKMS module would need a MOK
enrolled at the console), or an existing repository file of other content.
These messages end with C<Nothing was changed on the host>; called from
L<Rex::GPU/gpu_setup>, whose earlier steps may have changed the host
(C<pciutils>, the NVIDIA steps), they end with C<Nothing was changed for
the AMD GPU> (C<GPUs> for several) instead.
For C<dkms> it dies before any driver package is installed, but after the
apt timers are stopped (apt), in L<Rex::GPU::AMD::Setup/prepare_source>,
which puts AMD's repository in place: when a missing C<curl> or C<gpg> is
not installed after its install (apt: after an C<apt-get update>; the
other one may be installed by then); after that, when AMD's signing key
cannot be downloaded or is not the pinned one (the key file is left as it
was; only its directory is created if it was missing), or cannot be put in
place (on RHEL the key file may then be there, not C<rpm --import>ed); and,
with the key in place, when the repository file cannot be written.
Dies before any driver package is installed, but after the apt timers are
stopped and C<apt-get update> ran (apt) and, for C<dkms>, with C<curl> and
C<gpg> installed where they were missing and AMD's signing key and
repository file in place (a re-run accepts them), when a package the
install needs has no candidate -- neither installed nor offered by the
host's package sources: for C<dkms> the running kernel's headers (the
message then says to upgrade the kernel and reboot: usually the mirror has
moved on to a newer kernel than the running one) and C<amdgpu-dkms>; for
C<inbox> the module package or every firmware package; on RHEL also when
C<dnf repoquery> itself fails (metadata that cannot be downloaded). These
messages say C<No driver package was installed> (C<dkms>, and the failed
C<dnf repoquery>) or C<Nothing was installed> (C<inbox>); called from
L<Rex::GPU/gpu_setup>, whose NVIDIA steps may have installed their driver,
they say it C<for the AMD GPU> (C<GPUs> for several).
Dies after the install when a package is not installed afterwards (a failed
DKMS build leaves C<amdgpu-dkms> half-configured, so C<dpkg -l> does not show
it C<ii>; an RPM whose C<%post> build failed is caught by the C<dkms status>
check). For C<dkms> that message and the one for no module built name a
hold in the way of the install as the cause, with the way out
(L<Rex::GPU::AMD::Setup/hold_note>). On Debian and Ubuntu (C<apt-mark
hold>; C<apt-get install -y> does not change a held package, and aborts the
whole install where it would have to; way out C<apt-mark unhold>): a held
package of the install that is not installed or not at its candidate
version (C<apt-cache policy>), or a held C<amdgpu-dkms-firmware> that is not
installed; a hold at the candidate is not named. On RHEL (C<dnf
versionlock>; way out C<dnf versionlock delete>): a lock on C<amdgpu-dkms>,
or on a kernel header package or C<amdgpu-dkms-firmware> that is not
installed; without the versionlock plugin, or when its list cannot be read,
no lock is named. Asked only then: an install that went through runs no
extra command.

=head2 verify_amd

  my $result = Rex::GPU::AMD::verify_amd(gpus => \@amd);   # gpus optional
  # { ok   => 1,
  #   gpus => [ { slot       => '0000:95:00.0',
  #               device_id  => '1586',
  #               gfx_target => 'gfx1151',
  #               vram_bytes => '137438953472',
  #               gtt_bytes  => '33535848448',
  #               kfd_node   => 1,          # the lowest KFD node of the GPU
  #               kfd_nodes  => [ 1 ] } ] }

B<Experimental.> Checks, with the one read-only command of L</read_state>,
that the AMD driver is usable for ROCm on the given GPUs (all AMD GPUs of
the host without C<gpus>): C</sys/module/amdgpu>, C</dev/kfd> a character
device, and per GPU a KFD node with a C<gfx_target_version> other than C<0>
and a C</sys/class/drm/renderD*> node of vendor C<0x1002> at the GPU's PCI
address. C<gpus> as for L</install_driver>.

C<ok> is C<1> only if all of that holds. One entry per GPU, in the order
given (or of the PCI address): C<slot> with its domain, C<device_id> four
lowercase hex digits, C<gfx_target> from the GPU's lowest KFD node (the
device table without one), C<vram_bytes> and C<gtt_bytes> from the GPU's
C<mem_info_vram_total> / C<mem_info_gtt_total> (decimal strings), C<kfd_node>
the lowest KFD node ID and C<kfd_nodes> all of them (a partitioned MI300 has
several); C<undef> or C<[]> for what is not there. A GPU that is not on the
host has C<undef> everywhere but the C<slot> or C<device_id> it was given.

Never dies: every problem is logged as a warning and makes C<ok> C<0>, also
an unreadable state or a malformed C<gpus>. An empty C<gpus =E<gt> []>
warns and returns C<< { ok =E<gt> 0, gpus =E<gt> [] } >> -- omit C<gpus>
to check every AMD GPU.

=head2 install_rocm

  my $how = Rex::GPU::AMD::install_rocm(release => '10.1', gpus => \@amd);
  my $how = Rex::GPU::AMD::install_rocm(release => '10.1', targets => [ 'gfx1151' ]);
  my $how = Rex::GPU::AMD::install_rocm(release => '10.1');   # targets from the running driver
  # 'present' or 'installed'

B<Experimental.> Installs AMD's ROCm Core SDK of C<release> (required;
known: see L</rocm_releases>) for the given gfx targets from
C<stable.repo.amd.com>: per target the package C<amdrocm10.1-gfxNNNN>, plus
C<libatomic1> and C<libquadmath0> (AMD: some ROCm tools need them). The
targets come from C<targets> (gfx target names), else from each of C<gpus>'
C<gfx_target> (as L<Rex::GPU::Detect> sets it), else from the KFD nodes of
the running driver. Returns C<present> if every target's package is already
installed at that release (one read of C<dpkg-query>, nothing else changed),
C<installed> after the install. The repository key is checked against a
pinned fingerprint before apt trusts it.

apt hosts only: Ubuntu 22.04, 24.04, 26.04 and Debian 12, 13 on amd64.
Dies before anything is changed on the host for anything else, for a
release or target AMD ships no package for, for both C<gpus> and
C<targets>, for an empty C<gpus>, for a GPU without C<gfx_target>, when the old ROCm line is
installed (C<rocm-core>: AMD requires removing ROCm 7.2.4 or older first;
C<install_rocm> never uninstalls), for a Radeon or Ryzen APU target AMD's
matrix does not list for the host's release and kernel (below), and when
C</etc/apt/sources.list.d/amdrocm-stable.sources> exists with other
content. Dies after the install if a package is not installed, or not at
C<release>.

AMD's compatibility matrix binds the Radeon GPUs and the Ryzen APUs to
releases and kernels, and C<install_rocm> follows it as L</install_driver>
does. Unless every package is already installed (C<present>, checked
first), it dies before any change for a target whose L</hardware_class>
row says C<matrix =E<gt> 'radeon'> outside the releases and kernels of
L<Rex::GPU::AMD::Setup/radeon_unsupported> (Ubuntu 26.04 GA kernel 7.0,
24.04 HWE kernel 7.0, 22.04 HWE kernel 6.8, all C<-generic>; no Debian
release), then for one with C<matrix =E<gt> 'ryzen'> outside those of
L<Rex::GPU::AMD::Setup/inbox_only_unsupported> (Ubuntu 26.04 GA kernel 7.0
and 24.04 HWE kernel 7.0, C<-generic>; not 22.04, no Debian release),
reading the running kernel for it. The row is looked up by gfx target,
whether the targets came from C<targets>, C<gpus> or the KFD nodes. A
C<matrix =E<gt> 'instinct'> target needs nothing beyond the OS list above;
a target without C<matrix> -- no row (C<gfx1250>), a C<compute =E<gt> 0>
target (C<gfx1010>-C<gfx1012>, C<gfx1031>-C<gfx1036>), a row of your own
written without the field -- is not checked
(L<Rex::GPU::AMD::Setup/check_rocm_matrix>).

The driver is not part of it: run L</install_driver> first. On Proxmox VE
(C<pve-firmware> installed) that installs no driver -- only a working
C<amdgpu> passes it, as C<present> -- but C<install_rocm> is not refused
there and runs as on the Debian release the host reports itself as (so not
for a Radeon or Ryzen APU target, above): neither its packages nor what
apt pulls in with them include a firmware package, so nothing conflicts
with C<pve-firmware>.

=head2 rocm_releases

  my $releases = Rex::GPU::AMD->rocm_releases;   # { '10.1' => { ... } }

B<Experimental.> The ROCm releases L</install_rocm> knows, by release: the
gfx targets AMD ships a package for (C<amdrocm10.1-gfxNNNN>, read from the
repository's C<Packages> files of every supported OS on 2026-10-30), the
extra packages, the repository base URL and its signing key with the pinned
primary key fingerprint. Override it in a subclass to add a release.

=head2 read_state

  my $state = Rex::GPU::AMD->read_state;   # hashref, or undef if unreadable

B<Experimental.> Runs L</state_script> (one read-only command) and returns
L</parse_state> of its output.

=head2 state_script

The read-only shell command behind L</read_state>: shell builtins over
C</sys/module/amdgpu>, C</dev/kfd>, the vendor C<0x1002> display and
accelerator devices under C</sys/bus/pci/devices> (bound driver,
C<mem_info_vram_total>, C<mem_info_gtt_total>), C</sys/class/drm/renderD*>
and the KFD topology under C</sys/class/kfd/kfd/topology/nodes>.
L<Rex::GPU::Detect> runs it too, on hosts with an AMD GPU.

=head2 parse_state

  my $state = Rex::GPU::AMD->parse_state($output);

B<Experimental.> The output of L</state_script> as

  { amdgpu => 1, kfd => 1,
    pci    => [ { slot => '0000:95:00.0', class => '0380', device_id => '1586',
                  bound_driver => 'amdgpu', vram_bytes => '...', gtt_bytes => '...' } ],
    render => [ { name => 'renderD128', vendor => '1002', slot => '0000:95:00.0' } ],
    nodes  => [ { id => 1, gfx_target_version => 110501, gfx_target => 'gfx1151',
                  vendor => '1002', device_id => '1586', slot => '0000:95:00.0',
                  drm_render_minor => 128 } ] }

or C<undef> when the output does not end with the C<end> line (the read did
not complete). Lines it does not know are ignored; it never dies.

=head2 state_problems

  my @problems = Rex::GPU::AMD->state_problems($state, \@gpus);

B<Experimental.> What keeps the driver from being usable for C<@gpus>
(GPUs as L</install_driver> resolves them; all AMD GPUs of C<$state>
without), one message each; empty when it is usable. The check
L</install_driver> calls C<present> and L</verify_amd> C<ok>.

=head2 kfd_nodes

  my @nodes = Rex::GPU::AMD->kfd_nodes($state, $gpu);

B<Experimental.> The KFD GPU nodes (C<gfx_target_version> not C<0>) of one
GPU, lowest ID first: matched by PCI address (C<slot>), or by C<device_id>
for a node whose topology has no C<location_id>.

=head2 gpu_label

  Rex::GPU::AMD->gpu_label($gpu);   # 'AMD GPU 0000:95:00.0 [1002:1586] (gfx1151)'

B<Experimental.> How messages name a GPU hashref.

=head2 module_source

  my $source = Rex::GPU::AMD->module_source(kernel => '7.0.0-42-generic');

B<Experimental.> Where C<modinfo -n amdgpu> resolves the module for the
running kernel (C<uname -r> unless C<kernel> is given): C<inbox> under
C</lib/modules/KERNEL/kernel/>, C<dkms> under C<updates/> or C<extra/>,
C<other> elsewhere, C<undef> without a module. Read-only.

=head2 host_run

  my $out = $class->host_run($command, %run_options);

B<Experimental.> The one place every host command of L<Rex::GPU::AMD> and
its setup classes goes through: C<Rex::Commands::Run::run($command,
auto_die =E<gt> 0, %run_options)> in scalar context; C<$?> is left as
C<run> set it. Override it in a subclass to log, dry-run or refuse
commands.

=head2 read_os_release

  my $os = Rex::GPU::AMD->read_os_release;   # { ID => 'ubuntu', VERSION_ID => '24.04', ... }

B<Experimental.> C</etc/os-release> as a hashref of its keys, quotes
removed; C<{}> when it cannot be read.

=head2 setup_class_for_os

  my $setup = Rex::GPU::AMD->setup_class_for_os($os);   # class name or undef

B<Experimental.> The setup class for an L</read_os_release> hashref:
C<ID> C<ubuntu> L<Rex::GPU::AMD::Setup::Ubuntu>, C<debian>
L<Rex::GPU::AMD::Setup::Debian>, C<rhel>, C<rocky> or C<almalinux>
L<Rex::GPU::AMD::Setup::RHEL>; C<undef> for anything else. Override it in a
subclass to use a setup class of your own.

=head2 setup_for

  my $setup = Rex::GPU::AMD->setup_for(gpus => \@targets, state => $state);

B<Experimental.> Reads C</etc/os-release> and returns a new object of
L</setup_class_for_os>. Dies, before anything is changed on the host, for
an OS without a setup class.

=head2 hardware_class

B<Experimental.> The class L</install_driver> and L</verify_amd> ask for a
GPU's gfx target, C<compute>, C<integrated>, supported C<driver> and AMD
C<matrix> table, and L</install_rocm> for each target's C<matrix>:
L<Rex::GPU::AMD::Hardware>. Override it in a subclass to use your own rows.

=head2 normalize_slot

  Rex::GPU::AMD->normalize_slot('95:00.0');   # '0000:95:00.0'

B<Experimental.> A PCI address with its domain, lowercase; C<undef> for
anything that is not one -- always exactly one value, also in a list.

=head2 reboot_and_wait

B<Experimental.> Reboots the host (C<shutdown -r now>, two seconds after
the command returns) and waits for it: 20 seconds, then up to 60 times
every 5 seconds a reconnect and C<echo ok>, and the kernel's C<boot_id> must
differ from the one before (when it was readable). Dies C<Host did not come
back after reboot> after that. Every command through L</host_run>.

=head2 configured_class

  my $class = Rex::GPU::AMD->configured_class($amd_option);

B<Experimental.> The class a function call of L</install_driver>,
L</verify_amd> or L</install_rocm> is passed on to as a method:
C<$amd_option> (L<Rex::GPU/gpu_setup>'s C<amd> option) if defined, else
C<set gpu_amd_class =E<gt> 'My::GPU::AMD'> in the Rexfile, else
C<Rex::GPU::AMD>. Loaded by L<Rex::GPU::NVIDIA/load_user_class>; croaks,
before anything touches the host, for a class that is not a package name,
cannot be loaded or is not a subclass of C<Rex::GPU::AMD>.

=head1 SEE ALSO

L<Rex::GPU>, L<Rex::GPU::AMD::Hardware>, L<Rex::GPU::AMD::Setup>,
L<https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html>,
L<https://instinct.docs.amd.com/projects/amdgpu-docs/en/latest/>

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
