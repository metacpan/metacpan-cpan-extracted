use strict;
use warnings;
use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";
use lib "$Bin/../eg/custom-setup/lib";   # the eg/ example class, My::GPU::Setup

use Path::Tiny qw( tempdir );

# -----------------------------------------------------------------------------
# Choosing the Setup class, and the requirement escape hatch (karr #34, T5 of
# epic #25).
#
# CLAIMS:
#   * precedence: setup => (class or object) beats `set gpu_nvidia_setup`,
#     which beats setup_class_for_os; an unset or empty option falls through;
#   * a class name is loaded from @INC (a temp lib dir here, the project's
#     lib/ under Rex) unless the package is already defined (inline, as in a
#     Rexfile), and must be a Rex::GPU::NVIDIA::Setup;
#   * a missing module, a module that does not compile, a non-package name, a
#     non-Setup class or an unblessed ref croak -- before any host
#     interaction, and in gpu_setup before detection;
#   * an object is used as-is, but gets the detected GPUs when it has none,
#     and refuses when its requirement is already fixed;
#   * requirement => is intersected with what the GPUs need: it tightens
#     (Ada + open => -server-open), cannot loosen (V100 + open dies in plan
#     with only read-only probes before it), and a typo in it croaks;
#   * gpu_setup hands setup/requirement through to install_driver only when
#     given (Rex::Rancher's gpu => 1 call is unchanged);
#   * the eg/ class My::GPU::Setup produces the transcript in
#     t/golden/driver/custom--ubuntu-24.04--ada--apt-line.txt.
#
# NOT covered: a real host. Nothing here runs apt, dnf or a GPU, and whether
# the eg/ class's pinned package exists on a real Ubuntu is not checked.
# -----------------------------------------------------------------------------

use Test::RexGPU::Golden qw( record_host golden_is host_profile gpu_fixture mutating_lines );
use Rex::GPU;
use Rex::GPU::NVIDIA;
use My::GPU::Setup;

my $NV  = 'Rex::GPU::NVIDIA';
my $UBU = 'Rex::GPU::NVIDIA::Setup::Ubuntu';

{
  package My::Inline::Setup;          # like a class written into a Rexfile
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Ubuntu';

  package My::Inline::Other;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Debian';

  package My::Inline::NotASetup;
  use Moo;
  sub install { 1 }

  package My::Inline::Plain;          # no Moo: only @ISA, no %INC entry
  our @ISA = ( 'Rex::GPU::NVIDIA::Setup::Ubuntu' );
}

sub with_set {
  my ( $value, $code ) = @_;
  Rex::Config->set(gpu_nvidia_setup => $value);
  my $ok  = eval { $code->(); 1 };
  my $err = $@;
  Rex::Config->set(gpu_nvidia_setup => undef);
  die $err unless $ok;
}

sub setup_on {
  my ( $os, %opt ) = @_;
  my $setup;
  my $rec = record_host(host => host_profile($os),
    code => sub { $setup = $NV->setup_for(%opt) });
  return ( $setup, $rec );
}

#### Precedence

{
  my ( $s, $rec ) = setup_on('ubuntu-24.04', gpus => [ gpu_fixture('ada') ]);
  is(ref $s, $UBU, 'nothing chosen: the OS class');

  with_set('My::Inline::Other', sub {
    ( $s, $rec ) = setup_on('ubuntu-24.04', gpus => [ gpu_fixture('ada') ]);
    is(ref $s, 'My::Inline::Other', 'set gpu_nvidia_setup beats the OS');
    is_deeply($rec->{lines}, [], '... and the OS is not even asked');

    ( $s ) = setup_on('ubuntu-24.04', setup => 'My::Inline::Setup');
    is(ref $s, 'My::Inline::Setup', 'setup => beats set gpu_nvidia_setup');

    ( $s ) = setup_on('ubuntu-24.04', setup => '');
    is(ref $s, 'My::Inline::Other', "setup => '' falls through to the set");
    ( $s ) = setup_on('ubuntu-24.04', setup => undef);
    is(ref $s, 'My::Inline::Other', 'setup => undef falls through to the set');
  });

  with_set('', sub {
    ( $s ) = setup_on('ubuntu-24.04');
    is(ref $s, $UBU, "set gpu_nvidia_setup => '' means auto");
  });

  my $obj = My::Inline::Other->new;
  with_set($obj, sub {
    ( $s, $rec ) = setup_on('ubuntu-24.04');
    like($rec->{error}, qr/^set gpu_nvidia_setup takes a class name/,
      'set gpu_nvidia_setup => $object croaks: shared by every host');
  });

  is_deeply([ map { $_->{name} } My::Inline::Setup->new(kernel => 'k', arch => 'amd64')->sources ],
    [ 'ubuntu-server', 'ubuntu-server-open', 'ubuntu-server-580' ],
    'an inline class inherits the built-in sources');
}

