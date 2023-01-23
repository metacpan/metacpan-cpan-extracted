use 5.016;
use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

my $GITHUB_URL = 'https://github.com/jhthorsen/mojo-sharedir';

my %WriteMakefileArgs = (
  AUTHOR             => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE            => 'artistic_2',
  NAME               => 'Mojo::ShareDir',
  ABSTRACT_FROM      => 'lib/Mojo/ShareDir.pm',
  VERSION_FROM       => 'lib/Mojo/ShareDir.pm',
  EXE_FILES          => [],
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker'     => '6.00', 'File::ShareDir::Install' => '0.14'},
  TEST_REQUIRES      => {'Test::More'              => '0.30'},
  PREREQ_PM          => {'File::ShareDir::Install' => '0.14', 'Mojolicious' => '9.00'},
  META_MERGE         => {
    'dynamic_config' => 0,
    'meta-spec'      => {version   => 2},
    'no_index'       => {directory => [qw(examples t)]},
    'prereqs'        => {runtime   => {requires => {perl => '5.016'}}},
    'resources'      => {
      bugtracker => {web => "$GITHUB_URL/issues"},
      homepage   => $GITHUB_URL,
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {type => 'git', url => "$GITHUB_URL.git", web => $GITHUB_URL},
      x_IRC      => {url  => 'irc://irc.libera.chat/#convos', web => 'https://web.libera.chat/#convos'},
    },
    'x_contributors' => [],
  },
  test => {TESTS => (-e 'META.yml' ? 't/*.t' : 't/*.t xt/*.t')},
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.63_03') }) {
  my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

install_share 'share';
WriteMakefile(%WriteMakefileArgs);

package MY;
use File::ShareDir::Install qw(postamble);
