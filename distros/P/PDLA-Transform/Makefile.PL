use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use PDLA::Core::Dev;
use PDLA::Config;

my @coredep = ('PDLA::Core' => '2.019100');
my @prereq = @coredep;

##############################
# Hack to include fPIC on x86_64 systems -
# use similar mods to affect CCFLAGS on other systems as needed...
my $ccflags =  $Config{ccflags};
if($Config{archname}=~m/x86_64/) {
    $ccflags .= " -fPIC";
}

my @optimize = (OPTIMIZE => $PDLA::Config{OPTIMIZE}) if $PDLA::Config{OPTIMIZE};

my @pack = (["transform.pd", qw(Transform PDLA::Transform)]);
my %hash = pdlpp_stdargs(@pack);

sub MY::postamble { pdlpp_postamble(@pack); }

$hash{clean}{FILES} .= ' MANIFEST.bak';

WriteMakefile(
  %hash,
  PREREQ_PM => { @prereq },
  LICENSE => 'perl',
  CONFIGURE_REQUIRES => {
    @coredep,
    'ExtUtils::MakeMaker' => 6.56,
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
    'Test::Exception' => '0',
  },
  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
  },
  MIN_PERL_VERSION => '5.010',
  NAME => 'PDLA::Transform',
  VERSION_FROM => 'transform.pd',
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdlporters.github.io',
      bugtracker  => {web=>'https://github.com/PDLPorters/pdla-transform/issues'},
      repository  => {
        url => 'git://github.com/PDLPorters/pdla-transform',
        type => 'git',
        web => 'https://github.com/PDLPorters/pdla-transform',
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
  @optimize,
  CCFLAGS => $ccflags,
  AUTHOR => 'PerlDL Developers (pdl-general@lists.sourceforge.net)',
  ABSTRACT => 'Perl Data Language',
);
