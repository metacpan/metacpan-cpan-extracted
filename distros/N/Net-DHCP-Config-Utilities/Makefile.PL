use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
						 NAME             => 'Net::DHCP::Config::Utilities',
						 AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
						 VERSION_FROM     => 'lib/Net/DHCP/Config/Utilities.pm',
						 ABSTRACT_FROM    => 'lib/Net/DHCP/Config/Utilities.pm',
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
									   'Config::Tiny'=>'2.24',
									   'Net::CIDR::Overlap'=>'0.2.0',
									   'Hash::Merge'=>'0.300',
									   'Net::CIDR'=>'0.20',
									   'Net::CIDR::Set'=>'0.13',
									   'File::Find::Rule'=>'0.34',
									   'Template'=>'2.29',
									   'String::Shellquote'=>'1.04',
									   },
						 dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
						 clean => { FILES => 'Net-DHCP-Config-Utilities-*' },
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
