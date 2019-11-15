require 5.014;
use strict;
use ExtUtils::MakeMaker;
use Module::Metadata;
eval "use Devel::Required pod => [ qw(
	lib/String/Lookup.pm
	lib/String/Lookup/AsyncDBI.pm
	lib/String/Lookup/DBI.pm
	lib/String/Lookup/FlatFile.pm
) ]";

WriteMakefile (
	NAME		=> "String::Lookup",
	AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
	ABSTRACT	=> "convert strings to ID's authoritatively and vice-versa",
	VERSION_FROM	=> 'lib/String/Lookup.pm',
	LICENSE	=> 'perl',
	MIN_PERL_VERSION => '5.014',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
                'Module::Metadata' => '1.000033',
                'threads' => '0'
	},
	BUILD_REQUIRES => {
		'Test::More' => '0'
	},
	PREREQ_PM	=> {
		'warnings' => 0,
		'autodie' => 0,
		'bytes' => 0,
		'Encode' =>  0, 
		'Scalar::Util' => 0	 
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
        clean => { FILES => 'String-Lookup-*' },
	META_MERGE => {
                'meta-spec' => { version => 2 },
                resources => {
                        repository => {
                                type => 'git',
                                url  => 'https://github.com/ThisUsedToBeAnEmail/String-Lookup.git',
                                web  => 'https://github.com/ThisUsedToBeAnEmail/String-Lookup',
                        }
                }
        },
        META_ADD => {
                provides => Module::Metadata->provides(version => '2', dir => 'lib')
        }
);
