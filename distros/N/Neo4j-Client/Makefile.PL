use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $mm = Alien::Build::MM->new;

WriteMakefile($mm->mm_args(
  ABSTRACT => 'Build and use the libneo4j-client library',
  AUTHOR => ['Mark A. Jensen (majensen -at- cpan -dot- org)'],
  DISTNAME => 'Neo4j-Client',
  NAME => 'Neo4j::Client',
  VERSION_FROM => 'lib/Neo4j/Client.pm',
  LICENSE => 'apache_2_0',
  CONFIGURE_REQUIRES => {
    'Alien::Build::MM' => 0,
    'Alien::OpenSSL' => 0,
    'Path::Tiny' => 0,
    'Env' => 0,
    'Capture::Tiny' => 0,
    'File::Which' => 0,
  },
  BUILD_REQUIRES => {
  },
  TEST_REQUIRES => {
    'Test2::V0' => 0,
    'Test::Alien' => 0,
  },
  PREREQ_PM => {
    'Alien::Build' => 0,
    'Alien::OpenSSL' => 0,
    'Path::Tiny' => 0,
    'Env' => 0,
    'Capture::Tiny' => 0,
    'File::Which' => 0,
  },
  META_MERGE => {
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
      "Mark A. Jensen <majensen@cpan.org>",
      "Mohawk (ETJ)"
     ]
  }
 ));

sub MY::postamble {
  $mm->mm_postamble;
}
