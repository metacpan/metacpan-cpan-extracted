use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Unit tests for the Setup classes (karr #31/#32, T2/T3 of epic #25):
# Rex::GPU::NVIDIA::Setup, ::Setup::Apt, ::Setup::Debian, ::Setup::Ubuntu,
# ::Setup::Rpm, ::Setup::RHEL, ::Setup::SUSE.
#
# CLAIMS:
#   * install runs its steps in the fixed order and stops after
#     already_installed when a driver works;
#   * plan only reads the host: for every Debian/Ubuntu/RHEL/Leap profile x
#     GPU it emits no mutating command (Golden.pm's read-only list), a
#     Blackwell on a Debian release without a CUDA repo dies inside plan, and
#     the RHEL plan does not read `uname -m` (it runs after EPEL/CRB);
#   * a failed pre-Turing module-stream enable dies before any dnf install;
#   * Ubuntu's plan does not read the apt index (karr #35): resolve_plan,
#     after apt-get update, picks the package, checks it against the
#     requirement again and dies on nothing found or a branch that does not
#     fit; a subclass can replace resolve_source and keep that check;
#   * facts passed to new() are not read from the host;
#   * run_cmd is the seam: a subclass that overrides it sees every command;
#   * a subclass overriding one step changes exactly that step;
#   * setup_class_for_os picks Debian / Ubuntu / RHEL / SUSE / none by OS,
#     and an OS without a class still probes nvidia-smi and rejects Kepler
#     before it dies.
# That install_driver still emits the same commands is t/96's job (goldens).
#
# NOT covered: anything a real host does with these commands -- none of this
# runs apt, dnf, zypper, rpm or a GPU.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host host_profile gpu_fixture mutating_lines working_driver );
use Rex::GPU::NVIDIA;

my $APT  = 'Rex::GPU::NVIDIA::Setup::Apt';
my $DEB  = 'Rex::GPU::NVIDIA::Setup::Debian';
my $UBU  = 'Rex::GPU::NVIDIA::Setup::Ubuntu';
my $RPM  = 'Rex::GPU::NVIDIA::Setup::Rpm';
my $RHEL = 'Rex::GPU::NVIDIA::Setup::RHEL';
my $SUSE = 'Rex::GPU::NVIDIA::Setup::SUSE';

#### Class layout

isa_ok($APT, 'Rex::GPU::NVIDIA::Setup');
isa_ok($DEB, $APT);
isa_ok($UBU, $APT);
isa_ok($RPM, 'Rex::GPU::NVIDIA::Setup');
isa_ok($RHEL, $RPM);
isa_ok($SUSE, $RPM);
is($RHEL->package_manager, 'dnf',    'RHEL installs with dnf');
is($SUSE->package_manager, 'zypper', 'SUSE installs with zypper');
# karr #53: zypper waits for the zypp lock like apt-get for the dpkg lock;
# the class-method call is the one install_container_toolkit makes.
is($RHEL->package_manager_command, 'dnf', 'RHEL runs dnf unprefixed');
is($SUSE->zypper, 'ZYPP_LOCK_TIMEOUT=120 zypper', 'SUSE zypper waits 120s for the zypp lock');
is($SUSE->package_manager_command, $SUSE->zypper, '... and installs with that invocation');
{
  package Local::SUSE::Patient;
  use parent -norequire, 'Rex::GPU::NVIDIA::Setup::SUSE';
  sub zypper_lock_timeout { 600 }
}
is(Local::SUSE::Patient->zypper, 'ZYPP_LOCK_TIMEOUT=600 zypper', '... overridable in a subclass');

#### setup_class_for_os

{
  my %want = (
    'debian-12'    => $DEB,
    'debian-13'    => $DEB,
    'ubuntu-24.04' => $UBU,
    'rocky-9'      => $RHEL,
    'rocky-10'     => $RHEL,
    'leap-15.6'    => $SUSE,
    'leap-16.0'    => $SUSE
  );
  for my $os (sort keys %want) {
    my $class;
    my $rec = record_host(host => host_profile($os),
      code => sub { $class = Rex::GPU::NVIDIA->setup_class_for_os });
    is($class, $want{$os}, "$os => ".($want{$os} // 'no Setup class'));
    is_deeply($rec->{lines}, [], "$os: resolving the class runs nothing");
  }
}

{
  my $class;
  my $rec = record_host(host => host_profile('debian-12', os => 'Gentoo'),
    code => sub { $class = Rex::GPU::NVIDIA->setup_class_for_os });
  is($class, undef, 'Gentoo => no Setup class');

  $rec = record_host(host => host_profile('debian-12', os => 'Gentoo'),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
  like($rec->{error}, qr/^Unsupported OS for NVIDIA driver installation: Gentoo$/,
    'install_driver on an OS without a class dies naming it');
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1', 'run(auto_die=default): uname -r' ],
    '... after only the probe and the kernel read, as before T3');

  $rec = record_host(host => host_profile('debian-12', os => 'Gentoo'),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('kepler')) });
  like($rec->{error}, qr/Kepler or older/, '... a Kepler still gets the Kepler message first');

  $rec = record_host(host => host_profile('debian-12', os => 'Gentoo', responses => [ working_driver() ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
  is($rec->{error}, undef, '... and a working driver still short-circuits without dying');
}

#### plan only reads the host

for my $os (qw( debian-12 debian-13 ubuntu-22.04 ubuntu-24.04 )) {
  my $class = $os =~ /^ubuntu/ ? $UBU : $DEB;
  for my $g (qw( ada blackwell volta none )) {
    my $plan;
    my $rec = record_host(host => host_profile($os),
      code => sub { $plan = $class->new(gpu => gpu_fixture($g))->plan });
    is($rec->{error}, undef, "$os + $g: plan lives");
    is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], "$os + $g: plan emits only read-only probes");
    # karr #35: Ubuntu's -server/-server-open sources are resolved from the
    # package index only after apt-get update (resolve_plan), so their plan
    # has the kernel headers and no driver package yet -- and plan must not
    # read the (possibly stale) index at all.
    if ($plan->{source}{search}) {
      is_deeply([ grep { /apt-cache/ } @{ $rec->{lines} } ], [], "$os + $g: plan does not read the apt index");
      is_deeply($plan->{verify}, [], "$os + $g: driver package left to resolve_plan");
      is_deeply([ grep { !/^linux-headers-/ } @{ $plan->{packages} } ], [],
        "$os + $g: plan packages are the kernel headers only");
    }
    else {
      ok(@{ $plan->{packages} } && @{ $plan->{verify} }, "$os + $g: packages and verify filled");
    }
  }
}

for my $os (qw( rocky-9 rocky-10 leap-15.6 leap-16.0 )) {
  my $class = $os =~ /^rocky/ ? $RHEL : $SUSE;
  for my $g (qw( ada blackwell volta none )) {
    my $plan;
    my $rec = record_host(host => host_profile($os),
      code => sub { $plan = $class->new(gpu => gpu_fixture($g))->plan });
    is($rec->{error}, undef, "$os + $g: plan lives");
    is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], "$os + $g: plan emits only read-only probes");
    is_deeply([ grep { /uname -m/ } @{ $rec->{lines} } ], [], "$os + $g: plan does not read the arch");
    ok(scalar @{ $plan->{packages} }, "$os + $g: packages filled");
    if ($class eq $SUSE) {
      # every source verifies its meta package and the kmp it requires (karr #27)
      my $meta = $g eq 'volta' ? 'nvidia-driver-G06-kmp-meta'
        : $os eq 'leap-16.0' ? 'nvidia-open-driver-G07-signed-kmp-meta'
        : 'nvidia-open-driver-G06-signed-kmp-meta';
      (my $kmp = $meta) =~ s/-meta$//;
      is_deeply($plan->{verify}, [ $meta, $kmp ], "$os + $g: meta package and its kmp verified");
    }
    else {
      is($plan->{verify}[0], 'nvidia-driver', "$os + $g: nvidia-driver verified");
    }
  }
}

