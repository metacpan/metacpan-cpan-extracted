use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',		# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME => 'Test::Consumer::Contract',
	VERSION_FROM => 'lib/Test/Consumer/Contract.pm',
	ABSTRACT_FROM => 'lib/Test/Consumer/Contract.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE => 'GPL',
	MIN_PERL_VERSION => '5.014',	# Sub::Private needs 5.14
	PREREQ_PM => {
		'autodie' => 0,
		'Carp' => 0,
		'Cwd' => 0,
		'Exporter' => 0,
		'File::Basename' => 0,
		'File::Find' => 0,
		'File::Spec' => 0,
		'IPC::System::Simple' => 0,	# autodie qw(:all) covers system()
		'lib' => 0,
		'List::Util' => 0,
		'Module::Runtime' => 0,
		'Params::Get' => 0.17,
		'Params::Validate::Strict' => 0.41,
		'Readonly' => 0,
		'Return::Set' => 0.05,
		'Scalar::Util' => 0,
		'Sub::Private' => 0.06,
		'Sub::Protected' => 0.03,
		'Test::More' => 0,	# the module emits TAP itself
		'Text::Balanced' => 0,
	},
	TEST_REQUIRES => {
		'Data::Dumper' => 0,
		'Errno' => 0,
		'File::Path' => 0,
		'File::Temp' => 0,
		'POSIX' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
	},
	dist => $dist,
	clean => { FILES => 'Test-Consumer-Contract-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				repository => 'https://github.com/nigelhorne/Test-Consumer-Contract',
				type => 'git',
				url => 'git://github.com/nigelhorne/Test-Consumer-Contract.git',
				web => 'https://github.com/nigelhorne/Test-Consumer-Contract',
			}, bugtracker => {
				mailto => 'bug-Test-Consumer-Contract@rt.cpan.org',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Consumer-Contract',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Consumer-Contract',
			}
		},
	},
);
