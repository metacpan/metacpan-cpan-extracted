use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Sub::Deprecate',
    AUTHOR           => q{Evan Carroll <me@evancarroll.com>},
    VERSION_FROM     => 'lib/Sub/Deprecate.pm',
    ABSTRACT_FROM    => 'lib/Sub/Deprecate.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.020',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'Exporter'   => '0',
    },
    PREREQ_PM => {
			'parent' => '0'
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version   => 2},
    no_index       => {directory => [qw(examples t)] },
    prereqs        => {runtime   => {requires => {perl => '5.016'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/EvanCarroll/perl-sub-deprecate/issues'},
      homepage   => 'https://github.com/EvanCarroll/perl-sub-deprecate',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/EvanCarroll/perl-sub-deprecate.git',
        web  => 'https://github.com/EvanCarroll/perl-sub-deprecate',
      },
    },
  },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Sub-Deprecate-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
