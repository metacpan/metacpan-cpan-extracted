use 5.016;
use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker;

my $GITHUB_URL = 'https://github.com/jhthorsen/mojo-server-daemoncontrol';

my %WriteMakefileArgs = (
  AUTHOR        => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE       => 'artistic_2',
  NAME          => 'Mojo::Server::DaemonControl',
  ABSTRACT_FROM => 'lib/Mojo/Server/DaemonControl.pm',
  VERSION_FROM  => 'lib/Mojo/Server/DaemonControl.pm',
  EXE_FILES     => [],
  TEST_REQUIRES => {'Test2::V0'   => '0.000145'},
  PREREQ_PM     => {'Mojolicious' => '9.00'},
  META_MERGE    => {
    'dynamic_config' => 0,
    'meta-spec'      => {version   => 2},
    'no_index'       => {directory => [qw(examples t)]},
    'prereqs'        => {runtime   => {requires => {perl => '5.026'}}},
    'resources'      => {
      bugtracker => {web => "$GITHUB_URL/issues"},
      homepage   => $GITHUB_URL,
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {type => 'git', url => "$GITHUB_URL.git", web => $GITHUB_URL},
      x_IRC => {url => 'irc://irc.libera.chat/#convos', web => 'https://web.libera.chat/#convos'},
    },
    'x_contributors' => [],
  },
  test => {TESTS => (-e 'META.yml' ? 't/*.t' : 't/*.t xt/*.t')},
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.63_03') }) {
  my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

WriteMakefile(%WriteMakefileArgs);
