use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
						 NAME             => 'Net::Connection::ncnetstat',
						 AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
						 VERSION_FROM     => 'lib/Net/Connection/ncnetstat.pm',
						 ABSTRACT_FROM    => 'lib/Net/Connection/ncnetstat.pm',
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
									   'Net::Connection'=>'0.2.0',
									   'Net::Connection::lsof'=>'0.1.1',
									   'Net::Connection::Match'=>'0.4.0',
									   'Net::Connection::Sort'=>'0.0.1',
									   'Term::ANSIColor'=>'4.06',
									   'Text::ANSITable'=>'0.501',
									   'Getopt::Long'=>'0.0.0',
									   'Data::Unixish::Apply'=>'1.570',
									   },
						 dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
						 clean => { FILES => 'Net-Connection-ncnetstat-*' },
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
