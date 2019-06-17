use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::c_o {
  package MY; # so that "SUPER" works right
  my $inherited = shift->SUPER::c_o(@_);
  $inherited =~ s/\$\*\.c/\$\(C_FILES\)/; 
  $inherited;
}

my %WriteMakefileArgs = (
    NAME             => 'Proc::ProcessTable',
    AUTHOR           => q{Joachim Bargsten <jw@bargsten.org>},
    VERSION_FROM     => 'lib/Proc/ProcessTable.pm',
    ABSTRACT_FROM    => 'lib/Proc/ProcessTable.pm',
    LICENSE          => 'artistic_2',
    'LDFROM'    => '$(O_FILES)',
    'LIBS'	=> [''],
    'OBJECT'    => 'ProcessTable.o OS.o',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    'PREREQ_PM'    => { 'File::Find' => 0, 'Storable' => 0 },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Proc-ProcessTable-* OS.c' },
    'META_MERGE' => {
         resources => {
             repository  =>  'https://github.com/jwbargsten/perl-proc-processtable',
         },
    },
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
