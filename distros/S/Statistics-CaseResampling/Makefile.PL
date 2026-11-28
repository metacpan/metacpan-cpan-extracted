use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %WriteMakefileArgs = (
    NAME              => 'Statistics::CaseResampling',
    VERSION_FROM      => 'lib/Statistics/CaseResampling.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    TEST_REQUIRES     => {
      'Test::More' => '0',
      'List::Util' => '0',
    },
    ABSTRACT_FROM     => 'lib/Statistics/CaseResampling.pm', # retrieve abstract from module
    AUTHOR            => 'Steffen Mueller <cpan@steffen-mueller.net>',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.008001',
    LIBS              => ['-lm'], # e.g., '-lm'
    #DEFINE            => '-O2', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)', # link all the C files too
    META_MERGE        => {
      'meta-spec' => { version => 2 },
      resources   => {
        repository => {
          type => 'git',
          url  => 'https://github.com/tsee/Statistics-CaseResampling.git',
          web  => 'https://github.com/tsee/Statistics-CaseResampling',
        },
        bugtracker => {
          web => 'https://github.com/tsee/Statistics-CaseResampling/issues',
        },
      },
    },
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.64') } ) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}
delete $WriteMakefileArgs{MIN_PERL_VERSION} unless eval { ExtUtils::MakeMaker->VERSION('6.48') };
delete $WriteMakefileArgs{META_MERGE}       unless eval { ExtUtils::MakeMaker->VERSION('6.46') };
delete $WriteMakefileArgs{LICENSE}          unless eval { ExtUtils::MakeMaker->VERSION('6.31') };

WriteMakefile(%WriteMakefileArgs);
