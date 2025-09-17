use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	ABSTRACT_FROM	=> 'lib/Params/Validate/Strict.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	NAME => 'Params::Validate::Strict',
	VERSION_FROM => 'lib/Params/Validate/Strict.pm', # finds $VERSION in the module
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Params::Validate::Strict',
			repository => {
				repository => 'https://github.com/nigelhorne/Params-Validate-Strict',
				type => 'git',
				url => 'git://github.com/nigelhorne/Params-Validate-Strict.git',
				web => 'https://github.com/nigelhorne/Params-Validate-Strict',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Params-Validate-Strict@rt.cpan.org',
				# url => 'https://github.com/nigelhorne/Params-Validate-Strict/issues',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Params-Validate-Strict',
				# web => 'https://github.com/nigelhorne/Params-Validate-Strict/issues'
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Params-Validate-Strict',
			}
		}
	}, PREREQ_PM => {
		'Carp' => 0,
		'Exporter' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'List::Util' => 0,
		'Params::Get' => 0.13,
		'Scalar::Util' => 0,
		'strict' => 0,
		'warnings' => 0
	}, TEST_REQUIRES => {
		'File::Glob' => 0,
		'File::Slurp' => 0,
		'File::stat' => 0,
		'IPC::System::Simple' => 0,
		'JSON::MaybeXS' => 0,
		'POSIX' => 0,
		'Readonly' => 0,
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Warnings' => 0
	}, dist => $dist,
	clean => { FILES => 'Params-Validate-Strict-*' },	# Clean up distribution files
);