{
  my $plan;
  record_host(host => host_profile('rocky-9'),
    code => sub { $plan = $RHEL->new(gpu => gpu_fixture('volta'))->plan });
  is_deeply($plan->{verify}, [ 'nvidia-driver', 'kmod-nvidia-latest-dkms' ],
    'rocky-9 + V100: the proprietary kmod is verified too');
  is($plan->{source}{module_stream}, '580-dkms', '... stream 580-dkms decided in plan');

  my $rec = record_host(host => host_profile('rocky-9'), code => sub {
    $plan = $RHEL->new(os => 'Redhat', release => '8.10', kernel => '4.18.0-553.el8_10.x86_64',
      os_release => { ID => 'rocky' })->plan;
  });
  is_deeply($rec->{lines}, [], 'RHEL 8, facts given to new(): plan reads nothing from the host');
  is_deeply($plan->{packages},
    [ 'kernel-devel-4.18.0-553.el8_10.x86_64', 'kernel-headers', 'nvidia-open' ],
    'RHEL 8: running-kernel devel package, nvidia-open');
}

{
  # Pre-Turing on RHEL 9, module stream enable fails: dies in prepare_source,
  # before any driver package is installed.
  my $rec = record_host(host => host_profile('rocky-9', responses => [
      [ 'dnf module enable nvidia-driver:580-dkms -y' => 'Error: conflicting stream', 1 ]
    ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('volta')) });
  like($rec->{error}, qr/dnf module enable nvidia-driver:580-dkms failed/,
    'rocky-9 + V100, stream enable fails: dies');
  is_deeply([ grep { /dnf install/ } @{ $rec->{lines} } ], [], '... before any dnf install');
}

