use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Redis::ClusterRider',
  VERSION_FROM     => 'lib/Redis/ClusterRider.pm',
  MIN_PERL_VERSION => '5.008000',
  PREREQ_PM        => {
    'Redis'           => '1.982',
    'List::MoreUtils' => '0.410',
    'Scalar::Util'    => '0',
    'Time::HiRes'     => '1.9726',
    'Carp'            => '0',
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
  },
  BUILD_REQUIRES => {
    'Test::More'       => '0.98',
    'Test::Fatal'      => '0.013',
    'Test::MockObject' => '1.20150527',
    'Clone'            => '0.38',
  },
  META_MERGE => {
    resources => {
      homepage   => 'https://github.com/iph0/Redis-ClusterRider',
      bugtracker => 'https://github.com/iph0/Redis-ClusterRider/issues',
      repository => 'https://github.com/iph0/Redis-ClusterRider',
      license    => 'http://dev.perl.org/licenses/',
    },
  },
  ABSTRACT_FROM => 'lib/Redis/ClusterRider.pm',
  AUTHOR        => 'Eugene Ponizovsky <ponizovsky@gmail.com>',
  LICENSE       => 'perl',
);
