use strict;
use warnings;
use ExtUtils::MakeMaker;

# Test for broken smokers that don't set AUTOMATED_TESTING
if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
	if($reporter =~ /smoker/i) {
		warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
		$ENV{'AUTOMATED_TESTING'} = 1;
	}
}

my $dist = {
	COMPRESS => 'gzip -9f', # Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME	 => 'Readonly::Enum',		# Name of the module
	VERSION_FROM => 'lib/Readonly/Enum.pm',	# Automatically fetch version from the module
	AUTHOR	=> 'Nigel Horne <njh@nigelhorne.com>', # Author information
	ABSTRACT	 => 'A Perl module for improving grammar using an external API.',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM	=> {			# Dependencies (with versions)
		'Carp' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Scalar::Readonly' => 0,
		'version' => 0.77,
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Warnings' => 0
	}, dist => $dist,
	clean	 => {
		FILES => 'Readonly-Enum-*',
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Readonly::Enum',
			repository => {
				# repository => 'https://github.com/nigelhorne/Readonly-Enum',
				repository => 'https://github.com/robrwo/Readonly-Enum',
				type => 'git',
				url => 'git://github.com/nigelhorne/Readonly-Enum.git',
				web => 'https://github.com/robrwo/Readonly-Enum',
			}, bugtracker => {
				mailto => 'bug-Readonly-Enum@rt.cpan.org',
				# url => 'git://github.com/nigelhorne/Readonly-Enum.git',
				# web => 'https://github.com/robrwo/Readonly-Enum',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Readonly-Enum',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Readonly-Enum',
			}
		},
	},
	MIN_PERL_VERSION	=> '5.010'
);
