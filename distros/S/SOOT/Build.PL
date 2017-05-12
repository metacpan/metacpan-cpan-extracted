use strict;
use warnings;

use Getopt::Long;
use inc::latest 'ExtUtils::ParseXS';
use inc::latest 'ExtUtils::XSpp';
use inc::latest 'ExtUtils::CppGuess';
use inc::latest 'Module::Build';

use lib 'inc';
use SOOTBuilder;

my $userRootConfig;
my $compiler;
my $debugmode = 0;
my @flags;
my @libs;

GetOptions(
  '--with-root-config:s' => \$userRootConfig,
  '--build-debug' => \$debugmode,
  '--compiler:s' => \$compiler,
);
push @flags, '-DDEBUG', '-Wall' if $debugmode;

my $guess = ExtUtils::CppGuess->new(
  (defined($compiler) ? (cc => $compiler) : ()),
);

push(@flags,
#  '-std=gnu++98', # FIXME necessary?
  '-Wall',
#  '-xc++',
  '-I.',
  '-Isrc',
  ($guess->is_gcc ? ('-Wno-unused') : ()),
);

if ($SOOTBuilder::Alien->private_root) {
  # FIXME using rpath might be unportable
  # Add an rpath to the .so to make sure it can find root after install
  if ($^O =~ /darwin/) {
    push @libs, '-Wl,-rpath,' . $SOOTBuilder::Alien->libdir;
  }
  else {
    push @libs, '-Wl,-R' . $SOOTBuilder::Alien->libdir;
  }
}

my $rootConfig = defined($userRootConfig) ? $userRootConfig : 'root-config';
if (!SOOTBuilder::can_run($rootConfig)) {
  $rootConfig = File::Spec->catfile($ENV{ROOTSYS}, 'bin', 'root-config');
  if (!SOOTBuilder::can_run($rootConfig)) {
    die <<HERE;
Could not find the root-config utility which is necessary for building
SOOT. You can either make sure it's available from your PATH environment,
set the ROOTSYS environment variable correctly, or run Build.PL with
  perl Build.PL --with-root-config=/path/to/root-config
HERE
  }
}

push @flags, split(' ', SOOTBuilder::striprun($rootConfig, '--cflags')),
             (defined $ENV{ROOTSYS}
              ? ('-I'.File::Spec->catdir($ENV{ROOTSYS}, 'include'),
                 '-I'.File::Spec->catdir($ENV{ROOTSYS}, 'include', 'root'))
              : ());
push @flags, '-IRunTimeXS';

push @libs, map { split(' ', $_) }
             ($Config::Config{lddlflags},
              SOOTBuilder::striprun($rootConfig, '--ldflags'),
              SOOTBuilder::striprun($rootConfig, '--libs'));

if ($debugmode) {
  @flags = ('-O0', grep !/^-O\d$/, @flags);
}

$guess->add_extra_compiler_flags(join(' ', @flags));
$guess->add_extra_linker_flags(join(' ', @libs));

if ($guess->is_gcc) {
  print "Detected that we're building for a gcc compiler...\n";
}
elsif ($guess->is_msvc) {
  print "Detected that we're building for an MS compiler...\n";
}
else {
  print "Unknown compiler... Trying regardless.\n";
}

my %build_args = (
  module_name           => 'SOOT',
  license               => 'gpl',
  dist_author           => 'Steffen Mueller <smueller@cpan.org>',
  dist_version_from     => 'lib/SOOT.pm',
  dynamic_config        => 1,
  create_readme         => 1,
  recursive_test_files  => 1,
  create_packlist       => 1,

  # Maintain compatibility with ExtUtils::MakeMaker installations
  #create_makefile_pl    => 'passthrough',

  # Location of our special C and XS source files
  c_source => ['src', 'RunTimeXS'],
  xs_files => {
    'SOOT.xs' => 'lib/SOOT.xs'
  },

  #extra_compiler_flags  => \@flags,
  #extra_linker_flags    => \@libs,
  $guess->module_build_options(),

  requires => {
    'perl'                  => '5.008',
    'Data::Dumper'          => '0', # core as of 5.008

    # Pragmatic and special modules
    'Carp'                  => '1.01', # core as of 5.008
    'version'               => '0',
    'warnings'              => '0', # core as of 5.008
    'strict'                => '0', # core as of 5.008
  },
  configure_requires => {
    'Module::Build'         => '0.3605',
    'Alien::ROOT'           => '5.26.0.1',
    'ExtUtils::CppGuess'    => '0.01',
  },
  build_requires => {
    # For the XS build process
    'ExtUtils::XSpp'        => '0.10_02',
    'ExtUtils::CBuilder'    => '0',
    'ExtUtils::ParseXS'     => '3.02', # actually, we have this in inc/, so we don't *really* need to list it here
    'ExtUtils::Constant'    => '0', # core as of 5.008
    'File::Spec'            => '0', # core as of 5.008
    'File::Path'            => '0', # core as of 5.008
  },

  add_to_cleanup => [ qw(rootclasses.xsinclude rootclasses.h rootclasses.map src/SOOTDictionary.cc src/SOOTDictionary.h) ],
  script_files => [],

  meta_merge => {
    resources => {
      # Official keys (homepage, license, bugtracker)
      repository   => 'git://github.com/tsee/SOOT.git',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SOOT',
      license      => 'http://www.opensource.org/licenses/gpl-2.0.php',
    },
    no_index => {
      directory => [
        qw(buildtools src t ROOT_XSP xt XS inc examples)
      ],
    },
  },
);

if ($debugmode) {
  $build_args{extra_linker_flags} =~ s/-O\d//g; # REALLY?
}
my $builder = SOOTBuilder->new(%build_args);
$builder->create_build_script();