{
  my $rec = record_host(host => host_profile('debian-12', release => '11.11'),
    code => sub { $DEB->new(gpu => gpu_fixture('blackwell'))->plan });
  like($rec->{error}, qr/CUDA repo only covers Debian 12 and 13/, 'debian-11 + Blackwell dies in plan');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... before any change');

  $rec = record_host(host => host_profile('debian-12'),
    code => sub { $DEB->new(gpu => gpu_fixture('kepler'))->plan });
  like($rec->{error}, qr/Kepler or older.*No driver package was installed and no package source was added/, 'Kepler dies in plan');
  is_deeply($rec->{lines}, [], '... before any host interaction');
}

#### Injected facts are not read

{
  my $plan;
  my $rec = record_host(host => host_profile('debian-12'), code => sub {
    $plan = $DEB->new(gpu => gpu_fixture('blackwell'), os => 'Debian',
      release => '13.1', arch => 'arm64', kernel => '6.12.0-test')->plan;
  });
  is_deeply($rec->{lines}, [], 'facts given to new(): plan reads nothing from the host');
  is($plan->{cuda_repo}{distro}, 'debian13', 'injected release decides the CUDA repo');
  is($plan->{cuda_repo}{arch},   'sbsa',     'injected arch decides the repo arch');
  is_deeply($plan->{packages},
    [ 'linux-headers-6.12.0-test', 'nvidia-driver-cuda', 'nvidia-kernel-open-dkms' ],
    'injected kernel names the headers');
}

#### run_cmd is the seam (no harness)

{
  package My::FakeHost;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';
  has seen => ( is => 'ro', default => sub { [] } );
  sub run_cmd {
    my ( $self, $cmd ) = @_;
    push @{ $self->seen }, $cmd;
    $? = 0;
    return $cmd =~ /^apt-cache search .*-server\$'/ ? 'nvidia-driver-595-server' : '';
  }
}

{
  no warnings 'redefine';
  local *Rex::Logger::info = sub { };
  my $s = My::FakeHost->new(os => 'Ubuntu', release => '24.04', arch => 'amd64', kernel => '6.8.0-1');
  my $plan = $s->plan;
  is(scalar @{ $s->seen }, 0, 'plan ran no command: the apt index is not read before apt-get update (karr #35)');
  is($plan->{source}{name}, 'ubuntu-server', '... but the source is chosen');
  $s->resolve_plan($plan);
  is_deeply($plan->{packages},
    [ 'linux-headers-6.8.0-1', 'linux-headers-generic', 'nvidia-driver-595-server' ],
    'overridden run_cmd feeds the apt-cache search in resolve_plan');
  is_deeply($plan->{verify}, [ 'nvidia-driver-595-server' ], 'the chosen driver is verified');
  is($plan->{source}{branch}, 595, 'the exact branch is recorded');
  is(scalar @{ $s->seen }, 1, 'resolve_plan ran exactly one command through run_cmd');
  like($s->seen->[0], qr/^apt-cache search /, '... the search');
}

