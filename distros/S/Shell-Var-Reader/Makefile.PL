use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

my %WriteMakefileArgs = (
	NAME               => 'Shell::Var::Reader',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/Shell/Var/Reader.pm',
	ABSTRACT_FROM      => 'lib/Shell/Var/Reader.pm',
	LICENSE            => 'artistic_2',
	INST_SCRIPT        => 'bin',
	EXE_FILES          => [ 'src_bin/shell_var_reader', 'src_bin/cmdb_shell_var_reader' ],
	MIN_PERL_VERSION   => '5.006',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'     => '0',
		'File::ShareDir::Install' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'File::Slurp'        => '0',
		'JSON'               => '0',
		'TOML'               => '0',
		'YAML::XS'           => '0',
		'Data::Dumper'       => '0',
		'String::ShellQuote' => '0',
		'Hash::Merge'        => '0',
		'Rex'                => '1.14.2',
		'Rex::CMDB::TOML'    => '0.0.1',
		'JSON::Path'         => '1.0.3',
		'Hash::Flatten'      => '0',
		'File::Slurp'        => '0',
		'File::ShareDir'     => '0',
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'Shell-Var-Reader-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'git@github.com:VVelox/Shell-Var-Reader.git',
				web  => 'https://github.com/VVelox/Shell-Var-Reader',
			},
		},
	},

);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
	my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
	my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
	unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
	unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

package MY;
use File::ShareDir::Install qw(postamble);
