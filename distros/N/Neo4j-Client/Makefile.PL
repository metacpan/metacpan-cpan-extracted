use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $mm = Alien::Build::MM->new;

WriteMakefile($mm->mm_args(
  ABSTRACT => 'Build and use the libneo4j-omni library',
  AUTHOR => ['Mark A. Jensen (majensen -at- cpan -dot- org)'],
  DISTNAME => 'Neo4j-Client',
  NAME => 'Neo4j::Client',
  VERSION_FROM => 'lib/Neo4j/Client.pm',
  LICENSE => 'apache_2_0',
  MIN_PERL_VERSION => '5.006',  # our
  CONFIGURE_REQUIRES => {
    'Alien::Build::MM' => '1.19',
    'Alien::OpenSSL' => '0.09',
    'Capture::Tiny' => 0,
    'Env' => 0,
    'ExtUtils::MakeMaker' => '6.64',
    'File::Which' => 0,
    'Path::Tiny' => '0.014',
  },
  BUILD_REQUIRES => {
    'Alien::Base' => '0.036',
  },
  TEST_REQUIRES => {
    'Test2::V0' => 0,
    'Test::Alien' => 0,
  },
  PREREQ_PM => {
    'Alien::Build' => '1.19',
    'Alien::OpenSSL' => '0.09',
    'Capture::Tiny' => 0,
    'Env' => 0,
    'File::Which' => 0,
    'Path::Tiny' => '0.014',
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    prereqs => {
      develop => {
        recommends => {
          'FFI::Platypus' => 0,
          'Inline::C' => 0,
          'Test::CPAN::Changes' => 0,
          'Test::Pod' => 0,
        },
        requires => {
          'IPC::Run' => 0,  # nc-update
        },
      },
    },
    resources => {
      bugtracker => {
	web => 'https://github.com/majensen/neoclient/issues',
      },
      repository => {
	type => 'git',
	url => 'https://github.com/majensen/neoclient.git',
       },
    },
    x_contributors => [
      'Mohawk (ETJ)'
     ]
  },
  dist => {
    TAR => 'ptar',  # avoid extended headers in tarball
  },
  realclean => {
    FILES => 'MANIFEST.bak build/configure~',
  },
 ));

sub MY::postamble {
  $mm->mm_postamble;
}