#### resolve_plan: what the refreshed index offers is checked again (karr #35)

{
  package My::Index;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';
  has answer => ( is => 'ro', default => '' );
  # apt-cache policy: a B300 is an HGX B200/B300 host since karr #56, so
  # resolve_plan also asks for its Fabric Manager's candidate
  sub run_cmd {
    my ( $self, $cmd ) = @_;
    $? = 0;
    return $cmd =~ /^apt-cache search / ? $self->answer
      : $cmd =~ /apt-cache policy (\S+)/ ? "$1:\n  Installed: (none)\n  Candidate: 1.0-1\n"
      : '';
  }

  # the shape an `ubuntu-drivers list` based setup (karr #42) would take:
  # only the package choice is replaced, the requirement check stays
  package My::Chooser;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';
  has pick => ( is => 'ro' );
  sub run_cmd { $? = 0; return '' }
  sub resolve_source {
    my ( $self, $source ) = @_;
    my ($branch) = $self->pick =~ /-(\d+)-/;
    return { %$source, packages => [ $self->pick ], verify => [ $self->pick ], branch => $branch };
  }

  package My::Static;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';
  sub run_cmd { $? = 0; return '' }
  sub resolve_source { my ( $self, $source ) = @_; return $source }
}

{
  no warnings 'redefine';
  local *Rex::Logger::info = sub { };
  my %facts = ( os => 'Ubuntu', release => '24.04', arch => 'amd64', kernel => '6.8.0-1' );

  my $s = My::Index->new(%facts, gpu => gpu_fixture('ada'));
  my $plan = $s->plan;
  my @before = @{ $plan->{packages} };
  ok(!eval { $s->resolve_plan($plan); 1 }, 'empty search after apt-get update dies (no 570 fallback)');
  like($@, qr/^The NVIDIA driver source ubuntu-server chosen for .* has nothing to install on this Ubuntu 24\.04 host: apt-cache search '\^nvidia-driver-\[0-9\]\.\*-server\$' finds no package after apt-get update.*No driver package was installed/,
    '... naming the source, the search and that nothing was installed');
  is_deeply($plan->{packages}, \@before, '... and the plan is left as it was');

  $s = My::Index->new(%facts, gpu => gpu_fixture('b300'), answer => 'nvidia-driver-570-server-open');
  $plan = $s->plan;
  is($plan->{source}{name}, 'ubuntu-server-open', 'B300 plans -server-open (at least 580 claimed)');
  ok(!eval { $s->resolve_plan($plan); 1 }, 'the index only has 570: dies');
  like($@, qr/ubuntu-server-open chosen for .*: branch 570 is older than 580\./, '... with the requirement reason');

  $s = My::Index->new(%facts, gpu => gpu_fixture('b300'), answer => 'nvidia-driver-590-server-open');
  $plan = $s->plan;
  $s->resolve_plan($plan);
  is_deeply($plan->{verify}, [ 'nvidia-driver-590-server-open' ], 'the index has 590: taken');

  $s = My::Chooser->new(%facts, gpu => gpu_fixture('ada'), pick => 'nvidia-driver-590-server');
  $plan = $s->plan;
  $s->resolve_plan($plan);
  is_deeply($plan->{packages}, [ 'linux-headers-6.8.0-1', 'linux-headers-generic', 'nvidia-driver-590-server' ],
    'a subclass replacing resolve_source picks the package');

  $s = My::Chooser->new(%facts, gpu => gpu_fixture('volta'), pick => 'nvidia-driver-590-server');
  $plan = $s->plan;
  ok(!eval { $s->resolve_plan($plan); 1 }, '... and a pick the GPU cannot use still dies');
  like($@, qr/branch 590 is newer than 580/, '... with the requirement reason');

  # a source that is final at plan time (the base resolve_source) is untouched
  $s = My::Static->new(%facts, gpu => gpu_fixture('volta'));
  $plan = $s->plan;
  my $source = $plan->{source};
  $s->resolve_plan($plan);
  is($plan->{source}, $source, 'unchanged source: the same reference stays in the plan');
  is_deeply($plan->{packages}, [ 'linux-headers-6.8.0-1', 'linux-headers-generic', 'nvidia-driver-580-server' ],
    '... with the packages plan gave it');
}

