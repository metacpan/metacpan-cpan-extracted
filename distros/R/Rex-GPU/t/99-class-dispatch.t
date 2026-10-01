use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

# -----------------------------------------------------------------------------
# Class dispatch for Rex::GPU / Rex::GPU::Detect / Rex::GPU::NVIDIA (karr #71):
# every public function is also a class method, every private helper is
# called through the class it runs as, and a subclass of the user's own
# (C<set gpu_nvidia_class> / C<gpu_nvidia_class>, C<set gpu_detect_class> /
# C<detect =>) is used in its place -- for a bare function call, for
# C<install_driver>/C<detect> called via C<gpu_setup>, and for the option
# passed straight to C<gpu_setup>.
#
# CLAIMS:
#   * a bare function call (C<install_driver(...)>, C<configure_containerd
#     ('rke2')>, C<Rex::GPU::Detect::detect()>) and the same call through
#     C<Rex::GPU::NVIDIA->method(...)> / C<Rex::GPU::Detect->method(...)>
#     emit byte-identical host interactions;
#   * a positional first argument of a public function (a runtime name
#     string) is never mistaken for a class -- C<_invocant> only recognises
#     something that C<isa> the base class;
#   * C<set gpu_nvidia_class> makes a subclass's override of a private
#     helper (C<_reboot_and_wait>) run instead of the built-in one, for a
#     bare C<install_driver(...)> call and for C<gpu_setup>'s own call to it;
#     C<gpu_setup(nvidia => ...)> does the same without the C<set>;
#   * the same three shapes for C<set gpu_detect_class> / C<detect =>
#     overriding C<_parse_nvidia_line> (plus a direct-call check for
#     C<requirement_class>);
#   * a class name that is not a Perl package name, cannot be loaded, or does
#     not extend the base class dies -- for both C<nvidia> and C<detect> --
#     before a single command reaches the (scripted) host;
#   * C<gpu_setup> hands C<install_driver> to a glob-stubbed
#     C<*Rex::GPU::NVIDIA::install_driver> exactly as before: the opts hash,
#     no class prepended -- the contract Rex::Rancher and kubernetes-ocp's
#     stubs rely on;
#   * C<install_driver> passes the setup it installed with to
#     C<verify_nvidia_driver>, which runs that object's C<libcuda_command>,
#     not the base class's default.
#
# NOT covered -- no host, real or otherwise, runs here:
#   * that a subclass a Rexfile author actually writes behaves like the
#     throwaway ones below (they exist only to prove the dispatch reaches
#     them);
#   * anything the t/10-detect.t / t/96-golden-driver.t header already says
#     prove cannot see (real lspci output, a real install, a real reboot).
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host host_names host_profile gpu_fixture );
use Rex::GPU;
use Rex::GPU::Detect;
use Rex::GPU::NVIDIA;
use Rex::GPU::NVIDIA::Requirement;
use Rex::GPU::NVIDIA::Setup::Ubuntu;

# Rex::Config->set(...) is shared by every host of a Rexfile; reset it after
# each case even if the case dies, like t/99-setup-select.t's with_set.
sub with_config {
  my ( $key, $value, $code ) = @_;
  Rex::Config->set($key => $value);
  my $ok  = eval { $code->(); 1 };
  my $err = $@;
  Rex::Config->set($key => undef);
  die $err unless $ok;
}

#### Throwaway subclasses, just to prove dispatch reaches them ###############

{
  package Test::ClassDispatch::NVIDIA;
  use parent -norequire, 'Rex::GPU::NVIDIA';
  our @REBOOTS;
  # Replaces the built-in reboot entirely (no SUPER::) so a passing test
  # proves the override ran, not that it ran the real thing afterwards.
  sub _reboot_and_wait {
    my ( $class ) = @_;
    push @REBOOTS, $class;
    return;
  }
}

{
  package Test::ClassDispatch::Detect;
  use parent -norequire, 'Rex::GPU::Detect';
  our @PARSED;
  sub _parse_nvidia_line {
    my ( $class, $line ) = @_;
    my $gpu = $class->SUPER::_parse_nvidia_line($line);
    if ($gpu) {
      push @PARSED, $gpu->{device_id};
      $gpu->{name} = 'OVERRIDDEN: '.$gpu->{name};
    }
    return $gpu;
  }
}

