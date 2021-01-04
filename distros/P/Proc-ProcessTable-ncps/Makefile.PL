use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
						 NAME             => 'Proc::ProcessTable::ncps',
						 AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
						 VERSION_FROM     => 'lib/Proc/ProcessTable/ncps.pm',
						 ABSTRACT_FROM    => 'lib/Proc/ProcessTable/ncps.pm',
						 LICENSE          => 'artistic_2',
						 MIN_PERL_VERSION => '5.006',
						 INST_SCRIPT => 'bin',
						 CONFIGURE_REQUIRES => {
												'ExtUtils::MakeMaker' => '0',
												},
						 TEST_REQUIRES => {
										   'Test::More' => '0',
										   },
						 PREREQ_PM => {
									   'Term::ANSIColor'=>'4.06',
									   'Text::ANSITable'=>'0.501',
									   'Getopt::Long'=>'0.0.0',
									   'Data::Unixish::Apply'=>'1.570',
									   'Proc::ProcessTable'=>'0.59',
									   'Proc::ProcessTable::Match'=>'0.0.1',
									   'Statistics::Basic'=>'1.6611',
									   'List::Util'=>'0.0',
									   'Proc::ProcessTable::InfoString' => '0.0.1',
									   'ColorTheme::NoColor'=>'0.0',
									   },
						 dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
						 clean => { FILES => 'Proc-ProcessTable-ncps-*' },
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