#### Step order and the already-installed short-circuit

{
  package My::Steps;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup';
  has log       => ( is => 'ro', default => sub { [] } );
  has installed => ( is => 'ro', default => 0 );
  sub already_installed { my ( $s ) = @_; push @{ $s->log }, 'already_installed'; $s->installed }
  for my $step (qw( prepare_host prepare_source resolve_plan install_packages verify_packages post_install )) {
    no strict 'refs';
    *{$step} = sub { my ( $s, $plan ) = @_; push @{ $s->log }, $step.'('.$plan->{tag}.')' };
  }
  sub plan { my ( $s ) = @_; push @{ $s->log }, 'plan'; return { tag => 'p' } }
}

{
  my $s = My::Steps->new;
  is($s->install, 1, 'install returns 1 after an install');
  is_deeply($s->log, [ 'already_installed', 'plan', 'prepare_host(p)', 'prepare_source(p)',
    'resolve_plan(p)', 'install_packages(p)', 'verify_packages(p)', 'post_install(p)' ],
    'steps run in the fixed order, each handed the plan');

  $s = My::Steps->new(installed => 1);
  is($s->install, 0, 'install returns 0 when a driver already works');
  is_deeply($s->log, [ 'already_installed' ], '... and nothing after already_installed runs');
}

{
  my $rec = record_host(
    host => host_profile('ubuntu-24.04', responses => [ working_driver() ]),
    code => sub { die "install returned true\n" if $UBU->new(gpu => gpu_fixture('ada'))->install }
  );
  is($rec->{error}, undef, 'working driver: install returns 0');
  is_deeply($rec->{lines}, [ 'run: nvidia-smi -L 2>&1',
    q{run: /sbin/ldconfig -p 2>/dev/null | grep -q '^[[:space:]]*libcuda\.so\.1 '} ],
    '... after nothing but the two probes (nvidia-smi, libcuda)');
}

#### A subclass overriding one step

{
  package My::Mirror;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Debian';
  sub prepare_source {
    my ( $self, $plan ) = @_;
    $self->run_cmd('echo site mirror', auto_die => 0);
    $self->SUPER::prepare_source($plan);
  }
}

{
  my $base = record_host(host => host_profile('debian-12'),
    code => sub { $DEB->new(gpu => gpu_fixture('ada'))->install });
  my $mine = record_host(host => host_profile('debian-12'),
    code => sub { My::Mirror->new(gpu => gpu_fixture('ada'))->install });
  is($mine->{error}, undef, 'subclass install lives');
  my @want = @{ $base->{lines} };
  my ($at) = grep { $want[$_] =~ /apt-get .* update -q$/ } 0 .. $#want;
  splice @want, $at, 0, 'run: echo site mirror';
  is_deeply($mine->{lines}, \@want, 'exactly one extra command, right before apt-get update');
  ok(( grep { $_ eq 'run: update-initramfs -u 2>/dev/null' } @{ $base->{lines} } ),
    'post_install rebuilds the initramfs with the apt layer command');
}

{
  package My::RHEL::Mirror;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::RHEL';
  sub prepare_source {
    my ( $self, $plan ) = @_;
    $self->run_cmd('echo site mirror', auto_die => 0);
    $self->SUPER::prepare_source($plan);
  }

  package My::SUSE::NoLock;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::SUSE';
  sub install_packages {
    my ( $self, $plan ) = @_;
    $self->Rex::GPU::NVIDIA::Setup::Rpm::install_packages($plan);
  }
}

