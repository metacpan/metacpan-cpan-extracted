use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

my $tmpdir = File::Spec->tmpdir();
if(!-w $tmpdir) {
	print STDERR "NA: Your temporary directory '$tmpdir' isn't writable, fix your configuration and try again";
	exit(0);
}

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Schema::Validator',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Schema/Validator.pm',
	ABSTRACT_FROM	=> 'lib/Schema/Validator.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	EXE_FILES => [ 'bin/extract-event', 'bin/extract-event2', 'bin/validate-schema' ],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'FindBin' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::RequiresInternet' => 0,
	}, PREREQ_PM => {
		'LWP::Protocol::https' => 0,
		'LWP::UserAgent' => 0,
		'JSON::MaybeXS' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Schema-Validator-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Schema::Validator',
			repository => {
				repository => 'https://github.com/nigelhorne/Schema-Validator',
				type => 'git',
				url => 'git://github.com/nigelhorne/Schema-Validator.git',
				web => 'https://github.com/nigelhorne/Schema-Validator',
				# license  => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Schema-Validator@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Schema-Validator',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Schema-Validator',
				# url => 'https://github.com/nigelhorne/Schema-Validator/issues',
				# web => 'https://github.com/nigelhorne/Schema-Validator/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
