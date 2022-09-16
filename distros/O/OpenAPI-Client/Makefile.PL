use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $GITHUB_URL = 'https://github.com/jhthorsen/openapi-client';

my %WriteMakefileArgs = (
  NAME          => 'OpenAPI::Client',
  AUTHOR        => 'Jan Henning Thorsen <jan.henning@thorsen.pm>',
  LICENSE       => 'artistic_2',
  ABSTRACT_FROM => 'lib/OpenAPI/Client.pm',
  VERSION_FROM  => 'lib/OpenAPI/Client.pm',
  TEST_REQUIRES => {'Test::More'      => '0.88'},
  PREREQ_PM     => {'JSON::Validator' => '5.09', 'Mojolicious::Plugin::OpenAPI' => '5.05'},
  META_MERGE    => {
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
    'x_contributors' => [
      'Clive Holloway <clhollow@estee.com>',
      'Ed J <mohawk2@users.noreply.github.com>',
      'Jan Henning Thorsen <jhthorsen@cpan.org>',
      'Mohammad S Anwar <mohammad.anwar@yahoo.com>',
      'Reneeb <info@perl-services.de>',
      'Roy Storey <kiwiroy@users.noreply.github.com>',
      'Veesh Goldman <rabbiveesh@gmail.com>',
    ],
  },
  test => {TESTS => (-e 'META.yml' ? 't/*.t' : 't/*.t xt/*.t')},
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.63_03') }) {
  my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

WriteMakefile(%WriteMakefileArgs);