{
  my $base = record_host(host => host_profile('rocky-10'),
    code => sub { $RHEL->new(gpu => gpu_fixture('ada'))->install });
  my $mine = record_host(host => host_profile('rocky-10'),
    code => sub { My::RHEL::Mirror->new(gpu => gpu_fixture('ada'))->install });
  is($mine->{error}, undef, 'RHEL subclass install lives');
  my @want = @{ $base->{lines} };
  my ($at) = grep { $want[$_] eq 'run: uname -m' } 0 .. $#want;
  splice @want, $at, 0, 'run: echo site mirror';
  is_deeply($mine->{lines}, \@want, 'RHEL: one extra command, right before the arch read of prepare_source');
  ok(( grep { $_ eq 'run: dracut --force 2>/dev/null' } @{ $base->{lines} } ),
    'post_install rebuilds the initramfs with dracut on the rpm layer');

  $base = record_host(host => host_profile('leap-16.0'),
    code => sub { $SUSE->new(gpu => gpu_fixture('ada'))->install });
  $mine = record_host(host => host_profile('leap-16.0'),
    code => sub { My::SUSE::NoLock->new(gpu => gpu_fixture('ada'))->install });
  is($mine->{error}, undef, 'SUSE subclass install lives');
  is_deeply($mine->{lines}, [ grep { !/zypper addlock/ } @{ $base->{lines} } ],
    'SUSE: overriding install_packages drops exactly the addlock');
}

#### Pure helpers are callable on the class, as the old wrappers use them

is(Rex::GPU::NVIDIA::Setup->_cuda_repo_arch('arm64'), 'sbsa', '_cuda_repo_arch on the class');
is(Rex::GPU::NVIDIA::Setup->_major_version('10.1'), 10, '_major_version keeps the dots in mind');
is(Rex::GPU::NVIDIA::_os_major_version('15.6'), 15, 'old wrapper _os_major_version still answers');
is($RPM->_rpm_version_in_branch('580.95.05', 580), 1, '_rpm_version_in_branch on the class');
is($SUSE->repo_url('15.6'), 'https://download.nvidia.com/opensuse/leap/15.6/',
  'repo_url on the class');

#### Sources and their selection (karr #33)