{
  # A custom class makes an OS without a built-in class installable.
  my $rec;
  with_set('My::Inline::Setup', sub {
    $rec = record_host(host => host_profile('ubuntu-24.04', os => 'Gentoo'),
      code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada')) });
  });
  unlike($rec->{error} // '', qr/Unsupported OS/, 'custom class on an OS without one: no Unsupported OS');
}

#### Loading a class from @INC

{
  my $dir = tempdir();
  $dir->child('lib/My/Tmp')->mkpath;
  $dir->child('lib/My/Tmp/Setup.pm')->spew_utf8(<<'PM');
package My::Tmp::Setup;
use Moo;
extends 'Rex::GPU::NVIDIA::Setup::Debian';
1;
PM
  $dir->child('lib/My/Tmp/Broken.pm')->spew_utf8("package My::Tmp::Broken;\nsub {\n1;\n");
  $dir->child('lib/My/Tmp/Plain.pm')->spew_utf8("package My::Tmp::Plain;\nsub new { bless {}, shift }\n1;\n");
  local @INC = ( $dir->child('lib')->stringify, @INC );

  ok(!My::Tmp::Setup->can('new'), 'My::Tmp::Setup is not loaded yet');
  is($NV->custom_setup('My::Tmp::Setup'), 'My::Tmp::Setup', 'class name loaded from @INC');
  ok($INC{'My/Tmp/Setup.pm'}, '... via its file');
  my ( $s ) = setup_on('debian-12', setup => 'My::Tmp::Setup', gpus => [ gpu_fixture('ada') ]);
  isa_ok($s, 'My::Tmp::Setup');
  is_deeply($s->gpus, [ gpu_fixture('ada') ], '... built with the GPUs');

  is($NV->custom_setup('My::Inline::Setup'), 'My::Inline::Setup', 'an inline Moo class is taken');
  ok(!$INC{'My/Inline/Plain.pm'}, 'an inline @ISA-only package has no %INC entry ...');
  is($NV->custom_setup('My::Inline::Plain'), 'My::Inline::Plain', '... and is still not looked up as a file');

  ok(!eval { $NV->custom_setup('My::Tmp::Missing'); 1 }, 'missing module croaks');
  like($@, qr{^NVIDIA driver setup from setup =>: My::Tmp::Missing not found -- no My/Tmp/Missing\.pm in \@INC\. Put it at lib/My/Tmp/Missing\.pm next to your Rexfile .*Nothing was changed on the host},
    '... saying where to put it');

  ok(!eval { $NV->custom_setup('My::Tmp::Broken'); 1 }, 'module that does not compile croaks');
  like($@, qr/loading My::Tmp::Broken failed: .*syntax error/s, '... with the compile error');

  ok(!eval { $NV->custom_setup('My::Tmp::Plain'); 1 }, 'a loadable non-Setup class croaks');
  like($@, qr/My::Tmp::Plain is not a subclass of Rex::GPU::NVIDIA::Setup/, '... saying so');

  ok(!eval { $NV->custom_setup('My::Inline::NotASetup'); 1 }, 'an inline non-Setup class croaks');
  ok(!eval { $NV->custom_setup('../evil'); 1 }, 'a non-package name croaks');
  like($@, qr/'\.\.\/evil' is not a Perl package name/, '... before any file is looked up');
  ok(!eval { $NV->custom_setup({}); 1 }, 'an unblessed ref croaks');
  ok(!eval { $NV->custom_setup(My::Inline::NotASetup->new); 1 }, 'a non-Setup object croaks');

  with_set('My::Tmp::Missing', sub {
    ok(!eval { $NV->custom_setup(undef); 1 }, 'a missing module in set gpu_nvidia_setup croaks');
    like($@, qr/^NVIDIA driver setup from set gpu_nvidia_setup: My::Tmp::Missing not found/,
      '... naming the set as the origin');
  });

  my $rec = record_host(host => host_profile('ubuntu-24.04'),
    code => sub { Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada'), setup => 'My::Tmp::Missing') });
  like($rec->{error}, qr/My::Tmp::Missing not found/, 'install_driver with a missing class dies');
  is_deeply($rec->{lines}, [], '... before any host interaction, the nvidia-smi probe included');
}

#### An object

{
  my $obj = My::Inline::Setup->new;
  my ( $s, $rec ) = setup_on('ubuntu-24.04', setup => $obj, gpus => [ gpu_fixture('blackwell') ]);
  is($s, $obj, 'an object is used as-is');
  is_deeply($s->gpus, [ gpu_fixture('blackwell') ], '... and gets the detected GPUs when it has none');
  is_deeply($rec->{lines}, [], '... without a host interaction');

  $obj = My::Inline::Setup->new(gpus => []);
  setup_on('ubuntu-24.04', setup => $obj, gpus => [ gpu_fixture('volta') ]);
  is_deeply($obj->gpus, [ gpu_fixture('volta') ], 'an object built with gpus => [] gets them too');

  $obj = My::Inline::Setup->new(gpu => gpu_fixture('ada'));
  setup_on('ubuntu-24.04', setup => $obj, gpus => [ gpu_fixture('blackwell') ]);
  is_deeply($obj->gpus, [ gpu_fixture('ada') ], 'an object built for its own GPUs keeps them');

  $obj = My::Inline::Setup->new(requirement => Rex::GPU::NVIDIA::Requirement->new);
  ( $s, $rec ) = setup_on('ubuntu-24.04', setup => $obj, gpus => [ gpu_fixture('volta') ]);
  like($rec->{error}, qr/already has a fixed requirement/, 'an object with a fixed requirement and no GPUs croaks');

  $obj = My::Inline::Setup->new(requirement => Rex::GPU::NVIDIA::Requirement->new);
  ( $s ) = setup_on('ubuntu-24.04', setup => $obj);
  is($s, $obj, '... but is fine when there is nothing to hand over');

  $obj = My::Inline::Setup->new(extra_requirement => { min_branch => 580 });
  ( $s, $rec ) = setup_on('ubuntu-24.04', setup => $obj, extra_requirement => { kernel_module => 'open' });
  like($rec->{error}, qr/has an extra_requirement of its own/, 'extra_requirement on the object and the option croaks');

  $obj = My::Inline::Setup->new;
  setup_on('ubuntu-24.04', setup => $obj, extra_requirement => { kernel_module => 'open' });
  is($obj->requirement->describe, 'open kernel module, any driver branch', 'the requirement option reaches an object');

  # one object, two hosts: the second is refused before its host is touched
  $obj = My::Inline::Setup->new;
  $rec = record_host(host => host_profile('ubuntu-24.04'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada'), setup => $obj) });
  is($rec->{error}, undef, 'an object installs on the first host');
  $rec = record_host(host => host_profile('ubuntu-22.04'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada'), setup => $obj) });
  like($rec->{error}, qr/has already run install/, '... and is refused for a second one');
  is_deeply($rec->{lines}, [], '... before any host interaction');
}

#### The requirement escape hatch

{
  no warnings 'redefine';
  local *Rex::Logger::info = sub { };
  my %facts = ( os => 'Ubuntu', release => '24.04', kernel => '6.8.0-1', arch => 'amd64' );

  my $s = $UBU->new(%facts, gpu => gpu_fixture('ada'), extra_requirement => { kernel_module => 'open' });
  is($s->requirement->describe, 'open kernel module, any driver branch', 'Ada + open: intersected');
  like($s->requirement->who, qr/RTX 4000 SFF Ada.*, the requirement option/, '... naming the GPU and the option');

  $s = $UBU->new(%facts, gpu => gpu_fixture('volta'), extra_requirement => { min_branch => 570 });
  is($s->requirement->describe, 'proprietary kernel module, driver branch 570 to 580',
    'V100 + 570 or newer: tightened, the GPU max stays');

  $s = $UBU->new(%facts, extra_requirement => { kernel_module => 'open', min_branch => 580 });
  is($s->requirement->describe, 'open kernel module, driver branch 580 or newer', 'no GPU: the option alone');

  my $obj = Rex::GPU::NVIDIA::Requirement->new(kernel_module => 'open', name => 'site policy');
  $s = $UBU->new(%facts, gpu => gpu_fixture('ada'), extra_requirement => $obj);
  like($s->requirement->who, qr/site policy/, 'a Requirement object is taken as-is');

  ok(!eval { $UBU->new(extra_requirement => { min_brach => 580 }); 1 }, 'a typo in the requirement croaks');
  like($@, qr/unknown requirement key min_brach/, '... in new, naming the key');
  ok(!eval { $UBU->new(extra_requirement => { kernel_module => 'closed' }); 1 }, 'a bad value croaks');
  ok(!eval { $UBU->new(extra_requirement => 'open'); 1 }, 'a string croaks');

  ok(!eval { $UBU->new(%facts, gpu => gpu_fixture('volta'), extra_requirement => { kernel_module => 'open' })->requirement; 1 },
    'V100 + open: cannot loosen, dies');
  like($@, qr/^No NVIDIA driver meets both what the GPUs need and the requirement option \(open kernel module, any driver branch\): .*No driver package was installed and no package source was added/,
    '... naming both sides');
}

{
  my $rec = record_host(host => host_profile('ubuntu-24.04'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada'), requirement => { kernel_module => 'open' });
  });
  is($rec->{error}, undef, 'install_driver, Ada + requirement open: lives');
  ok(( grep { /apt-get .* install -y .*nvidia-driver-590-server-open$/ } @{ $rec->{lines} } ),
    '... and installs the -server-open driver');

  $rec = record_host(host => host_profile('ubuntu-24.04'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('volta'), requirement => { kernel_module => 'open' });
  });
  like($rec->{error}, qr/No NVIDIA driver meets both/, 'install_driver, V100 + requirement open: dies');
  is_deeply([ mutating_lines(@{ $rec->{lines} }) ], [], '... with only read-only probes before it');

  $rec = record_host(host => host_profile('ubuntu-24.04'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('kepler'), requirement => { max_branch => 470 });
  });
  like($rec->{error}, qr/Kepler or older/, 'a requirement cannot bring Kepler back');

  $rec = record_host(host => host_profile('ubuntu-24.04'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('ada'), requirement => { min_brach => 1 });
  });
  like($rec->{error}, qr/unknown requirement key/, 'install_driver with a typo in requirement dies');
  is_deeply($rec->{lines}, [], '... before any host interaction');
}

#### gpu_setup hands the options through

{
  my ( @calls, @steps, $detected );
  no warnings 'redefine';
  local *Rex::GPU::_check_connection               = sub { };
  local *Rex::GPU::Detect::detect                  = sub { $detected++; { nvidia => [ gpu_fixture('ada') ], amd => [] } };
  local *Rex::GPU::NVIDIA::install_driver          = sub { push @calls, { @_ }; push @steps, 'driver' };
  local *Rex::GPU::NVIDIA::install_container_toolkit = sub { push @steps, 'toolkit' };
  local *Rex::GPU::NVIDIA::generate_cdi_specs      = sub { push @steps, 'cdi' };
  local *Rex::GPU::NVIDIA::configure_containerd    = sub { push @steps, 'containerd' };
  local *Rex::GPU::NVIDIA::verify_nvidia           = sub { push @steps, 'verify' };
  local *Rex::Logger::info                         = sub { };

  Rex::GPU::gpu_setup(containerd_config => 'rke2', reboot => 0);
  is_deeply([ sort keys %{ $calls[-1] } ], [ qw( gpus reboot ) ],
    'gpu_setup without the options: install_driver gets exactly what it got before');
  # karr #42: install_driver checks only the driver; the full verify_nvidia
  # (toolkit included) runs once, after the toolkit and containerd steps.
  is_deeply(\@steps, [ qw( driver toolkit cdi containerd verify ) ],
    'gpu_setup runs the full verify_nvidia last');
  @steps = ();
  Rex::GPU::gpu_setup(containerd_config => 'none');
  is_deeply(\@steps, [ qw( driver toolkit cdi verify ) ], '... also with containerd_config => none');

  Rex::GPU::gpu_setup(setup => 'My::Inline::Setup', requirement => { min_branch => 580 });
  is($calls[-1]{setup}, 'My::Inline::Setup', 'setup => handed through');
  is_deeply($calls[-1]{requirement}, { min_branch => 580 }, 'requirement => handed through');

  $detected = 0;
  ok(!eval { Rex::GPU::gpu_setup(setup => 'My::Tmp::Nowhere'); 1 }, 'gpu_setup with a missing class dies');
  is($detected, 0, '... before detection (which installs pciutils)');
}

#### The eg/ example class, as a golden transcript

{
  my $rec = record_host(host => host_profile('ubuntu-24.04'), code => sub {
    Rex::GPU::NVIDIA::install_driver(
      gpu   => gpu_fixture('ada'),
      setup => My::GPU::Setup->new(apt_line => 'deb [signed-by=/usr/share/keyrings/internal.gpg] http://apt.internal.example/ubuntu noble main restricted')
    );
  });
  golden_is($rec, 'driver/custom--ubuntu-24.04--ada--apt-line');

  # V100: the pinned open source is rejected, the built-in 580 one taken
  $rec = record_host(host => host_profile('ubuntu-24.04'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('volta'), setup => 'My::GPU::Setup');
  });
  my $base = record_host(host => host_profile('ubuntu-24.04'), code => sub {
    Rex::GPU::NVIDIA::install_driver(gpu => gpu_fixture('volta'));
  });
  is_deeply($rec->{lines}, $base->{lines}, 'eg/ class + V100: exactly the built-in transcript');
}

done_testing;