{
  package Test::ClassDispatch::Requirement;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Requirement';
  sub generations {
    my ( $self ) = @_;
    return (
      { generation => 'Site Special', first => 0x4001, last => 0x4001,
        kernel_module => 'open', min_branch => 999, compute => 1 },
      $self->SUPER::generations
    );
  }
}

{
  package Test::ClassDispatch::DetectReq;
  use parent -norequire, 'Rex::GPU::Detect';
  sub requirement_class { 'Test::ClassDispatch::Requirement' }
}

{
  package Test::ClassDispatch::Setup;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';
  sub libcuda_command { 'echo test-class-dispatch-libcuda' }
}

# Loadable, but neither extends Rex::GPU::NVIDIA nor Rex::GPU::Detect.
{
  package Test::ClassDispatch::NotASubclass;
  use Moo;
}

my $MISSING = 'Test::ClassDispatch::NoSuchModuleAtAll';

#### 1. function call vs Class->method: identical host interactions #########

subtest 'function call and Class->method emit identical commands' => sub {
  my $fn = record_host(host => host_profile('ubuntu-24.04'),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
  my $cm = record_host(host => host_profile('ubuntu-24.04'),
    code => sub { Rex::GPU::NVIDIA->install_driver(gpu => gpu_fixture('ada')) });
  is($cm->{error}, $fn->{error}, 'install_driver: same result (lives)');
  is_deeply($cm->{lines}, $fn->{lines},
    'install_driver: Rex::GPU::NVIDIA->install_driver(...) matches the bare function call');

  my $conf_host = sub {
    host_profile('debian-12', can_run => { 'nvidia-container-runtime' => 1 },
      responses => [
        [ 'cat /var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl 2>/dev/null' => '', 1 ],
        [ 'cat /var/lib/rancher/rke2/agent/etc/containerd/config.toml 2>/dev/null'      => '', 1 ],
        [ 'test -f /var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.tmpl'      => '', 1 ],
        [ 'test -d /var/lib/rancher/rke2/agent/etc/containerd/config-v3.toml.d'         => '', 1 ]
      ]);
  };
  my $fn2 = record_host(host => $conf_host->(),
    code => sub { Rex::GPU::NVIDIA::configure_containerd('rke2') });
  my $cm2 = record_host(host => $conf_host->(),
    code => sub { Rex::GPU::NVIDIA->configure_containerd('rke2') });
  is($cm2->{error}, $fn2->{error}, 'configure_containerd: same result (lives)');
  is_deeply($cm2->{lines}, $fn2->{lines},
    'configure_containerd: Rex::GPU::NVIDIA->configure_containerd(...) matches the bare function call');
  ok(scalar(@{$fn2->{lines}}) > 0, '... and it is not a no-op (sanity: the v3 drop-in path ran)');

  no warnings 'redefine';
  local *Rex::GPU::Detect::_has_lspci   = sub { 1 };
  local *Rex::GPU::Detect::is_installed = sub { 1 };
  local *Rex::GPU::Detect::run          = sub {
    '01:00.0 3D controller [0302]: NVIDIA Corporation AD104GL [RTX 4000 SFF Ada Generation] [10de:27b0] (rev a1)'
  };
  local *Rex::Logger::info = sub { };
  my $fd = Rex::GPU::Detect::detect();
  my $cd = Rex::GPU::Detect->detect();
  is_deeply($cd, $fd, 'Rex::GPU::Detect->detect matches the bare function call');
};

#### 2. a runtime string is never mistaken for a class #######################

subtest "positional configure_containerd('rke2') is not mistaken for a class" => sub {
  for my $runtime (qw( rke2 k3s containerd )) {
    my $base = $runtime eq 'containerd' ? undef : "/var/lib/rancher/$runtime/agent/etc/containerd";
    my $host = $runtime eq 'containerd'
      ? host_profile('debian-12', can_run => { 'nvidia-container-runtime' => 1 })
      : host_profile('debian-12', can_run => { 'nvidia-container-runtime' => 1 },
          responses => [
            [ "cat $base/config.toml.tmpl 2>/dev/null" => '', 1 ],
            [ "cat $base/config.toml 2>/dev/null"      => '', 1 ],
            [ "test -f $base/config-v3.toml.tmpl"      => '', 1 ],
            [ "test -d $base/config-v3.toml.d"         => '', 1 ]
          ]);
    my $rec = record_host(host => $host,
      code => sub { Rex::GPU::NVIDIA::configure_containerd($runtime) });
    is($rec->{error}, undef,
      "configure_containerd('$runtime') lives -- the runtime string dispatched as a function, not a bad class");
  }
  # CAVEAT, not a claim this test pins as "correct": _invocant's rule is
  # "the first argument isa the base class" (karr #71's own design), so a
  # positional argument that happens to BE a real Rex::GPU::NVIDIA subclass
  # name is indistinguishable from a method dispatch -- it is taken as the
  # invocant, $runtime is then undef and defaults to 'rke2', and the call
  # lives instead of dying "Unknown containerd runtime". Only an ordinary
  # runtime string (rke2/k3s/containerd/none, never a package name) is safe;
  # this is inherent to the recognition rule, not something to fix here.
  my $rec = record_host(host => host_profile('debian-12'),
    code => sub { Rex::GPU::NVIDIA::configure_containerd('Rex::GPU::NVIDIA') });
  is($rec->{error}, undef,
    'a positional argument that IS a real subclass name is read as the invocant instead (documented caveat)');
  is_deeply($rec->{lines}, [ 'can_run: nvidia-container-runtime' ],
    '... $runtime defaults to rke2 and the call proceeds as Rex::GPU::NVIDIA->configure_containerd()');
};

#### 3. set gpu_nvidia_class: override reaches install_driver, all shapes ####

sub gpu_setup_env {
  my ( $code ) = @_;
  no warnings 'redefine';
  local *Rex::GPU::_check_connection                 = sub { };
  local *Rex::GPU::Detect::detect                    = sub {
    { nvidia => [ gpu_fixture('ada') ], amd => [], nvswitch => [] }
  };
  local *Rex::GPU::NVIDIA::install_container_toolkit = sub { };
  local *Rex::GPU::NVIDIA::generate_cdi_specs        = sub { };
  local *Rex::GPU::NVIDIA::verify_nvidia             = sub { };
  local *Rex::Logger::info                           = sub { };
  return $code->();
}

subtest 'set gpu_nvidia_class: subclass overrides _reboot_and_wait' => sub {
  @Test::ClassDispatch::NVIDIA::REBOOTS = ();
  with_config(gpu_nvidia_class => 'Test::ClassDispatch::NVIDIA', sub {
    my $rec = record_host(host => host_profile('debian-12'),
      code => sub { Rex::GPU::NVIDIA::install_driver(reboot => 1, gpu => gpu_fixture('ada')) });
    is($rec->{error}, undef, 'bare install_driver(...) lives');
    is_deeply(\@Test::ClassDispatch::NVIDIA::REBOOTS, [ 'Test::ClassDispatch::NVIDIA' ],
      'bare install_driver(...): the configured subclass, not the base class, ran _reboot_and_wait');
    ok(!(grep { /shutdown -r/ } @{ $rec->{lines} }),
      '... the built-in shutdown never ran (the override replaced it)');
  });

  @Test::ClassDispatch::NVIDIA::REBOOTS = ();
  with_config(gpu_nvidia_class => 'Test::ClassDispatch::NVIDIA', sub {
    my $rec = gpu_setup_env(sub {
      record_host(host => host_profile('debian-12'),
        code => sub { Rex::GPU::gpu_setup(reboot => 1, containerd_config => 'none') });
    });
    is($rec->{error}, undef, 'gpu_setup lives');
    is_deeply(\@Test::ClassDispatch::NVIDIA::REBOOTS, [ 'Test::ClassDispatch::NVIDIA' ],
      "gpu_setup's own call to install_driver reached the configured subclass too");
    ok(!(grep { /shutdown -r/ } @{ $rec->{lines} }), '... no built-in shutdown here either');
  });

  @Test::ClassDispatch::NVIDIA::REBOOTS = ();
  my $rec = gpu_setup_env(sub {
    record_host(host => host_profile('debian-12'), code => sub {
      Rex::GPU::gpu_setup(nvidia => 'Test::ClassDispatch::NVIDIA', reboot => 1, containerd_config => 'none');
    });
  });
  is($rec->{error}, undef, 'gpu_setup(nvidia => ...) lives, with no set gpu_nvidia_class in effect');
  is_deeply(\@Test::ClassDispatch::NVIDIA::REBOOTS, [ 'Test::ClassDispatch::NVIDIA' ],
    'gpu_setup(nvidia => ...): the option alone routes install_driver to the subclass');
  ok(!(grep { /shutdown -r/ } @{ $rec->{lines} }), '... no built-in shutdown');
};

#### 4. set gpu_detect_class: override reaches detect, all shapes ###########

my $ADA_LINE = '01:00.0 3D controller [0302]: NVIDIA Corporation AD104GL [RTX 4000 SFF Ada Generation] [10de:27b0] (rev a1)';

sub detect_env {
  my ( $code ) = @_;
  no warnings 'redefine';
  local *Rex::GPU::Detect::_has_lspci   = sub { 1 };
  local *Rex::GPU::Detect::is_installed = sub { 1 };
  local *Rex::GPU::Detect::run          = sub { $ADA_LINE };
  local *Rex::Logger::info              = sub { };
  return $code->();
}

subtest 'set gpu_detect_class / detect =>: subclass overrides _parse_nvidia_line' => sub {
  @Test::ClassDispatch::Detect::PARSED = ();
  with_config(gpu_detect_class => 'Test::ClassDispatch::Detect', sub {
    my $r = detect_env(sub { Rex::GPU::Detect::detect() });
    is($r->{nvidia}[0]{name}, 'OVERRIDDEN: AD104GL [RTX 4000 SFF Ada Generation]',
      'bare Rex::GPU::Detect::detect(): the configured subclass parsed the line');
    is_deeply(\@Test::ClassDispatch::Detect::PARSED, [ '27b0' ], '... exactly once');
  });

  @Test::ClassDispatch::Detect::PARSED = ();
  my $r = detect_env(sub { Rex::GPU::gpu_detect(detect => 'Test::ClassDispatch::Detect') });
  is($r->{nvidia}[0]{name}, 'OVERRIDDEN: AD104GL [RTX 4000 SFF Ada Generation]',
    "gpu_detect(detect => ...): routed to the subclass, no set in effect");
  is_deeply(\@Test::ClassDispatch::Detect::PARSED, [ '27b0' ], '... exactly once');

  @Test::ClassDispatch::Detect::PARSED = ();
  no warnings 'redefine';
  local *Rex::GPU::_check_connection                 = sub { };
  local *Rex::GPU::NVIDIA::install_driver            = sub { };
  local *Rex::GPU::NVIDIA::install_container_toolkit = sub { };
  local *Rex::GPU::NVIDIA::generate_cdi_specs        = sub { };
  local *Rex::GPU::NVIDIA::configure_containerd      = sub { };
  local *Rex::GPU::NVIDIA::verify_nvidia             = sub { };
  my $gpus = detect_env(sub { Rex::GPU::gpu_setup(detect => 'Test::ClassDispatch::Detect') });
  is($gpus->{nvidia}[0]{name}, 'OVERRIDDEN: AD104GL [RTX 4000 SFF Ada Generation]',
    'gpu_setup(detect => ...): the GPU list gpu_setup acts on came from the configured subclass');
  is_deeply(\@Test::ClassDispatch::Detect::PARSED, [ '27b0' ], '... exactly once');
};

subtest 'requirement_class is read through the class too' => sub {
  no warnings 'redefine';
  local *Rex::Logger::info = sub { };
  is(Rex::GPU::Detect->_is_nvidia_compute('0300', 'Device', '4001'), 0,
    'base class: device id 4001 is in no generation row => not compute');
  is(Test::ClassDispatch::DetectReq->_is_nvidia_compute('0300', 'Device', '4001'), 1,
    'a subclass overriding requirement_class changes the verdict for the same ID');
};

#### 5. bad classes die before any host command, for both keys #############

subtest 'bad class name / not-a-subclass / unloadable die before any host command' => sub {
  no warnings 'redefine';
  local *Rex::GPU::_check_connection = sub { };
  for my $case (
    [ nvidia => '../evil',                             qr/is not a Perl package name/ ],
    [ nvidia => $MISSING,                               qr/not found -- no/ ],
    [ nvidia => 'Test::ClassDispatch::NotASubclass',    qr/is not a subclass of Rex::GPU::NVIDIA/ ],
    [ detect => '../evil',                              qr/is not a Perl package name/ ],
    [ detect => $MISSING,                               qr/not found -- no/ ],
    [ detect => 'Test::ClassDispatch::NotASubclass',    qr/is not a subclass of Rex::GPU::Detect/ ]
  ) {
    my ( $key, $bad, $want ) = @$case;
    my $rec = record_host(host => host_profile('debian-12'),
      code => sub { Rex::GPU::gpu_setup($key => $bad) });
    like($rec->{error}, $want, "gpu_setup($key => '$bad'): dies with the expected message");
    is_deeply($rec->{lines}, [], "gpu_setup($key => '$bad'): not one host command ran");
  }

  # The same, via `set`, for completeness -- reset afterwards either way.
  with_config(gpu_nvidia_class => $MISSING, sub {
    my $rec = record_host(host => host_profile('debian-12'), code => sub { Rex::GPU::gpu_setup() });
    like($rec->{error}, qr/not found -- no/, 'set gpu_nvidia_class with a missing module: gpu_setup dies');
    is_deeply($rec->{lines}, [], '... before any host command');
  });
  with_config(gpu_detect_class => $MISSING, sub {
    my $rec = record_host(host => host_profile('debian-12'), code => sub { Rex::GPU::gpu_setup() });
    like($rec->{error}, qr/not found -- no/, 'set gpu_detect_class with a missing module: gpu_setup dies');
    is_deeply($rec->{lines}, [], '... before any host command');
  });
};

#### 6. the downstream contract: no class prepended to a glob-stubbed call ##

subtest 'glob-stubbed install_driver from gpu_setup gets exactly the opts, no class prepended' => sub {
  my @raw;
  no warnings 'redefine';
  local *Rex::GPU::NVIDIA::install_driver            = sub { @raw = @_ };
  local *Rex::GPU::NVIDIA::install_container_toolkit = sub { };
  local *Rex::GPU::NVIDIA::generate_cdi_specs        = sub { };
  local *Rex::GPU::NVIDIA::configure_containerd      = sub { };
  local *Rex::GPU::NVIDIA::verify_nvidia             = sub { };
  local *Rex::GPU::_check_connection                 = sub { };
  local *Rex::GPU::Detect::detect                    = sub {
    { nvidia => [ gpu_fixture('ada') ], amd => [], nvswitch => [] }
  };
  local *Rex::Logger::info = sub { };

  Rex::GPU::gpu_setup(reboot => 1);
  is_deeply(\@raw, [ reboot => 1, gpus => [ gpu_fixture('ada') ] ],
    'exactly the opts hash Rex::Rancher and kubernetes-ocp stubs already expect -- no invocant in front');
  is($raw[0], 'reboot', '... the first element is an option key, not a class name');
};

#### 7. verify_nvidia_driver uses the installed setup's libcuda_command #####

subtest "verify_nvidia_driver uses the chosen setup's libcuda_command" => sub {
  my $rec = record_host(host => host_profile('ubuntu-24.04'),
    code => sub {
      Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada'), setup => 'Test::ClassDispatch::Setup');
    });
  is($rec->{error}, undef, 'install_driver with the custom setup class lives');
  is(scalar(grep { $_ eq 'run: echo test-class-dispatch-libcuda' } @{ $rec->{lines} }), 1,
    'the overridden libcuda_command ran exactly once');
  ok(!(grep { m{/sbin/ldconfig -p} } @{ $rec->{lines} }),
    '... and the base class default libcuda_command did not run');

  # Sanity: same host/GPU without the custom setup uses the default command.
  my $base = record_host(host => host_profile('ubuntu-24.04'),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
  ok((grep { m{/sbin/ldconfig -p} } @{ $base->{lines} }),
    '... which is present without the override (the difference is the setup class, not the host)');
};

done_testing;