{
  no warnings 'redefine';
  local *Rex::Logger::info = sub { };

  # sources only read facts: with them injected, no host is needed
  my %facts = ( kernel => '6.1.0-test', arch => 'amd64' );
  is_deeply([ map { $_->{name} } $DEB->new(%facts, release => '12.11')->sources ],
    [ 'debian-nonfree', 'nvidia-cuda-repo' ], 'Debian: non-free, then the CUDA repo');
  is_deeply([ map { $_->{branch} } $DEB->new(%facts, release => $_->[0])->sources ],
    [ $_->[1], undef ], "Debian $_->[0]: non-free is branch ".($_->[1] // 'unknown'))
    for [ '11.11', 470 ], [ '12.11', 535 ], [ '13.1', 550 ], [ '14.0', undef ], [ 'forky/sid', undef ];
  like(($DEB->new(%facts, release => '14.0')->sources)[1]{unavailable},
    qr/only covers Debian 12 and 13, not release '14.0'/, 'Debian 14: CUDA repo unavailable, says why');
  is_deeply([ map { $_->{name} } $UBU->new(%facts, release => '24.04')->sources ],
    [ 'ubuntu-server', 'ubuntu-server-open', 'ubuntu-server-580' ], 'Ubuntu: order');
  is_deeply([ map { $_->{name} } $RHEL->new(%facts, release => '9.6')->sources ],
    [ 'cuda-open-dkms', 'cuda-580-dkms' ], 'RHEL: order');
  is_deeply([ map { $_->{name} } $SUSE->new(%facts, release => '16.0')->sources ],
    [ 'nvidia-gfx-G07-open', 'nvidia-gfx-G06' ], 'Leap 16: order');
  is_deeply([ map { $_->{name} } $SUSE->new(%facts, release => '15.6')->sources ],
    [ 'nvidia-gfx-G06-open', 'nvidia-gfx-G06' ], 'Leap 15: order');

  # gpu / gpus
  is_deeply($DEB->new(gpu => gpu_fixture('ada'))->gpus, [ gpu_fixture('ada') ], 'gpu => [gpu]');
  is_deeply($DEB->new(gpu => undef)->gpus, [], 'gpu => undef => no GPU');
  ok(!eval { $DEB->new(gpu => gpu_fixture('ada'), gpus => [ gpu_fixture('ada') ]); 1 },
    'gpu and gpus together croak');
  ok(!eval { $DEB->new(gpus => gpu_fixture('ada')); 1 }, 'gpus not an arrayref croaks');

  # the requirement is the intersection
  my $req = $UBU->new(gpus => [ gpu_fixture('ada'), gpu_fixture('blackwell') ])->requirement;
  is($req->describe, 'open kernel module, driver branch 570 or newer', 'Ada + Blackwell => open, 570+');
  like($req->who, qr/RTX 4000 SFF Ada.*, .*RTX 5090/, '... naming both GPUs');
  is($UBU->new->requirement->describe, 'any kernel module, any driver branch', 'no GPU => no constraint');
  ok(!eval { $UBU->new(gpus => [ gpu_fixture('volta'), gpu_fixture('b200') ])->requirement; 1 },
    'V100 + B200: building the requirement dies');
  like($@, qr/^No single NVIDIA driver supports all GPUs on this host: .*B200.* needs the open kernel module, but .*V100.* needs the proprietary one\. No driver package was installed and no package source was added/,
    '... naming both GPUs, without a Perl file/line');

  # a subclass reorders its sources: a GPU without constraints takes the new first
  {
    package My::Ubuntu::Pinned;
    use Moo;
    extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';
    sub sources { my ( $self ) = @_; return reverse $self->SUPER::sources }
  }
  my $plan = My::Ubuntu::Pinned->new(%facts, os => 'Ubuntu', release => '24.04')->plan;
  is($plan->{source}{name}, 'ubuntu-server-580', 'subclass sources: its order wins');
  is_deeply($plan->{packages}, [ 'linux-headers-6.1.0-test', 'linux-headers-generic', 'nvidia-driver-580-server' ],
    '... and its package lands after the kernel headers');

  # a requirement passed to new(): no candidate on RHEL / Leap dies, listing each
  my $R = 'Rex::GPU::NVIDIA::Requirement';
  ok(!eval {
    $RHEL->new(%facts, os => 'Redhat', release => '9.6',
      requirement => $R->new(kernel_module => 'proprietary', min_branch => 590))->plan; 1 },
    'RHEL, proprietary 590+: no source fits');
  like($@, qr/^No NVIDIA driver source on this Redhat 9\.6 host fits NVIDIA GPU \(proprietary kernel module, driver branch 590 or newer\) -- cuda-open-dkms: open kernel module, the proprietary one is needed; cuda-580-dkms: branch 580 is older than 590\. No driver package was installed and no package source was added/,
    '... every candidate with its reason');
  ok(!eval {
    $SUSE->new(%facts, os => 'SuSE', release => '16.0',
      requirement => $R->new(kernel_module => 'open', max_branch => 580))->plan; 1 },
    'Leap 16, open up to 580: no source fits');
  like($@, qr/nvidia-gfx-G07-open: installs the newest branch it carries, which can be newer than 580; nvidia-gfx-G06: proprietary kernel module, the open one is needed/,
    '... the newest-branch source never passes a max bound');
}

#### karr #39: the RHEL family under the names Rex reports with lsb_release

{
  # redhat-lsb-core 4.1: Rocky, AlmaLinux, CentOSStream, RedHatEnterprise;
  # EPEL 9 lsb_release: RockyLinux, AlmaLinux, CentOS, RedHatEnterprise.
  for my $name (qw( Rocky RockyLinux AlmaLinux CentOSStream CentOS RedHatEnterprise Redhat )) {
    my $class;
    my $rec = record_host(host => host_profile('rocky-9', os => $name),
      code => sub { $class = Rex::GPU::NVIDIA->setup_class_for_os });
    is($class, $RHEL, "$name => $RHEL");
    is_deeply($rec->{lines}, [], "$name: resolving the class runs nothing");
  }
  # exact names only: an OS we cannot name is still refused
  for my $name (qw( OracleLinux Rockylinux2 NotRocky )) {
    my $class;
    record_host(host => host_profile('rocky-9', os => $name),
      code => sub { $class = Rex::GPU::NVIDIA->setup_class_for_os });
    is($class, undef, "$name => no Setup class");
  }
}

{
  my $kv = $RHEL->_parse_os_release(qq{NAME="Red Hat Enterprise Linux"\nID="rhel"\nID_LIKE='fedora'\nVERSION_ID=9.6\n# comment\n\nPLATFORM_ID="platform:el9"});
  is_deeply($kv, { NAME => 'Red Hat Enterprise Linux', ID => 'rhel', ID_LIKE => 'fedora',
    VERSION_ID => '9.6', PLATFORM_ID => 'platform:el9' }, 'os-release parsed, quotes removed');
  is($RHEL->new(os => 'Redhat', os_release => { ID => 'rhel' })->is_rhel, 1, 'ID=rhel is RHEL');
  is($RHEL->new(os => 'Redhat', os_release => { ID => 'rocky', ID_LIKE => 'rhel centos fedora' })->is_rhel, 0,
    'ID_LIKE=rhel is not RHEL itself');
  is($RHEL->new(os => 'Redhat', os_release => {})->is_rhel, 0, 'no os-release: not RHEL (the clone path)');

  my $rec = record_host(host => host_profile('rocky-9', responses => [
      [ 'cat /etc/os-release 2>/dev/null' => '', 1 ]
    ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
  is($rec->{error}, undef, 'unreadable /etc/os-release: installs as before');
  ok((grep { $_ eq 'pkg: epel-release ensure=present' } @{ $rec->{lines} }), '... with epel-release via pkg');
}

{
  # Rex::Pkg dies ("OS/Provider not supported") on a name is_redhat does not
  # know: no helper may go through pkg there.
  my $rec = record_host(host => host_profile('rocky-9-lsb', release => '10.0'),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('volta')) });
  is($rec->{error}, undef, 'Rocky (lsb) 10 + V100: lives');
  is((grep { /^pkg: / } @{ $rec->{lines} }), 0, '... no Rex::Pkg call');
  ok((grep { $_ eq 'run: dnf install -y python3-dnf-plugin-versionlock' } @{ $rec->{lines} }),
    '... versionlock plugin installed with dnf directly');
  ok((grep { $_ eq 'run: rpm -q python3-dnf-plugin-versionlock 2>&1' } @{ $rec->{lines} }),
    '... and verified with rpm -q');

  $rec = record_host(host => host_profile('rocky-9-lsb', responses => [
      [ 'rpm -q epel-release 2>&1' => 'package epel-release is not installed', 1 ]
    ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
  like($rec->{error}, qr/^epel-release not installed after dnf install/, 'Rocky (lsb), EPEL missing: dies');
  is((grep { /cuda-rhel9\.repo|kernel-devel/ } @{ $rec->{lines} }), 0, '... before the CUDA repo and any driver package');
}

{
  # RHEL itself: EPEL from its release RPM, CRB via subscription-manager.
  my $rec = record_host(host => host_profile('rhel-9', responses => [
      [ 'rpm -q epel-release 2>&1' => 'package epel-release is not installed', 1 ]
    ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
  like($rec->{error}, qr/^epel-release not installed after dnf install/, 'RHEL 9, EPEL RPM did not install: dies');
  is((grep { /cuda-rhel9\.repo|kernel-devel/ } @{ $rec->{lines} }), 0, '... before the CUDA repo and any driver package');

  $rec = record_host(host => host_profile('rhel-9', responses => [
      [ qr{^subscription-manager repos } => 'This system has no repositories available through subscriptions.', 1 ]
    ]),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
  is($rec->{error}, undef, 'RHEL 9, CRB cannot be enabled: no die');
  ok((grep { $_->[0] eq 'warn' && $_->[1] =~ /codeready-builder-for-rhel-9-x86_64-rpms/ } @{ $rec->{logs} }),
    '... but a warning naming the repository');

  for my $release (qw( 8.10 10.0 )) {
    my ($major) = $release =~ /^(\d+)/;
    $rec = record_host(host => host_profile('rhel-9', release => $release),
      code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
    ok((grep { $_ eq "run: dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$major.noarch.rpm" } @{ $rec->{lines} }),
      "RHEL $release: epel-release-latest-$major");
    ok((grep { $_ eq "run: subscription-manager repos --enable codeready-builder-for-rhel-$major-x86_64-rpms" } @{ $rec->{lines} }),
      "RHEL $release: codeready-builder-for-rhel-$major");
    is((grep { /powertools|--set-enabled crb/ } @{ $rec->{lines} }), 0, "RHEL $release: no crb/powertools");
  }
}

done_testing;
