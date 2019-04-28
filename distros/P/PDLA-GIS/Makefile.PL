use strict;
use warnings;

use ExtUtils::MakeMaker;  # for CONFIGURE_REQUIRES support
use Config;
use PDLA::Core::Dev;
use PDLA::Config;

my @coredep = ('PDLA::Core' => '2.019100', 'PDLA::Transform' => '0');
my @prereq = @coredep;

##############################
# Hack to include fPIC on x86_64 systems -
# use similar mods to affect CCFLAGS on other systems as needed...

my $ccflags =  $Config{ccflags};
if($Config{archname}=~m/x86_64/) {
    $ccflags .= " -fPIC";
}

# create GENERATED subdir with *.pm files during 'make dist' (to make metacpan.org happy)
my $preop = '$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -MPDLA::Core::Dev -e pdlpp_mkgen $(DISTVNAME)';

my @optimize = (OPTIMIZE => $PDLA::Config{OPTIMIZE}) if $PDLA::Config{OPTIMIZE};

WriteMakefile(
  PREREQ_PM => { @prereq },
  LICENSE => 'perl',
  CONFIGURE_REQUIRES => {
    @coredep,
    'ExtUtils::MakeMaker' => 6.56,
    'Alien::Proj4' => '2.019107',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'Alien::Proj4' => '2.019107',
  },
  MIN_PERL_VERSION => '5.010',
  NAME => 'PDLA::GIS',
  VERSION_FROM => 'lib/PDLA/GIS.pm',
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdlporters.github.io',
      bugtracker  => {web=>'https://github.com/PDLPorters/pdla-gis/issues'},
      repository  => {
        url => 'git://github.com/PDLPorters/pdla-gis',
        type => 'git',
        web => 'https://github.com/PDLPorters/pdla-gis',
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
  @optimize,
  CCFLAGS => $ccflags,
  dist     => { COMPRESS => 'gzip',
                  SUFFIX   => 'gz',
                  PREOP    => $preop },
  clean => {
    FILES => join ' ', qw(
      MANIFEST.bak
    ),
  },
  AUTHOR => 'PerlDL Developers (pdl-general@lists.sourceforge.net)',
  ABSTRACT => 'Perl Data Language',
);
